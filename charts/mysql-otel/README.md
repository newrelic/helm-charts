# mysql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrmysql` receiver to scrape one MySQL instance and export the results to
New Relic over OTLP.

## What this chart does not do

- Monitor more than one MySQL instance per release — install the chart
  once per database.
- Support Unix-socket monitoring (`transport: unix`). The `nrmysql`
  receiver supports connecting via a local socket file, but that only
  makes sense when the collector runs on the same host/filesystem as
  MySQL. This chart runs the collector as a Kubernetes Deployment reaching
  MySQL remotely over the network, so `transport` is always `tcp` and is
  not exposed as a value at all.
- Report host/infrastructure metrics for the machine MySQL runs on. New
  Relic's docs show a "Full-feature configuration" that adds a
  `host_metrics` receiver and split host/db/traces pipelines — that only
  makes sense for a collector running directly on the MySQL host's own OS.
  This chart implements only the standalone "Standard configuration" shape.
- Auto-select an Amazon RDS CA bundle for you. `mysql.tls.caFile` is a
  plain value you supply — a chart-hardcoded default risks going stale as
  Amazon rotates CA bundles.

## Choosing `mysql.topology`

| Your setup | `mysql.topology` |
|---|---|
| Amazon RDS for MySQL | `rds` |
| Self-hosted MySQL (reached over the network) | `self-hosted` |

This value is always required, but does not currently change any rendered
output — it exists for documentation clarity and as a validated,
forward-compatible schema slot, same precedent as `mssql-otel`'s
`mssql.topology`.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to
  `mysql.server:mysql.port` (VPN, peering, or shared network), DNS
  resolution if it's a hostname, and the MySQL-side firewall must allow the
  connection's actual source IP (which may be a NAT gateway, not the Pod IP
  itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or shared-VPC
  placement with the RDS instance, and the RDS security group must allow
  the MySQL port (3306 by default) from the cluster's egress source.

## TLS

Set `mysql.tls.insecure: false` (the default) to require an encrypted
connection, `mysql.tls.insecureSkipVerify: true` to skip certificate
validation (useful for self-signed certs in test environments, but weakens
the connection's security guarantees), and `mysql.tls.caFile` to a CA
bundle path mounted into the collector container if the MySQL server's
certificate isn't in the default trust store — for example, an **Amazon
RDS instance with "Require SSL/TLS" enforcement needs `caFile` pointed at
Amazon's RDS CA bundle**. Confirm these flags' actual behavior against a
real MySQL instance requiring TLS before relying on this in production —
see `TESTING.md`.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring user
(`mysql.username`/`mysql.existingSecret`) and grants it `SELECT` on
`performance_schema.*`, using a separate admin credential
(`setupJob.mysqlAdmin.existingSecret` — **required**, no plain-value path,
since it can `CREATE USER` and grant broad `performance_schema` access).
Set `setupJob.enableWaitTimeMetrics: true` to also grant `UPDATE` on
`performance_schema.setup_consumers`, needed for wait-time data — this is
optional per New Relic's docs.

This requires a `mysql`-CLI-capable image. Unlike the other two charts in
this family, `setupJob.image` defaults to the official, actively-maintained
`mysql:8.4` image — no license click-through required, so enabling the
setup Job needs no extra `--set` flags for the image. Override
`setupJob.image.repository`/`tag` if you need a different version.

**Known limitation:** the setup Job builds its `CREATE USER`/`GRANT`
statements by shell-expanding the monitoring credentials directly into a
SQL heredoc. This is not injection-safe against an adversarial password (a
password containing `'` could break out of the quoted SQL string) — the
same trust model as this chart family's other setup Jobs. Credentials are
expected to come from the same operator running the install, not
attacker-controlled input.

If you'd rather not grant this chart admin-level MySQL access at all,
leave `setupJob.enabled: false` and create the monitoring user yourself
before installing:
```sql
CREATE USER IF NOT EXISTS 'nr_monitor'@'%' IDENTIFIED BY '<password>';
GRANT SELECT ON performance_schema.* TO 'nr_monitor'@'%';
FLUSH PRIVILEGES;
```

## Testing

See [`TESTING.md`](./TESTING.md) for a full local/EC2 setup and end-to-end
validation runbook, including a disposable MySQL instance for testing
without touching production.

## Values

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
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
| `otlpEndpoint` | New Relic OTLP/gRPC endpoint, bare host:port, no scheme | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into the `nrmysql` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user-creation Job | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `mysql`-CLI image | `mysql` / `8.4` |
| `setupJob.mysqlAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if enabled | `""` |
| `setupJob.enableWaitTimeMetrics` | Also grant `UPDATE` on `performance_schema.setup_consumers` | `false` |
