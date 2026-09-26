# mysql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrmysql` receiver to monitor MySQL and export the results to New Relic
over OTLP. One release runs one collector pod, monitoring either a single
MySQL instance (`mysql:`) or multiple instances (`mysqlMulti:`) — see
"Which mode do I need?" below.

## Which mode do I need?

| Your situation | Use | Schema |
|---|---|---|
| One MySQL instance | Single-instance mode | [`mysql:`](#single-instance-schema-mysql) |
| Multiple instances, one release | Multi-instance mode | [`mysqlMulti:`](#multi-instance-schema-mysqlmulti) |

The two are mutually exclusive within a single release — setting both
`mysql.server` and `mysqlMulti.enabled: true` fails the render. Aside from
that schema choice, everything below through "Automated setup" applies to
both modes: networking, TLS, and the setup Job all work the same way,
just applied per instance in the multi case.

## What this chart does not do

- Support Unix-socket monitoring (`transport: unix`). The `nrmysql`
  receiver supports connecting via a local socket file, but that only
  makes sense when the collector runs on the same host/filesystem as
  MySQL. This chart runs the collector as a Kubernetes Deployment reaching
  MySQL remotely over the network, so `transport` is always `tcp` and is
  not exposed as a value at all.
- Report host/infrastructure metrics for the machine(s) MySQL runs on. New
  Relic's docs show a "Full-feature configuration" that adds a
  `host_metrics` receiver and split host/db/traces pipelines — that only
  makes sense for a collector running directly on the MySQL host's own OS.
  This chart implements only the standalone "Standard configuration" shape.
- Auto-select an Amazon RDS CA bundle for you. `additionalReceiverConfig.tls.ca_file`
  is a plain value you supply — a chart-hardcoded default risks going
  stale as Amazon rotates CA bundles.

## Choosing the topology

| Your setup | Topology value |
|---|---|
| Amazon RDS for MySQL | `rds` |
| Self-hosted MySQL (reached over the network) | `self-hosted` |

This is `mysql.topology` in single-instance mode, or `mysqlMulti.topology`
in multi-instance mode — always required either way, but it does not
currently change any rendered output. It exists for documentation clarity
and as a validated, forward-compatible schema slot, same precedent as
`mssql-otel`'s `mssql.topology`.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to each
  instance's `server:port` (VPN, peering, or shared network), DNS
  resolution if it's a hostname, and the MySQL-side firewall must allow the
  connection's actual source IP (which may be a NAT gateway, not the Pod IP
  itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or shared-VPC
  placement with each RDS instance, and each RDS security group must allow
  the MySQL port (3306 by default) from the cluster's egress source.

In multi-instance mode, these requirements apply **per entry** — one pod
reaching N databases still needs a valid network path to all N of them.

## TLS

`tls.insecure: false` and `tls.insecure_skip_verify: false` are the
receiver's fixed defaults (requiring an encrypted connection with
certificate validation) — not `values.yaml` fields in either mode. Use
`additionalReceiverConfig.tls.insecure_skip_verify=true` to skip
certificate validation (useful for self-signed certs in test
environments, but weakens the connection's security guarantees), and
`additionalReceiverConfig.tls.ca_file` to a CA bundle path mounted into
the collector container if the MySQL server's certificate isn't in the
default trust store — for example, an **Amazon RDS instance with "Require
SSL/TLS" enforcement needs `ca_file` pointed at Amazon's RDS CA bundle**.
Confirm these flags' actual behavior against a real MySQL instance
requiring TLS before relying on this in production — see `TESTING.md`.

In multi-instance mode, `tls.*` (like the other scrape-behavior settings)
is one shared value applied to every entry via `additionalReceiverConfig`,
not configurable per instance — see "Multi-instance schema" below for why.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring user and grants it
`SELECT` on `performance_schema.*`, using a separate admin credential —
**required**, no plain-value path, since it can `CREATE USER` and grant
broad `performance_schema` access:

- **Single-instance**: one Job, using `mysql.username`/`mysql.existingSecret`
  for the monitoring user and `setupJob.mysqlAdmin.existingSecret` for the
  admin credential.
- **Multi-instance**: one Job **per entry** (named `<release>-setup-<name>`),
  each using that entry's own `existingSecret` and `mysqlAdmin.existingSecret`
  — separate MySQL instances normally have independent admin passwords, so
  there's no shared admin credential option.

`setupJob.enableWaitTimeMetrics` (default `true`, opt-out) also grants
`UPDATE` on `performance_schema.setup_consumers`, so the receiver can
enable the `events_waits_current` consumer itself on reconnect — needed
for lock-wait duration tracking, since that consumer resets on
restart/failover. This is the RDS-specific workaround from New Relic's
[mysql/advanced-config docs, "Enable lock-wait duration
tracking"](https://docs.newrelic.com/docs/opentelemetry/database/mysql/advanced-config/#lock)
(self-managed MySQL instead sets
`performance-schema-consumer-events-waits-current=ON` in `my.cnf`, which
this chart has no way to touch). Applies to every entry's Job identically
in multi-instance mode (one shared toggle, not per-entry). Set to `false`
to skip it.

**This setup Job does not create the `explain_statement` procedure**
`mysql.explainMode: procedure` depends on — that receiver mode collects
`EXPLAIN` plans for write statements without granting DML privileges to
the monitoring user, but requires a `SQL SECURITY DEFINER` stored
procedure to exist first. If you want that, follow New Relic's
[mysql/advanced-config docs, "Query plans for write
statements"](https://docs.newrelic.com/docs/opentelemetry/database/mysql/advanced-config/#query)
and create the procedure yourself; leaving `explainMode: inline` (the
default) needs no extra setup.

This requires a `mysql`-CLI-capable image (shared across every entry's Job
in multi-instance mode — one image, not one per instance), and **this
chart ships no default one** — same as `postgresql-otel`/`mssql-otel`.
The official, actively-maintained, freely-pullable `mysql:8.4` image is a
reasonable choice:

```
--set setupJob.image.repository=mysql --set setupJob.image.tag=8.4
```

**Known limitation:** the setup Job builds its `CREATE USER`/`GRANT`
statements by shell-expanding the monitoring credentials directly into a
SQL heredoc. This is not injection-safe against an adversarial password (a
password containing `'` could break out of the quoted SQL string) — the
same trust model as this chart family's other setup Jobs. Credentials are
expected to come from the same operator running the install, not
attacker-controlled input.

If you'd rather not grant this chart admin-level MySQL access at all,
leave `setupJob.enabled: false` and create the monitoring user yourself
before installing (once per instance, in multi-instance mode):
```sql
CREATE USER IF NOT EXISTS 'nr_monitor'@'%' IDENTIFIED BY '<password>';
GRANT SELECT ON performance_schema.* TO 'nr_monitor'@'%';
FLUSH PRIVILEGES;
```

## Single-instance schema (`mysql:`)

The default mode — one release, one MySQL instance:

```yaml
mysql:
  topology: "self-hosted"
  server: "mysql.example.internal"
  port: 3306
  existingSecret: "db-monitor-creds"   # or username/password as plain values

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"
```

Unlike multi-instance mode, plain-value credentials are allowed here
(`mysql.username`/`mysql.password`) if you don't want to create a Secret
yourself — mainly useful for quick local testing, not recommended for
production. `mysql.existingSecret` wins over the plain values if both are
set.

## Multi-instance schema (`mysqlMulti:`)

Setting `mysqlMulti.enabled: true` switches to an alternative, fully
opt-in mode: one release, one collector pod, monitoring every entry in
`mysqlMulti.databases`. This is additive: `mysqlMulti` is a separate values
block from `mysql:`, and the two are mutually exclusive in a single
release.

**Without the setup Job** (`setupJob.enabled: false`, the default — you
create the monitoring user yourself per "If you'd rather not grant this
chart admin-level MySQL access at all" above, once per instance):

```yaml
mysqlMulti:
  enabled: true
  topology: "self-hosted"
  databases:
    - name: db1
      server: "mysql-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
    - name: db2
      server: "mysql-db-2.example.internal"
      existingSecret: "db2-monitor-creds"

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"
```

**With the setup Job** (`setupJob.enabled: true` — a top-level field,
shared with single-instance mode, **not** nested under `mysqlMulti`;
each entry additionally needs its own `mysqlAdmin.existingSecret`):

```yaml
mysqlMulti:
  enabled: true
  topology: "self-hosted"
  databases:
    - name: db1
      server: "mysql-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
      mysqlAdmin:
        existingSecret: "db1-admin-creds"
    - name: db2
      server: "mysql-db-2.example.internal"
      existingSecret: "db2-monitor-creds"
      mysqlAdmin:
        existingSecret: "db2-admin-creds"

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"

setupJob:
  enabled: true
  image:
    repository: mysql
    tag: "8.4"
```
This runs one setup Job per entry (see "Automated setup" above), each
using that entry's own `mysqlAdmin.existingSecret`.

Each entry requires `name` (unique within the release), `server`, and
`existingSecret` — there is no plain-value credential path in this mode,
unlike `mysql:`. `port` defaults to `3306` per entry if not set, and
`database` is optional per entry, mirroring `mysql.database`.

`allowNativePasswords`, `collectionInterval`, `initialDelay`, and
`explainMode`, which **are** configurable for the single-instance chart,
are **not configurable at all in multi-instance mode** — every entry
shares the same fixed defaults (identical values to `mysql:`'s own
defaults). `tls`, the query-sampling/top-query events, `statementEvents`,
`querySampleCollection`, and `topQueryCollection` aren't `values.yaml` fields in *either* mode —
both share the same hardcoded defaults, matching
`oracle-otel`/`mssql-otel`'s pattern of fixed scrape behavior rather than
per-field values.yaml knobs. Use `additionalReceiverConfig` if you need to
override any of it — same global escape hatch in both modes. A
single-entry `databases` list is
valid too (e.g. as a values-file template meant to scale from 1 to N) — it
just renders as a plain receiver with none of the sharing behavior
described next, since there's nothing to share with.

**How the generated config stays compact with many entries:** with 2+
entries, the first database's receiver carries the full scrape-behavior
config and is tagged with a YAML anchor (`&nrmysql-common`); every entry
after that is a short `<<: *nrmysql-common` override carrying only its own
`endpoint`/`username`/`password`/`database` — this matches New Relic's own
documented MySQL multi-receiver pattern
(https://docs.newrelic.com/docs/opentelemetry/database/mysql/multi-receiver/#multi).

**Known limitation:** because every entry shares one pipeline and processor,
that processor's `server.address`/`server.port` resource attributes are
only correct for the *first* entry in `mysqlMulti.databases` — every other
entry's metrics/events carry the first entry's server/port. Same accepted
tradeoff as `oracle-otel`'s `oracleMulti`.

## Values

Shared across both modes:

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `otlpEndpoint` | New Relic OTLP/gRPC endpoint. Bare host:port is recommended (e.g. `otlp.nr-data.net:4317`); a scheme'd URL is tolerated too | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into every `nrmysql` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user-creation Job(s) | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `mysql`-CLI image, shared across every Job — **required** when enabled, no default | `""` |
| `setupJob.enableWaitTimeMetrics` | Grant `UPDATE` on `performance_schema.setup_consumers`, every entry in multi mode; set `false` to opt out | `true` |
| `resources` / `nodeSelector` / `tolerations` / `affinity` | Standard Pod scheduling/sizing fields | `{}` / `{}` / `[]` / `{}` |

Single-instance schema (`mysql:`, ignored when `mysqlMulti.enabled: true`):

| Key | Description | Default |
|---|---|---|
| `mysql.topology` | `self-hosted` or `rds` — always required | `""` |
| `mysql.server` | MySQL host/endpoint | `""` |
| `mysql.port` | MySQL port | `3306` |
| `mysql.username` / `mysql.password` | Plain-value monitoring credentials | `""` |
| `mysql.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `mysql.database` | Restrict monitoring to one database; empty monitors all | `""` |
| `mysql.allowNativePasswords` | Receiver's allow_native_passwords | `true` |
| `mysql.collectionInterval` | Scrape interval | `10s` |
| `mysql.initialDelay` | Delay before first scrape | `1s` |
| `mysql.explainMode` | `inline` or `procedure` — `procedure` needs a manually-created `explain_statement` procedure, see "Automated setup" | `inline` |
| `setupJob.mysqlAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if `setupJob.enabled` | `""` |

`tls`, `statementEvents`, query-sampling/top-query events, `query_sample_collection`, and
`top_query_collection` are **not** `values.yaml` fields (single- or multi-instance) — they're fixed defaults
shared by both modes (matches `oracle-otel`/`mssql-otel`'s pattern). Use `additionalReceiverConfig` to
override any of them, e.g. `additionalReceiverConfig.tls.insecure_skip_verify=true`,
`additionalReceiverConfig.statement_events.limit=1000`, or
`additionalReceiverConfig.top_query_collection.top_query_count=100`.

Multi-instance schema (`mysqlMulti:`, mutually exclusive with `mysql.*`):

| Key | Description | Default |
|---|---|---|
| `mysqlMulti.enabled` | Enables multi-instance mode | `false` |
| `mysqlMulti.topology` | `self-hosted` or `rds` — kept for parity, no rendered effect | `""` |
| `mysqlMulti.databases` | List of `{name, server, port, existingSecret, database, mysqlAdmin.existingSecret}` entries, one per monitored instance | `[]` |

Scrape-behavior settings (`allowNativePasswords`, `collectionInterval`,
`initialDelay`, `explainMode`, etc.) are not configurable in multi-instance
mode — every entry uses the same fixed defaults as `mysql:`'s own
defaults. Use `additionalReceiverConfig` to override any of it.
