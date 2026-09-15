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
- Auto-select an Amazon RDS CA bundle for you. `tls.caFile` is a plain
  value you supply — a chart-hardcoded default risks going stale as Amazon
  rotates CA bundles.

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

Set `tls.insecure: false` (the default) to require an encrypted
connection, `tls.insecureSkipVerify: true` to skip certificate validation
(useful for self-signed certs in test environments, but weakens the
connection's security guarantees), and `tls.caFile` to a CA bundle path
mounted into the collector container if the MySQL server's certificate
isn't in the default trust store — for example, an **Amazon RDS instance
with "Require SSL/TLS" enforcement needs `caFile` pointed at Amazon's RDS
CA bundle**. Confirm these flags' actual behavior against a real MySQL
instance requiring TLS before relying on this in production — see
`TESTING.md`.

In multi-instance mode, `tls.*` (like the other scrape-behavior settings)
is one shared value applied to every entry, not configurable per instance
— see "Multi-instance schema" below for why.

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

Set `setupJob.enableWaitTimeMetrics: true` to also grant `UPDATE` on
`performance_schema.setup_consumers`, needed for wait-time data — this is
optional per New Relic's docs, and applies to every entry's Job identically
in multi-instance mode (one shared toggle, not per-entry).

This requires a `mysql`-CLI-capable image (shared across every entry's Job
in multi-instance mode — one image, not one per instance). Unlike the other
two charts in this family, `setupJob.image` defaults to the official,
actively-maintained `mysql:8.4` image — no license click-through required,
so enabling the setup Job needs no extra `--set` flags for the image.
Override `setupJob.image.repository`/`tag` if you need a different version.

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

```yaml
mysqlMulti:
  enabled: true
  topology: "self-hosted"
  databases:
    - name: db1
      server: "mysql-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
      mysqlAdmin:
        existingSecret: "db1-admin-creds"   # only required if setupJob.enabled
    - name: db2
      server: "mysql-db-2.example.internal"
      existingSecret: "db2-monitor-creds"
      mysqlAdmin:
        existingSecret: "db2-admin-creds"

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"
```

Each entry requires `name` (unique within the release), `server`, and
`existingSecret` — there is no plain-value credential path in this mode,
unlike `mysql:`. `port` defaults to `3306` per entry if not set, and
`database` is optional per entry, mirroring `mysql.database`.

Everything else that's configurable for the single-instance chart
(`allowNativePasswords`, `collectionInterval`, `initialDelay`, `explainMode`,
`tls`, `statementEvents`, `querySampleCollection`, `topQueryCollection`,
`events`) is **not configurable at all in multi-instance mode** — every
entry shares the same fixed defaults (identical values to `mysql:`'s own
defaults), matching `oracle-otel`'s pattern of hardcoded shared scrape
behavior rather than per-field values.yaml knobs. Use
`additionalReceiverConfig` if you need to override any of it — same global
escape hatch as single-instance mode. A single-entry `databases` list is
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
tradeoff as `oracle-otel`'s `oracleMulti` — see
`docs/superpowers/specs/2026-09-16-mysql-otel-multi-instance-design.md` for
the full rationale.

## Values

Shared across both modes:

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `otlpEndpoint` | New Relic OTLP/gRPC endpoint, bare host:port, no scheme | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into every `nrmysql` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user-creation Job(s) | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `mysql`-CLI image, shared across every Job | `mysql` / `8.4` |
| `setupJob.enableWaitTimeMetrics` | Also grant `UPDATE` on `performance_schema.setup_consumers`, every entry in multi mode | `false` |
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
| `mysql.explainMode` | `inline` or `procedure` | `inline` |
| `mysql.tls.insecure` / `insecureSkipVerify` / `caFile` | TLS connection settings | `false` / `false` / `""` |
| `mysql.statementEvents.*` | `digestTextLimit`, `timeLimit`, `limit` | `4096` / `24h` / `500` |
| `mysql.querySampleCollection.*` | `maxRowsPerQuery`, `allowedCommentKeys` | `100` / `[nr_service_guid]` |
| `mysql.topQueryCollection.*` | `lookbackTime`, `maxQuerySampleCount`, `topQueryCount`, `collectionInterval`, `queryPlanCacheSize`, `queryPlanCacheTtl`, `allowedCommentKeys` | see `values.yaml` |
| `mysql.events.querySample.enabled` / `topQuery.enabled` | Enable the query-sample/top-query log events | `true` / `true` |
| `setupJob.mysqlAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if `setupJob.enabled` | `""` |

Multi-instance schema (`mysqlMulti:`, mutually exclusive with `mysql.*`):

| Key | Description | Default |
|---|---|---|
| `mysqlMulti.enabled` | Enables multi-instance mode | `false` |
| `mysqlMulti.topology` | `self-hosted` or `rds` — kept for parity, no rendered effect | `""` |
| `mysqlMulti.databases` | List of `{name, server, port, existingSecret, database, mysqlAdmin.existingSecret}` entries, one per monitored instance | `[]` |

Scrape-behavior settings (`allowNativePasswords`, `collectionInterval`,
`tls`, `statementEvents`, etc.) are not configurable in multi-instance mode
— every entry uses the same fixed defaults as `mysql:`'s own defaults. Use
`additionalReceiverConfig` to override any of it.
