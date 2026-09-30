# mssql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrsqlserver` receiver (currently **Preview**) to monitor Microsoft SQL
Server and export the results to New Relic over OTLP. One release runs
one collector pod, monitoring either a single SQL Server instance
(`mssql:`) or multiple instances (`mssqlMulti:`) — see "Which mode do I
need?" below.

## Which mode do I need?

| Your situation | Use | Schema |
|---|---|---|
| One SQL Server instance | Single-instance mode | [`mssql:`](#single-instance-schema-mssql) |
| Multiple instances, one release | Multi-instance mode | [`mssqlMulti:`](#multi-instance-schema-mssqlmulti) |

The two are mutually exclusive within a single release — setting both
`mssql.server` and `mssqlMulti.enabled: true` fails the render. Aside from
that schema choice, everything below through "Automated setup" applies to
both modes: networking and the setup Job all work the same way, just
applied per instance in the multi case.

## What this chart does not do

- Support Windows/domain/gMSA authentication. This isn't a config
  difference the way Amazon RDS vs. self-hosted is — Windows-integrated auth
  requires the *collector process itself* to run under a Windows/AD
  identity. New Relic does not publish a Windows container image for
  `nrdot-collector` anywhere (only a Linux container image, plus a separate
  Windows `.exe`/`.msi` binary/installer — different artifacts). Supporting
  this would mean building and maintaining an unofficial Windows container
  image ourselves (pinned to a specific Windows Server host-OS build, since
  Windows containers enforce strict host/container OS-build matching, unlike
  Linux), plus requiring the operator to install the out-of-tree
  `k8s-gmsa` CRD/webhooks. This chart only supports SQL authentication
  (username/password), which works identically whether SQL Server itself
  runs on Linux or Windows, self-hosted or on RDS, since the collector
  always reaches it remotely over the network.
- Report host/infrastructure metrics for the machine(s) SQL Server runs on.
  New Relic's docs show a "Full-feature configuration" that adds
  `host_metrics`/`otlp` (for traces) receivers and a `resourcedetection`
  processor chain — that only makes sense for a collector running directly
  on the SQL Server's own host OS. This chart runs the collector as a
  Kubernetes Deployment reaching SQL Server remotely, so it implements only
  the standalone "Standard configuration" shape.

## Choosing the topology

| Your setup | Topology value |
|---|---|
| Amazon RDS for SQL Server | `rds` |
| Self-hosted SQL Server (Linux or Windows, reached over the network) | `self-hosted` |

This is `mssql.topology` in single-instance mode, or `mssqlMulti.topology`
in multi-instance mode — always required either way, but — unlike
`oracle-otel`'s `oracle.topology` — it does not currently change any
rendered output. The grant script and receiver defaults are identical for
`self-hosted` and `rds` (the grant script's system-database exclusion list
always excludes `rdsadmin`, which is a harmless no-op on self-hosted
instances where that database simply doesn't exist). It's validated and
required anyway, for documentation clarity and to leave room for a future
difference without a breaking change.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to each
  instance's `server:port` (VPN, peering, or shared network), DNS
  resolution if it's a hostname, and the SQL Server-side firewall must
  allow the connection's actual source IP (which may be a NAT gateway, not
  the Pod IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or
  shared-VPC placement with each RDS instance, and each RDS security group
  must allow the SQL Server port (1433 by default) from the cluster's
  egress source.

In multi-instance mode, these requirements apply **per entry** — one pod
reaching N instances still needs a valid network path to all N of them.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring login and grants it
read-only access (`VIEW SERVER STATE`, `VIEW ANY DEFINITION`,
`VIEW ANY DATABASE`, and per-database `VIEW DATABASE STATE`), using a
separate admin credential — **required**, no plain-value path, since it
can create logins and grant broad `VIEW` access:

- **Single-instance**: one Job, using `mssql.username`/
  `mssql.existingSecret` for the monitoring login and
  `setupJob.sqlAdmin.existingSecret` for the admin credential.
- **Multi-instance**: one Job **per entry** (named `<release>-setup-<name>`),
  each using that entry's own `existingSecret` and `sqlAdmin.existingSecret`
  — separate SQL Server instances normally have independent admin
  passwords, so there's no shared admin credential option. Every Job
  mounts the same shared `grants.sql` ConfigMap, since the grant script
  itself doesn't vary by instance or topology.

Every admin credential must be able to run `CREATE LOGIN` and
server-level `GRANT` statements — a `sysadmin`-role login (e.g. `sa`, or
an RDS master user).

This requires a `sqlcmd`-capable image (shared across every entry's Job
in multi-instance mode — one image, not one per instance). Unlike
Oracle's Instant Client, Microsoft does publish a freely, anonymously
pullable image with `sqlcmd` at `mcr.microsoft.com/mssql-tools:latest` —
no license click-through required. However, that image is dated **2017**
and appears unmaintained (classic ODBC-based `sqlcmd`, not the current
`mssql-tools18`/go-sqlcmd). **Confirm you're comfortable with that image's
age (including any unpatched CVEs) before using it, or build a current
image yourself from Microsoft's `mssql-tools18` apt packages** — this
README intentionally does not default `setupJob.image.repository`/`tag`
to it, since a chart default shouldn't silently commit users to a stale
base image.

If you'd rather not grant this chart admin-level SQL Server access at
all, leave `setupJob.enabled: false` and run `files/setup/grants.sql`
yourself, as a `sysadmin`, before installing (once per instance, in
multi-instance mode).

## Single-instance schema (`mssql:`)

The default mode — one release, one SQL Server instance:

```yaml
mssql:
  topology: "self-hosted"
  server: "sqlserver.example.internal"
  port: 1433
  existingSecret: "db-monitor-creds"   # or username/password as plain values

otlpEndpoint: "https://otlp.nr-data.net:4318"
licenseKey: "<your New Relic license key>"
```

Unlike multi-instance mode, plain-value credentials are allowed here
(`mssql.username`/`mssql.password`) if you don't want to create a Secret
yourself — mainly useful for quick local testing, not recommended for
production. `mssql.existingSecret` wins over the plain values if both are
set.

## Multi-instance schema (`mssqlMulti:`)

Setting `mssqlMulti.enabled: true` switches to an alternative, fully
opt-in mode: one release, one collector pod, monitoring every entry in
`mssqlMulti.databases`. This is additive: `mssqlMulti` is a separate
values block from `mssql:`, and the two are mutually exclusive in a
single release.

**Without the setup Job** (`setupJob.enabled: false`, the default — you
run `files/setup/grants.sql` yourself per "If you'd rather not grant
admin-level SQL Server access" above, once per instance):

```yaml
mssqlMulti:
  enabled: true
  topology: "self-hosted"
  databases:
    - name: db1
      server: "sqlserver-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
    - name: db2
      server: "sqlserver-db-2.example.internal"
      existingSecret: "db2-monitor-creds"

otlpEndpoint: "https://otlp.nr-data.net:4318"
licenseKey: "<your New Relic license key>"
```

**With the setup Job** (`setupJob.enabled: true` — a top-level field,
shared with single-instance mode, **not** nested under `mssqlMulti`; each
entry additionally needs its own `sqlAdmin.existingSecret`):

```yaml
mssqlMulti:
  enabled: true
  topology: "self-hosted"
  databases:
    - name: db1
      server: "sqlserver-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
      sqlAdmin:
        existingSecret: "db1-admin-creds"
    - name: db2
      server: "sqlserver-db-2.example.internal"
      existingSecret: "db2-monitor-creds"
      sqlAdmin:
        existingSecret: "db2-admin-creds"

otlpEndpoint: "https://otlp.nr-data.net:4318"
licenseKey: "<your New Relic license key>"

setupJob:
  enabled: true
  image:
    repository: "<confirmed sqlcmd-capable image>"
    tag: "<confirmed tag>"
```
This runs one setup Job per entry (see "Automated setup" above), each
using that entry's own `sqlAdmin.existingSecret`.

Each entry requires `name` (unique within the release), `server`, and
`existingSecret` — there is no plain-value credential path in this mode,
unlike `mssql:`. `port` defaults to `1433` per entry if not set. Unlike
the other three charts in this family, there's no `endpoint`/`database`
field at all here — `server` and `port` are always two separate fields,
matching this chart's own single-instance schema and New Relic's
documented SQL Server multi-receiver example.

Everything else that's configurable for the single-instance chart
(`collectionInterval`, plus the receiver's metrics/events/query-collection
defaults) is **not configurable at all in multi-instance mode** — every
entry shares the same fixed defaults (identical values to `mssql:`'s own
defaults), matching `oracle-otel`/`mysql-otel`/`postgresql-otel`'s pattern
of hardcoded shared scrape behavior rather than per-field values.yaml
knobs. Use `additionalReceiverConfig` if you need to override any of it —
same global escape hatch as single-instance mode. A single-entry
`databases` list is valid too (e.g. as a values-file template meant to
scale from 1 to N) — it just renders as a plain receiver with none of the
sharing behavior described next, since there's nothing to share with.

**How the generated config stays compact with many entries:** with 2+
entries, the first database's receiver carries the full scrape-behavior
config and is tagged with a YAML anchor (`&nrsqlserver-common`); every
entry after that is a short `<<: *nrsqlserver-common` override carrying
only its own `username`/`password`/`server`/`port` — this matches New
Relic's own documented SQL Server multi-receiver pattern.

**No host-identification limitation to document here**, unlike
`oracleMulti`/`mysqlMulti`/`postgresqlMulti`: this chart's `processors:`
block (`memory_limiter`+`batch`) never included a per-instance
`resource.server.address`-style attribute in the first place, even in
single-instance mode, so there's nothing that becomes "only correct for
the first entry" when moving to multi-instance — there was never a
per-instance identifying attribute to begin with.

## Values

Shared across both modes:

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `otlpEndpoint` | New Relic endpoint for your account's region, full URL with scheme required (e.g. `https://otlp.nr-data.net:4318` for US) — validated at render time | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into every `nrsqlserver` receiver block | `{}` |
| `setupJob.enabled` | Run the automated login-creation Job(s) | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `sqlcmd`-capable image, shared across every Job | `""` |
| `resources` / `nodeSelector` / `tolerations` / `affinity` | Standard Pod scheduling/sizing fields | `{}` / `{}` / `[]` / `{}` |

Single-instance schema (`mssql:`, ignored when `mssqlMulti.enabled: true`):

| Key | Description | Default |
|---|---|---|
| `mssql.topology` | `self-hosted` or `rds` — always required | `""` |
| `mssql.server` | SQL Server host/endpoint | `""` |
| `mssql.port` | SQL Server port | `1433` |
| `mssql.username` / `mssql.password` | Plain-value monitoring credentials | `""` |
| `mssql.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `mssql.collectionInterval` | Scrape interval | `15s` |
| `setupJob.sqlAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if `setupJob.enabled` | `""` |

Multi-instance schema (`mssqlMulti:`, mutually exclusive with `mssql.*`):

| Key | Description | Default |
|---|---|---|
| `mssqlMulti.enabled` | Enables multi-instance mode | `false` |
| `mssqlMulti.topology` | `self-hosted` or `rds` — kept for parity, no rendered effect | `""` |
| `mssqlMulti.databases` | List of `{name, server, port, existingSecret, sqlAdmin.existingSecret}` entries, one per monitored instance | `[]` |
