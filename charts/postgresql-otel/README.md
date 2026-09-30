# postgresql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrpostgresql` receiver (currently **Preview**) to monitor PostgreSQL and
export the results to New Relic over OTLP. One release runs one collector
pod, monitoring either a single PostgreSQL instance (`postgresql:`) or
multiple instances (`postgresqlMulti:`) — see "Which mode do I need?"
below.

## Which mode do I need?

| Your situation | Use | Schema |
|---|---|---|
| One PostgreSQL instance (one or more databases on it) | Single-instance mode | [`postgresql:`](#single-instance-schema-postgresql) |
| Multiple instances, one release | Multi-instance mode | [`postgresqlMulti:`](#multi-instance-schema-postgresqlmulti) |

**Important naming distinction, unrelated to which mode you pick**:
"databases" always means individual database names on *one* PostgreSQL
server — PostgreSQL has no "monitor every database" mode, so both modes
require you to list them explicitly. "Instance" means a separate
PostgreSQL server. `postgresqlMulti.instances` is a list of *instances*,
and each instance entry has its own `databases` list — so multi-instance
mode is instances × databases-per-instance, not a rename of the existing
`postgresql.databases` concept.

The two modes are mutually exclusive within a single release — setting
both `postgresql.server` and `postgresqlMulti.enabled: true` fails the
render. Aside from that schema choice, everything below through "Automated
setup" applies to both modes: server-level prerequisites, networking, and
the setup Job all work the same way, just applied per instance (and per
database within each instance) in the multi case.

## What this chart does not do

- **Configure TLS.** This chart does not expose or render any `tls`
  block for the receiver; it connects with whatever the `nrpostgresql`
  receiver's own defaults are.
- **Support `db_auth` credential providers** (e.g. AWS IAM
  authentication instead of a static password). The receiver supports a
  `db_auth` block, mutually exclusive with `password`, but this chart
  always configures a username/password credential. Reachable via
  `additionalReceiverConfig` if you need it, though you'd also need to
  work around this chart always rendering a `password`.
- **Automate the server-level prerequisites.** See the next section —
  they require a database restart, which nothing running inside your
  Kubernetes cluster can perform.
- Mix topologies within one release — `postgresqlMulti` requires every
  instance to share one topology, and a single-instance release only ever
  has one topology by definition.
- Report host/infrastructure metrics for the machine(s) PostgreSQL runs
  on. New Relic's docs show a "Full-feature configuration" adding a
  `host_metrics` receiver and split host/db/traces pipelines — that only
  makes sense for a collector running directly on the PostgreSQL host's
  own OS. This chart implements only the standalone "Standard
  configuration" shape.

## Server-level prerequisites — do this first

PostgreSQL **14 or newer** is required. Before installing this chart (or
enabling `setupJob`), the following server parameters must be in place, on
**every** instance you plan to monitor. `pg_stat_statements` cannot be
created at all without `shared_preload_libraries`, and that parameter
requires a **restart** — so this cannot be automated from inside the
cluster.

| Parameter | Value |
|---|---|
| `shared_preload_libraries` | `pg_stat_statements` |
| `pg_stat_statements.track` | `ALL` |
| `pg_stat_statements.max` | `10000` |
| `pg_stat_statements.save` | `on` |
| `track_activity_query_size` | `4096` |
| `track_functions` | `all` |

- **Self-hosted**: set these in `postgresql.conf`, then restart
  PostgreSQL. Some distributions need the `postgresql-contrib` package
  installed for `pg_stat_statements` to be available.
- **Amazon RDS / Aurora**: set these in the DB **parameter group**, not a
  config file. `track_activity_query_size` and `pg_stat_statements.max`
  are *static* parameters — apply them with
  `apply_method: pending-reboot` and then reboot the instance. Applying
  them immediately fails with `InvalidParameterCombination`. For Aurora,
  the parameter-group family name must match your engine's major version
  exactly (e.g. `aurora-postgresql16`).

## Choosing the topology

| Your setup | Topology value |
|---|---|
| Amazon RDS for PostgreSQL | `rds` |
| Self-hosted PostgreSQL (reached over the network) | `self-hosted` |

This is `postgresql.topology` in single-instance mode, or
`postgresqlMulti.topology` in multi-instance mode — always required either
way, but it does not currently change any rendered output. It exists for
documentation clarity and as a validated, forward-compatible schema slot,
the same precedent as `mssql-otel`'s and `mysql-otel`'s `topology`.

## `databases` and `excludeDatabases`

In single-instance mode, `postgresql.databases` is a **required,
non-empty list**:

```yaml
postgresql:
  databases:
    - appdb
    - reporting
```

In multi-instance mode, each entry in `postgresqlMulti.instances` has its
own required, non-empty `databases` list, with the same meaning — see
"Which mode do I need?" above for why this isn't the same thing as the
list of instances itself.

`excludeDatabases` (a shared, hardcoded default of `[rdsadmin]` in both
modes — not a values.yaml field) exists because top-query and
query-sample collection scan cluster-wide regardless of the `databases`
list, and on RDS the monitoring user can never reach `rdsadmin`. It's only
applied when the topology is `rds` — on self-hosted PostgreSQL that
database doesn't exist, so it's omitted there.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to each
  instance's `server:port` (VPN, peering, or shared network), DNS
  resolution if it's a hostname, and the PostgreSQL-side
  `pg_hba.conf`/firewall must allow the connection's actual source IP
  (which may be a NAT gateway, not the Pod IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or
  shared-VPC placement with each RDS instance, and each RDS security group
  must allow the PostgreSQL port (5432 by default) from the cluster's
  egress source.

In multi-instance mode, these requirements apply **per instance** — one
pod reaching N instances still needs a valid network path to all N of
them.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring role and, for every
database in scope, creates the `otel` schema, grants the monitoring user
`USAGE`/`SELECT`/`pg_monitor`, and creates the `pg_stat_statements`
extension:

- **Single-instance**: one Job, looping over every entry in
  `postgresql.databases`, using `postgresql.username`/
  `postgresql.existingSecret` for the monitoring role and
  `setupJob.postgresAdmin.existingSecret` for the admin credential.
- **Multi-instance**: one Job **per instance** (named
  `<release>-setup-<name>`), each looping over that instance's own
  `databases` list, using that instance's own `existingSecret` and
  `postgresAdmin.existingSecret` — separate PostgreSQL instances normally
  have independent admin passwords, so there's no shared admin credential
  option.

Every admin credential must be a superuser (self-hosted) or an
`rds_superuser`-equivalent (RDS), since it needs `CREATE USER`,
`CREATE SCHEMA`, and `CREATE EXTENSION`.

This requires a `psql`-capable image (shared across every instance's Job
in multi-instance mode — one image, not one per instance), and **this
chart ships no default one** — unlike `mysql-otel`, no free,
actively-maintained PostgreSQL-client image has been verified for this
purpose yet. The official `postgres` image bundles `psql` and is a
reasonable choice:

```
--set setupJob.image.repository=postgres --set setupJob.image.tag=16
```

Two extras, applied to every database in every instance identically
(single shared toggle, not per-instance or per-database):

- `setupJob.enablePgvector: true` (default `false`, opt-in) also runs
  `CREATE EXTENSION IF NOT EXISTS vector` in each database, for vector
  metrics (the `l1`/`hamming`/`jaccard` distance functions need pgvector
  0.7.0+).
- `setupJob.enableExplainPermissions` (default `true`, opt-out) also
  creates the `otel.explain_statement` `SECURITY DEFINER` function and
  grants `EXECUTE` on it, letting the receiver run `EXPLAIN` against
  locking/write queries without holding write grants. Set to `false` to
  skip creating it.

### You usually don't need to set `explain_function_name`

The receiver's **own default** for `top_query_collection.
explain_function_name` is already `otel.explain_statement` — the exact
function `setupJob.enableExplainPermissions` creates. This isn't a
values.yaml field in either single- or multi-instance mode — it's a
fixed default the receiver already applies with no extra configuration.
Use `additionalReceiverConfig.top_query_collection.explain_function_name`
if you need a non-default function name.

The receiver probes for the function's availability per database and
re-checks periodically (the receiver's own default caching behavior;
this chart doesn't expose a value to override it), falling back to
inline `EXPLAIN` when it isn't there — so setting
`enableExplainPermissions: false` is safe and simply means write and
locking statements don't get query plans.

### Credential handling in the setup Job

Unlike this chart family's other setup Jobs, credentials are **not**
shell-expanded into SQL text. The admin credential reaches `psql` through
its own `PGUSER`/`PGPASSWORD` environment variables (never as CLI flags,
so it stays out of any in-Pod process listing), and the monitoring
credentials are passed as `psql` variables interpolated by `psql` itself
as a quoted identifier (`:"monitor_user"`) or quoted literal
(`:'monitor_password'`). Every heredoc is single-quoted, so the shell
performs no expansion inside them. A password containing quotes or
dollar signs is handled correctly.

### If you'd rather not grant admin access

Leave `setupJob.enabled: false` and run the equivalent SQL yourself as a
superuser, on every instance you plan to monitor. Cluster-level, once:

```sql
CREATE USER nr_monitor WITH LOGIN PASSWORD '<password>';
ALTER ROLE nr_monitor INHERIT;   -- required on PG15+, a no-op on PG14
```

Then in **every** database you're monitoring on that instance:

```sql
CREATE SCHEMA IF NOT EXISTS otel;
GRANT USAGE ON SCHEMA otel TO nr_monitor;
GRANT USAGE ON SCHEMA public TO nr_monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO nr_monitor;
GRANT pg_monitor TO nr_monitor;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## Single-instance schema (`postgresql:`)

The default mode — one release, one PostgreSQL instance, one or more
databases on it:

```yaml
postgresql:
  topology: "self-hosted"
  server: "postgresql.example.internal"
  port: 5432
  existingSecret: "db-monitor-creds"   # or username/password as plain values
  databases:
    - appdb
    - reporting

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"
```

Unlike multi-instance mode, plain-value credentials are allowed here
(`postgresql.username`/`postgresql.password`) if you don't want to create
a Secret yourself — mainly useful for quick local testing, not recommended
for production. `postgresql.existingSecret` wins over the plain values if
both are set.

## Multi-instance schema (`postgresqlMulti:`)

Setting `postgresqlMulti.enabled: true` switches to an alternative, fully
opt-in mode: one release, one collector pod, monitoring every entry in
`postgresqlMulti.instances`. This is additive: `postgresqlMulti` is a
separate values block from `postgresql:`, and the two are mutually
exclusive in a single release.

**Without the setup Job** (`setupJob.enabled: false`, the default — you create the monitoring role/grants yourself per "If you'd rather not grant admin access" above, once per instance):

```yaml
postgresqlMulti:
  enabled: true
  topology: "self-hosted"
  instances:
    - name: db1
      server: "postgresql-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
      databases:
        - appdb1
    - name: db2
      server: "postgresql-db-2.example.internal"
      existingSecret: "db2-monitor-creds"
      databases:
        - appdb2

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"
```

**With the setup Job** (`setupJob.enabled: true` — a top-level field, shared with single-instance mode, **not** nested under `postgresqlMulti`; each instance additionally needs its own `postgresAdmin.existingSecret`):

```yaml
postgresqlMulti:
  enabled: true
  topology: "self-hosted"
  instances:
    - name: db1
      server: "postgresql-db-1.example.internal"
      existingSecret: "db1-monitor-creds"
      databases:
        - appdb1
      postgresAdmin:
        existingSecret: "db1-admin-creds"
    - name: db2
      server: "postgresql-db-2.example.internal"
      existingSecret: "db2-monitor-creds"
      databases:
        - appdb2
      postgresAdmin:
        existingSecret: "db2-admin-creds"

otlpEndpoint: "otlp.nr-data.net:4317"
licenseKey: "<your New Relic license key>"

setupJob:
  enabled: true
  image:
    repository: postgres
    tag: "16"
```
This runs one setup Job per instance (see "Automated setup" above), each
using that instance's own `postgresAdmin.existingSecret`.

Each entry requires `name` (unique within the release), `server`,
`existingSecret`, and a non-empty `databases` list — there is no
plain-value credential path in this mode, unlike `postgresql:`. `port`
defaults to `5432` per entry if not set.

`collectionInterval` and `excludeDatabases`, which **are** configurable
for the single-instance chart, are **not configurable at all in
multi-instance mode** — every entry shares the same fixed defaults
(`15s` collection interval, `[rdsadmin]` excluded on RDS). The
query-sampling/top-query events, `topQueryCollection`,
`querySampleCollection`, and per-metric toggles aren't `values.yaml`
fields in *either* mode — both share the same hardcoded defaults,
matching `oracle-otel`/`mssql-otel`'s pattern of fixed scrape behavior
rather than per-field values.yaml knobs. Use `additionalReceiverConfig`
if you need to override any of this — same global escape hatch in both
modes. A single-entry `instances`
list is valid too (e.g. as a values-file template meant to scale from 1
to N) — it just renders as a plain receiver with none of the sharing
behavior described next, since there's nothing to share with.

**How the generated config stays compact with many instances:** with 2+
entries, the first instance's receiver carries the full scrape-behavior
config and is tagged with a YAML anchor (`&nrpostgresql-common`); every
entry after that is a short `<<: *nrpostgresql-common` override carrying
only its own `endpoint`/`username`/`password`/`databases` — this matches
New Relic's own documented PostgreSQL multi-receiver pattern
(https://docs.newrelic.com/docs/opentelemetry/database/postgresql/multi-receiver/#multi),
whose own example explicitly redeclares `databases` per instance after
the merge key, confirming it's meant to vary per instance rather than be
shared.

**Known limitation:** because every entry shares one pipeline and
processor, that processor's `server.address`/`server.port` resource
attributes are only correct for the *first* entry in
`postgresqlMulti.instances` — every other entry's metrics/events carry the
first entry's server/port. Same accepted tradeoff as `oracle-otel`'s
`oracleMulti` and `mysql-otel`'s `mysqlMulti` — see
`docs/superpowers/specs/2026-09-16-postgresql-otel-multi-instance-design.md`
for the full rationale.

## Values

Shared across both modes:

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `otlpEndpoint` | New Relic OTLP/gRPC endpoint, bare host:port, no scheme | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into every `nrpostgresql` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user/grant/extension Job(s) | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `psql`-capable image, shared across every Job — **required** when enabled, no default | `""` |
| `setupJob.enableExplainPermissions` | Create `otel.explain_statement` + grant `EXECUTE`, every entry in multi mode; set `false` to opt out | `true` |
| `setupJob.enablePgvector` | Also create the `vector` extension in each database, every entry in multi mode | `false` |
| `resources` / `nodeSelector` / `tolerations` / `affinity` | Standard Pod scheduling/sizing fields | `{}` / `{}` / `[]` / `{}` |

Single-instance schema (`postgresql:`, ignored when `postgresqlMulti.enabled: true`):

| Key | Description | Default |
|---|---|---|
| `postgresql.topology` | `self-hosted` or `rds` — always required | `""` |
| `postgresql.server` | PostgreSQL host/endpoint | `""` |
| `postgresql.port` | PostgreSQL port | `5432` |
| `postgresql.username` / `password` | Plain-value monitoring credentials | `""` |
| `postgresql.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `postgresql.databases` | **Required, non-empty list** of databases to monitor on this one instance | `[]` |
| `postgresql.excludeDatabases` | Databases excluded from cluster-wide scans | `[rdsadmin]` |
| `postgresql.collectionInterval` | Scrape interval | `15s` |
| `setupJob.postgresAdmin.existingSecret` | Admin Secret (keys `username`, `password`) — required if `setupJob.enabled`; superuser or `rds_superuser` | `""` |

Query-sampling/top-query events, `top_query_collection`, `query_sample_collection`, and the per-metric
`postgresql.*` enable toggles are **not** `values.yaml` fields (single- or multi-instance) — they're fixed
defaults shared by both modes (matches oracle-otel/mssql-otel's pattern). Use `additionalReceiverConfig` to
override any of them, e.g. `additionalReceiverConfig.metrics."postgresql.deadlocks".enabled=false` or
`additionalReceiverConfig.top_query_collection.explain_function_name=my_fn`.

Multi-instance schema (`postgresqlMulti:`, mutually exclusive with `postgresql.*`):

| Key | Description | Default |
|---|---|---|
| `postgresqlMulti.enabled` | Enables multi-instance mode | `false` |
| `postgresqlMulti.topology` | `self-hosted` or `rds` — kept for parity, no rendered effect | `""` |
| `postgresqlMulti.instances` | List of `{name, server, port, existingSecret, databases, postgresAdmin.existingSecret}` entries, one per monitored instance. Each entry's `databases` must be a non-empty list, same rule as `postgresql.databases` | `[]` |
