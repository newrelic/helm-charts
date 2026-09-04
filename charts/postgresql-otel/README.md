# postgresql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrpostgresql` receiver (currently **Preview**) to scrape one PostgreSQL
instance — one or more databases on it — and export the results to New
Relic over OTLP.

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
- Monitor more than one PostgreSQL *instance* per release — install the
  chart once per instance. (Multiple *databases* on one instance are
  supported; see `postgresql.databases`.)
- Report host/infrastructure metrics for the machine PostgreSQL runs on.
  New Relic's docs show a "Full-feature configuration" adding a
  `host_metrics` receiver and split host/db/traces pipelines — that only
  makes sense for a collector running directly on the PostgreSQL host's
  own OS. This chart implements only the standalone "Standard
  configuration" shape.

## Server-level prerequisites — do this first

PostgreSQL **14 or newer** is required. Before installing this chart (or
enabling `setupJob`), the following server parameters must be in place.
`pg_stat_statements` cannot be created at all without
`shared_preload_libraries`, and that parameter requires a **restart** —
so this cannot be automated from inside the cluster.

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

## Choosing `postgresql.topology`

| Your setup | `postgresql.topology` |
|---|---|
| Amazon RDS for PostgreSQL | `rds` |
| Self-hosted PostgreSQL (reached over the network) | `self-hosted` |

This value is always required, but does not currently change any rendered
output — it exists for documentation clarity and as a validated,
forward-compatible schema slot, the same precedent as `mssql-otel`'s and
`mysql-otel`'s `topology`.

## `databases` and `excludeDatabases`

`postgresql.databases` is a **required, non-empty list**. Unlike MySQL or
SQL Server, PostgreSQL has no "monitor every database" mode — a
connection targets one database at a time, so the receiver needs to be
told which ones to scrape:

```yaml
postgresql:
  databases:
    - appdb
    - reporting
```

`postgresql.excludeDatabases` defaults to `[rdsadmin]`. Top-query and
query-sample collection scan cluster-wide regardless of the `databases`
list, and on RDS the monitoring user can never reach `rdsadmin`, so
excluding it avoids permission errors. It's only rendered when
`postgresql.topology` is `rds` — on self-hosted PostgreSQL that database
doesn't exist, so the value is ignored there.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to
  `postgresql.server:postgresql.port` (VPN, peering, or shared network),
  DNS resolution if it's a hostname, and the PostgreSQL-side
  `pg_hba.conf`/firewall must allow the connection's actual source IP
  (which may be a NAT gateway, not the Pod IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or
  shared-VPC placement with the RDS instance, and the RDS security group
  must allow the PostgreSQL port (5432 by default) from the cluster's
  egress source.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring role and, **for every
database in `postgresql.databases`**, creates the `otel` schema, grants
the monitoring user `USAGE`/`SELECT`/`pg_monitor`, and creates the
`pg_stat_statements` extension. It uses a separate admin credential
(`setupJob.postgresAdmin.existingSecret` — **required**, no plain-value
path) which must be a superuser (self-hosted) or an
`rds_superuser`-equivalent (RDS), since it needs `CREATE USER`,
`CREATE SCHEMA`, and `CREATE EXTENSION`.

This requires a `psql`-capable image, and **this chart ships no default
one** — unlike `mysql-otel`, no free, actively-maintained
PostgreSQL-client image has been verified for this purpose yet. The
official `postgres` image bundles `psql` and is a reasonable choice:

```
--set setupJob.image.repository=postgres --set setupJob.image.tag=16
```

Two optional extras:

- `setupJob.enablePgvector: true` also runs
  `CREATE EXTENSION IF NOT EXISTS vector` in each database, for vector
  metrics (the `l1`/`hamming`/`jaccard` distance functions need pgvector
  0.7.0+).
- `setupJob.enableExplainPermissions: true` also creates the
  `otel.explain_statement` `SECURITY DEFINER` function and grants
  `EXECUTE` on it, letting the receiver run `EXPLAIN` against
  locking/write queries without holding write grants.

### You usually don't need to set `explainFunctionName`

The receiver's **own default** for `top_query_collection.
explain_function_name` is already `otel.explain_statement` — the exact
function `setupJob.enableExplainPermissions` creates. This chart omits
the key from the rendered config when
`postgresql.topQueryCollection.explainFunctionName` is empty (the
default), so the receiver's default applies and the two line up with no
extra configuration.

Set `explainFunctionName` only to point the receiver at a
**differently-named** function:

```yaml
postgresql:
  topQueryCollection:
    explainFunctionName: "myschema.my_explain_helper"
```

The receiver probes for the function's availability per database and
re-checks periodically (the receiver's own default caching behavior;
this chart doesn't expose a value to override it), falling back to
inline `EXPLAIN` when it isn't there — so leaving
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
superuser. Cluster-level, once:

```sql
CREATE USER nr_monitor WITH LOGIN PASSWORD '<password>';
ALTER ROLE nr_monitor INHERIT;   -- required on PG15+, a no-op on PG14
```

Then in **every** database you listed in `postgresql.databases`:

```sql
CREATE SCHEMA IF NOT EXISTS otel;
GRANT USAGE ON SCHEMA otel TO nr_monitor;
GRANT USAGE ON SCHEMA public TO nr_monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO nr_monitor;
GRANT pg_monitor TO nr_monitor;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## Values

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `postgresql.topology` | `self-hosted` or `rds` — always required | `""` |
| `postgresql.server` | PostgreSQL host/endpoint | `""` |
| `postgresql.port` | PostgreSQL port | `5432` |
| `postgresql.username` / `password` | Plain-value monitoring credentials | `""` |
| `postgresql.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `postgresql.databases` | **Required, non-empty list** of databases to monitor | `[]` |
| `postgresql.excludeDatabases` | Databases excluded from cluster-wide scans | `[rdsadmin]` |
| `postgresql.collectionInterval` | Scrape interval | `15s` |
| `postgresql.events.querySample.enabled` / `topQuery.enabled` | Enable the query-sample/top-query log events | `true` / `true` |
| `postgresql.topQueryCollection.maxRowsPerQuery` | | `1000` |
| `postgresql.topQueryCollection.topNQuery` | | `200` |
| `postgresql.topQueryCollection.collectionInterval` | | `60s` |
| `postgresql.topQueryCollection.allowedCommentKeys` | | `[nr_service_guid]` |
| `postgresql.topQueryCollection.explainFunctionName` | `SECURITY DEFINER` helper the receiver calls to EXPLAIN write/locking queries. Empty omits the key, so the receiver's own default (`otel.explain_statement`) applies | `""` |
| `postgresql.querySampleCollection.maxRowsPerQuery` | | `1000` |
| `postgresql.querySampleCollection.allowedCommentKeys` | | `[nr_service_guid]` |
| `postgresql.metrics.databaseLocks.enabled` | `postgresql.database.locks` | `true` |
| `postgresql.metrics.deadlocks.enabled` | `postgresql.deadlocks` | `true` |
| `postgresql.metrics.functionCalls.enabled` | `postgresql.function.calls` | `true` |
| `postgresql.metrics.queryConflicts.enabled` | `postgresql.query.conflicts` | `true` |
| `postgresql.metrics.sequentialScans.enabled` | `postgresql.sequential_scans` | `true` |
| `postgresql.metrics.tempIo.enabled` | `postgresql.temp.io` | `true` |
| `postgresql.metrics.tempFiles.enabled` | `postgresql.temp_files` | `true` |
| `otlpEndpoint` | New Relic OTLP/gRPC endpoint, **bare host:port, no scheme** (e.g. `otlp.nr-data.net:4317`) — validated at render time, since the gRPC `otlp` exporter rejects a URL, unlike `mssql-otel`'s `otlphttp` | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into the `nrpostgresql` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user/grant/extension Job | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `psql`-capable image — **required** when enabled, no default | `""` |
| `setupJob.postgresAdmin.existingSecret` | Admin Secret (keys `username`, `password`) — required when enabled; superuser or `rds_superuser` | `""` |
| `setupJob.enableExplainPermissions` | Also create `otel.explain_statement` + grant `EXECUTE` | `false` |
| `setupJob.enablePgvector` | Also create the `vector` extension in each database | `false` |
