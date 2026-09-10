# Testing mssql-otel end to end

A from-scratch runbook: no cluster, no SQL Server instance, no EC2 instance
assumed. Phases A and C below have been run live (Phase C against a real,
non-production Amazon RDS for SQL Server instance) — the notes under each
step come from what actually happened, including bugs found and fixed
along the way, not speculation. Phase B (the automated setup Job) has not
been run live yet.

## 0. Fastest check first — no cluster needed

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest --version 1.0.2
helm dependency update charts/mssql-otel
helm unittest charts/mssql-otel
helm lint charts/mssql-otel -f charts/mssql-otel/ci/test-values.yaml
```

`helm dependency update` must run before `helm unittest` — the
`common-library` dependency (used by `deployment.yaml`) isn't committed as
an archive (only `Chart.lock` is), so on a fresh clone it doesn't exist on
disk until `dependency update` downloads it.

Only move to a real cluster once all suites pass.

## 1. Launch an EC2 instance

**Console:** EC2 → Launch instance → AMI: **Ubuntu 22.04 LTS** (or Amazon
Linux/RHEL — both work, package manager commands differ, see notes below) →
Instance type: **t3.medium** (4GB RAM — SQL Server's Linux container wants
~2GB minimum, this gives headroom for k3s+Docker on top) → key pair →
Security group: allow inbound **SSH (22)** from your IP only (SQL Server
and the collector talk to each other via k3s/Docker's internal networking
— nothing needs to be open externally for a local disposable test; if
testing against RDS instead, see the networking note in Phase C) → Storage:
20-30GB → Launch.

**Equivalent CLI:**
```bash
aws ec2 run-instances \
  --image-id ami-0e2c8caa4b6378d8c \
  --instance-type t3.medium \
  --key-name <your-key-pair-name> \
  --security-group-ids <your-sg-id-allowing-ssh-from-your-ip> \
  --subnet-id <your-subnet-id> \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mssql-otel-test}]'
```
(That AMI id is Ubuntu 22.04 in `us-east-1` — look up the current one for
your region/OS if different.)

SSH in once running: `ssh -i <your-key.pem> <user>@<instance-public-ip>`
(`ubuntu` for Ubuntu AMIs, `ec2-user` for Amazon Linux/RHEL AMIs).

## 2. Install Docker, k3s, Helm

```bash
# Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker info   # should succeed with no sudo

# k3s (single-node Kubernetes)
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
kubectl get nodes   # should show Ready

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh && ./get_helm.sh

# clone the branch under test
git clone https://github.com/RamanaReddy8801/helm-charts.git
cd helm-charts
git checkout feat/mssql-otel-chart
```

Then run section 0's fastest-check commands.

### Alternative: local machine instead of EC2

```bash
brew install kind kubectl helm
kind create cluster --name mssql-otel-test
kubectl cluster-info --context kind-mssql-otel-test
```
Not exercised in this runbook's live runs — the EC2/k3s path above is the
one that's actually been used. If you use `kind`, the same networking note
from `oracle-otel/TESTING.md` applies: `kind`'s node containers live on a
Docker network named `kind`, not the default bridge, so a plain
`docker run` container needs `docker network connect kind mssql-otel-test`
before it's reachable.

## Phase A — everything except the automated setup Job (live-tested)

### 1. Start a disposable SQL Server instance

```bash
docker run -d --name mssql-otel-test \
  -p 1433:1433 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=TestAdminPass123!" \
  mcr.microsoft.com/mssql/server:2022-latest

docker logs -f mssql-otel-test
# wait for: SQL Server is now ready for client connections
```
Unlike Oracle's Instant Client, this image requires no manual license
click-through to pull — `ACCEPT_EULA=Y` is enough. `MSSQL_SA_PASSWORD` must
satisfy SQL Server's complexity policy (8+ chars, upper+lower+digit or
symbol) or the container exits immediately — check `docker logs` for a
password-policy complaint if it doesn't come up.

### 2. Confirm the cluster can actually reach it

```bash
HOST_IP=$(hostname -I | awk '{print $1}')
kubectl run -it --rm netcheck --image=busybox --restart=Never -- nc -zv $HOST_IP 1433
```
Expect `open`. Stop here if this fails — a networking issue, not a chart
issue.

**Common typo**: if you get `nc: bad address`, check for a missing space
between the host and port in your command — `nc -zv host1433` (concatenated)
fails very differently from `nc -zv host 1433` (correct).

### 3. Grant the monitoring login read access (standing in for the setup Job)

```bash
docker exec -it mssql-otel-test /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'TestAdminPass123!' -C <<'SQL'
CREATE LOGIN nr_monitor WITH PASSWORD = 'TestMonitorPass123!';
GO
GRANT VIEW SERVER STATE TO nr_monitor;
GRANT VIEW ANY DEFINITION TO nr_monitor;
GRANT VIEW ANY DATABASE TO nr_monitor;
GO
EXIT
SQL
```
(`-C` trusts the container's self-signed cert for this local `sqlcmd`
session only — the collector's own connection in step 4 below is always
unencrypted, since this chart has no TLS field at all; that's fine for this
local container, which doesn't enforce encryption.)

### 4. Create the Secret and install the chart

```bash
kubectl create secret generic test-mssql-monitor \
  --from-literal=username=nr_monitor --from-literal=password='TestMonitorPass123!'

helm install mssql-otel-test charts/mssql-otel \
  --set mssql.server=${HOST_IP} \
  --set mssql.topology=self-hosted \
  --set mssql.existingSecret=test-mssql-monitor \
  --set otlpEndpoint=https://otlp.nr-data.net:4318 \
  --set licenseKey=<your real license key, or any string to just check the export attempt>
```

**`otlpEndpoint` must be a full URL with scheme** (`https://...`), not bare
`host:port` — the chart validates this at render time and fails fast with a
clear message if you get it wrong. This validation was added after
originally finding, live, that a bare `host:port` value copied from
`oracle-otel`'s convention failed at runtime.

**Since then, the exporter itself was renamed from `otlphttp` to `otlp`**
(to match New Relic's doc text exactly), while this scheme requirement was
kept unchanged. That specific combination — a component literally named
`otlp` fed a scheme'd URL — is the exact pairing that was previously
confirmed to fail with `"unsupported protocol scheme"`. **Telemetry export
is not currently confirmed working; re-verify step 5/6 below carefully, and
expect it may need reverting to `otlphttp` (see README.md's "Telemetry
export" section) if it fails.**

### 5. Verify the collector

```bash
kubectl wait --for=condition=available deployment/mssql-otel-test --timeout=60s
kubectl logs deploy/mssql-otel-test --tail=50
```
Look for a clean `"Everything is ready. Begin running and processing
data."` line with **no subsequent error lines** — the collector only logs
on failure by default, so silence after a `collection_interval` (15s
default) has elapsed is itself a good sign, though not definitive proof
(see step 6).

### 6. Confirm data actually lands

Two ways, depending on whether you have a real license key:

**With a real key**: check the New Relic UI for `sqlserver.*` metrics
within the last 15 minutes.

**Without one** (or to verify independent of New Relic entirely): add a
temporary `debug` exporter directly via `kubectl edit configmap
mssql-otel-test-config` — add a `debug: {verbosity: detailed}` exporter
block and add `debug` alongside `otlp` in the `metrics` pipeline's
`exporters` list, then `kubectl rollout restart deployment/mssql-otel-test`
and check `kubectl logs deploy/mssql-otel-test --tail=100` for actual
scraped data points printed to stdout. Revert with `helm upgrade` (same
command as step 4) afterward — it overwrites the manual edit back to the
chart's rendered version.

## Phase B — the automated setup Job (not yet run live)

```bash
kubectl create secret generic test-mssql-admin \
  --from-literal=username=sa --from-literal=password='TestAdminPass123!'

helm upgrade mssql-otel-test charts/mssql-otel \
  --set mssql.server=${HOST_IP} \
  --set mssql.topology=self-hosted \
  --set mssql.existingSecret=test-mssql-monitor \
  --set otlpEndpoint=https://otlp.nr-data.net:4318 \
  --set licenseKey=<same as before> \
  --set setupJob.enabled=true \
  --set setupJob.sqlAdmin.existingSecret=test-mssql-admin \
  --set setupJob.image.repository=mcr.microsoft.com/mssql-tools \
  --set setupJob.image.tag=latest

kubectl wait --for=condition=complete job/mssql-otel-test-setup --timeout=120s
kubectl logs job/mssql-otel-test-setup
```
Expect no SQL errors and `complete` status. Since `nr_monitor` already
exists from Phase A step 3, this specifically exercises the idempotency
handling (`CREATE LOGIN` should skip via the `sys.server_principals` check,
not fail with a duplicate-login error). Run the same `helm upgrade` again
afterward to double check idempotency on a second pass. If
`mcr.microsoft.com/mssql-tools:latest` turns out to be broken/pulled/CVE'd
by the time you run this, build a substitute from Microsoft's
`mssql-tools18` apt packages instead — see the README's setup-Job section.

## Phase C — testing against a real (non-prod) Amazon RDS for SQL Server instance (no longer supported)

**This phase is now expected to fail, by design.** The chart used to build
a `datasource` connection string so it could set `encrypt=`/
`trustservercertificate=` and reach RDS (which enforces encryption
server-side, unconditionally). The chart has since switched to New Relic's
documented discrete `server`/`port`/`username`/`password` receiver fields
instead, matching the doc exactly — but those fields have no TLS
equivalent, so connections are always unencrypted. `mssql.tls.enabled`/
`mssql.tls.trustServerCertificate` no longer exist as values; setting them
via `--set` below is silently ignored (unknown key, no schema to reject
it), not an error, so nothing in the command below will look wrong until
the collector actually tries to scrape.

This section is kept as historical context (originally run end-to-end
against a real RDS instance, and where every real bug in this chart was
first found — see "Bugs found this way," below) — but re-running it today
will get through the grant script (`sqlcmd -C` still trusts RDS's cert for
that one local session) and the `helm install`, then fail at collector
scrape time with the same TLS error `mssql.tls` used to fix. There is
currently no supported way to monitor RDS SQL Server with this chart.

### Prerequisites specific to RDS

- Whatever host runs `kubectl`/`helm` needs a network path to the RDS
  endpoint (same VPC, peering, or transit gateway).
- The RDS security group must allow inbound on 1433 from that host's
  actual source IP.
- You need the RDS master username/password (set when the instance was
  created — check the AWS console's RDS instance Configuration tab if
  unsure).

### 1. Confirm network reachability

```bash
kubectl run -it --rm netcheck --image=busybox --restart=Never -- nc -zv <your-rds-endpoint> 1433
```

### 2. Install `sqlcmd` (skip if already installed — `which sqlcmd` first)

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
sqlcmd -?
```
(On Amazon Linux/RHEL, swap the `apt`/`curl ... tee` lines for the
`microsoft.com/config/rhel/9/prod.repo` equivalent + `sudo dnf install`.)

### 3. Run the grant script against RDS, as the RDS master user

```bash
cd helm-charts
sqlcmd -S <your-rds-endpoint>,1433 -U <rds-master-username> -P '<rds-master-password>' -C \
  -v monitor_user="nr_monitor" monitor_password="TestMonitorPass123!" \
  -i charts/mssql-otel/files/setup/grants.sql
```
**`-C` was required here** — RDS SQL Server enforces encryption
server-side and its certificate chains to Amazon's own RDS CA, which isn't
in most clients' default trust stores, so `sqlcmd` fails with `SSL
Provider: certificate verify failed` without `-C`. This is the same root
cause as the collector's own TLS issue (see step 5 below) — RDS forcing
encryption isn't optional/client-controlled.

Verify it worked:
```bash
sqlcmd -S <your-rds-endpoint>,1433 -U <rds-master-username> -P '<rds-master-password>' -C \
  -Q "SELECT name FROM sys.server_principals WHERE name = 'nr_monitor'"
```

### 4. Create the Secret and install the chart

```bash
kubectl create secret generic test-mssql-monitor \
  --from-literal=username=nr_monitor --from-literal=password='TestMonitorPass123!'

helm install mssql-otel-test charts/mssql-otel \
  --set mssql.server=<your-rds-endpoint> \
  --set mssql.port=1433 \
  --set mssql.topology=rds \
  --set mssql.existingSecret=test-mssql-monitor \
  --set otlpEndpoint=https://otlp.nr-data.net:4318 \
  --set licenseKey=<your real license key, or any string to just check the export attempt>
```

**This will install cleanly and then fail at scrape time.** RDS forces
encryption server-side, and its cert isn't in the collector's default trust
store. This chart no longer has any field to configure TLS (see the note at
the top of this phase), so every scrape fails with `TLS Handshake failed:
tls: failed to verify certificate: x509: certificate signed by unknown
authority` — there's currently no `--set` that fixes this.

### 5. Verify the collector

```bash
kubectl wait --for=condition=available deployment/mssql-otel-test --timeout=60s
kubectl logs deploy/mssql-otel-test --tail=50
```
A clean run shows the startup banner and then nothing else — no TLS
errors, no exporter protocol errors. Confirm data lands per Phase A step 6.

### 6. If you change any `--set` value afterward (`helm upgrade`)

The Pod now restarts automatically on any config-affecting change (a
`checksum/config` annotation forces this) — you should NOT need
`kubectl rollout restart` manually. If you ever see the *same* error after
an upgrade that changed config, `kubectl rollout status` reporting success
does not by itself prove the new config took effect; check
`kubectl get pods` for a genuinely new Pod name/age, or
`kubectl get configmap mssql-otel-test-config -o go-template='{{index .data "config.yaml"}}'`
to see exactly what's actually deployed.

### Bugs found this way (context — #1 below is currently unfixed again, see the Phase C note above)

Three real, otherwise-undetected bugs were found only by testing against a
live RDS instance — `ct install`/`helm-unittest` catch schema drift but
can't catch these:
1. `nrsqlserverreceiver` has no discrete `enable_ssl`/`trust_server_certificate`
   fields (the doc's example was wrong) — TLS is only configurable via a
   `datasource` connection string's `encrypt=`/`trustservercertificate=`
   DSN parameters. This chart originally fixed the RDS TLS failure by
   building a `datasource` string instead of discrete fields. It has since
   been reverted, on purpose, to match New Relic's doc field-for-field —
   which means this bug is back in effect and RDS is unreachable again
   (see the Phase C note above).
2. `helm upgrade` doesn't restart a Pod on a config-only change without a
   `checksum/config` annotation on the Deployment's Pod template — fixed,
   and worth checking for in any other chart with the same by-name
   ConfigMap-volume pattern (`oracle-otel` has the identical gap, not yet
   fixed there).
3. `otlpEndpoint` needs a full `https://host:port` URL (and port `4318`,
   not `4317`) for this chart's exporter — bare `host:port` (correct for
   `oracle-otel`'s gRPC exporter) fails with "unsupported protocol
   scheme." Now validated at render time. This was fixed by naming the
   exporter `otlphttp` (which genuinely wants a scheme'd URL). The exporter
   has since been renamed to `otlp` to match New Relic's doc text, with the
   scheme requirement left in place unchanged — reintroducing the exact
   broken pairing this bug describes. See the note above this phase and
   README.md's "Telemetry export" section.

## Clean up

```bash
helm uninstall mssql-otel-test
kubectl delete secret test-mssql-admin test-mssql-monitor
docker rm -f mssql-otel-test debug-collector
```

To tear down the whole test environment (k3s + everything on the EC2 box),
rather than just the one release:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```
Then terminate the EC2 instance itself from the console/CLI if you're
fully done with it — irreversible, so only if you're not planning to test
again soon.
