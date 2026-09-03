# oracle-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nroracledb` receiver (currently **Preview**) to scrape one Oracle Database
instance and export the results to New Relic over OTLP.

## What this chart does not do

- Monitor more than one Oracle instance per release — install the chart once
  per database.
- Verify TLS/SSL connections to Oracle. The `nroracledb` receiver's public
  documentation does not describe any TLS configuration; if your Oracle
  instance requires an encrypted connection, confirm support directly against
  the receiver before relying on this chart.
- Report host/infrastructure metrics (CPU, memory, disk, filesystem, network,
  OS logs) for the machine Oracle runs on. New Relic's `otel-oracledb` docs
  show two collector-config shapes: a combined "NRDOT host with database
  configuration" (adds `hostmetrics`/`filelog`/`otlp` receivers and a
  `health_check` extension) and a standalone "Database configuration". The
  combined shape only makes sense when the collector runs directly on the
  Oracle server's own host OS (e.g. as a systemd service) — this chart runs
  the collector as a Kubernetes Deployment that reaches Oracle remotely over
  the network via `oracle.endpoint`, so it can never be *on* that host.
  Reporting the Kubernetes node's metrics instead would be a different
  feature (cluster observability, unrelated to the Oracle server), not a
  substitute. This chart implements only the standalone "Database
  configuration" shape. If you also want host-level metrics for the Oracle
  server itself, install NRDOT (or another agent) directly on that host,
  outside this chart.

## Choosing `oracle.topology`

| Your setup | `oracle.topology` |
|---|---|
| Amazon RDS for Oracle | `rds` |
| Self-hosted, multitenant (you connect to the container database) | `cdb` |
| Self-hosted, single pluggable database only | `pdb` |
| Oracle Autonomous Database (OCI) | `adb` |

This value is always required. It selects the `nroracledb` receiver's default
`metrics`/`resource_attributes` block for `config.yaml`:

- **CDB/PDB**: same 64-metric set plus 8 `resource_attributes` keys.
- **RDS**: reduced 41-metric set, no `resource_attributes` — RDS restricts
  access to some of the `V$`/`DBA_` views the extra metrics/attributes read
  from.
- **ADB**: reduced 39-metric set, no `resource_attributes`, and no
  `oracle.db.pdb` attribute anywhere (ADB isn't multitenant from the client's
  perspective).

Override any individual metric/event via `additionalReceiverConfig` if you
need to.

`adb` also changes the receiver's connection shape and the exporter: instead
of discrete `endpoint`/`username`/`password`/`service` fields, the receiver
gets a single `datasource` connection string
(`oracle://<user>:<password>@<host>:<port>/<service>?ssl=true&ssl%20verify=true`,
credentials still injected via `${env:ORACLE_USERNAME}`/`${env:ORACLE_PASSWORD}`,
never written literally into the ConfigMap) with TLS enabled inline — no
wallet file is needed. The exporter becomes `otlphttp/newrelic` (HTTP)
instead of `otlp/newrelic` (gRPC), and `service.telemetry.metrics.level: none`
is added, all matching New Relic's documented ADB configuration.

When `setupJob.enabled: true`, this value additionally selects which grant
script the setup Job runs, since RDS, CDB, PDB, and ADB each require a
different user-creation and permission-granting procedure. It also
determines whether the monitoring username must carry a `C##` prefix (CDB
only, enforced by Oracle itself).

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to `oracle.endpoint`
  (VPN, peering, or shared network), DNS resolution if it's a hostname, and
  the Oracle-side firewall must allow the connection's actual source IP
  (which may be a NAT gateway, not the Pod IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or shared-VPC
  placement with the RDS instance, and the RDS security group must allow the
  Oracle port from the cluster's egress source.
- **ADB**: the collector Pod needs outbound access to the Autonomous
  Database's public (or private-endpoint) listener; the connection is
  TLS-secured via the `datasource` string's `ssl=true` query parameters, not
  a wallet file.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring user (`oracle.username`/
`oracle.existingSecret`) and grants it read access, using a separate admin
credential (`setupJob.oracleAdmin.existingSecret` — **required**, no
plain-value path, since it can create users and grant broad access).

**For `cdb`/`pdb` topology, this admin credential must be `SYS`, connecting
`AS SYSDBA`** — confirmed by hands-on testing, not just documentation.
Oracle protects its `V_$`/`DBA_` catalog views so that only `SYS` can grant
`SELECT` on them, even to a full `DBA`-role account like `SYSTEM` (which
fails with `ORA-01031: insufficient privileges` despite otherwise having
broad administrative rights). The Job connects `AS SYSDBA` automatically for
these two topologies. For `rds` topology, use the RDS master user instead —
RDS deliberately disallows `SYSDBA` entirely and grants via the `rdsadmin`
package internally, which is why `rds-grants.sql` doesn't hit this issue. For
`adb` topology, connect as `SYS` without `AS SYSDBA` — per New Relic's
documentation, ADB grants run as a plain SYS session with no `SYSDBA` mode,
no `CONTAINER=ALL`, and no `C##` prefix.

This requires an Oracle Instant Client + `sqlplus` image. Oracle publishes
one at `container-registry.oracle.com`, which requires manually accepting
Oracle's license terms once, before the image can be pulled — this cannot be
automated. **Confirm the exact repository path and a current tag against
that registry yourself before setting `setupJob.image.repository`/
`setupJob.image.tag`** — this README intentionally does not assert one, since
it wasn't independently verified while writing this chart.

If you'd rather not grant this chart admin-level Oracle access at all, leave
`setupJob.enabled: false` and run the appropriate script from `files/setup/`
yourself, as a DBA, before installing.

## Testing

See [`TESTING.md`](./TESTING.md) for a full local/EC2 setup and end-to-end
validation runbook, including a disposable Oracle instance for testing
without touching production.

## Values

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.2.0` |
| `oracle.topology` | `cdb`, `pdb`, `rds`, or `adb` — always required | `""` |
| `oracle.endpoint` | Oracle listener `host:port` | `""` |
| `oracle.service` | CDB/PDB service name, RDS DB name, or ADB service name | `""` |
| `oracle.username` / `oracle.password` | Plain-value monitoring credentials | `""` |
| `oracle.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `oracle.collectionInterval` | Scrape interval | `10s` |
| `otlpEndpoint` | New Relic OTLP endpoint for your account's region | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into the `nroracledb` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user-creation Job | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | Oracle Instant Client image | `""` |
| `setupJob.oracleAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if enabled | `""` |
