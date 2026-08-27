# mssql-otel

Deploys New Relic's NRDOT OpenTelemetry collector configured with the
`nrsqlserver` receiver (currently **Preview**) to scrape one Microsoft SQL
Server instance and export the results to New Relic over OTLP.

## What this chart does not do

- Monitor more than one SQL Server instance per release — install the chart
  once per database.
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
- Report host/infrastructure metrics for the machine SQL Server runs on.
  New Relic's docs show a "Full-feature configuration" that adds
  `hostmetrics`/`filelog`/`otlp` receivers and a `resourcedetection`
  processor chain — that only makes sense for a collector running directly
  on the SQL Server's own host OS. This chart runs the collector as a
  Kubernetes Deployment reaching SQL Server remotely, so it implements only
  the standalone "Standard configuration" shape.

## Choosing `mssql.topology`

| Your setup | `mssql.topology` |
|---|---|
| Amazon RDS for SQL Server | `rds` |
| Self-hosted SQL Server (Linux or Windows, reached over the network) | `self-hosted` |

This value is always required, but — unlike `oracle-otel`'s `oracle.topology`
— it does not currently change any rendered output. The grant script and
receiver defaults are identical for `self-hosted` and `rds` (the grant
script's system-database exclusion list always excludes `rdsadmin`, which is
a harmless no-op on self-hosted instances where that database simply
doesn't exist). It's validated and required anyway, for documentation
clarity and to leave room for a future difference without a breaking change.

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to
  `mssql.server:mssql.port` (VPN, peering, or shared network), DNS
  resolution if it's a hostname, and the SQL Server-side firewall must allow
  the connection's actual source IP (which may be a NAT gateway, not the Pod
  IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or shared-VPC
  placement with the RDS instance, and the RDS security group must allow the
  SQL Server port (1433 by default) from the cluster's egress source.

## TLS

The `nrsqlserver` receiver has no discrete TLS fields — despite what New
Relic's docs show, `ct install` confirmed the real receiver schema rejects
`enable_ssl`/`trust_server_certificate` outright. TLS is only configurable
via the receiver's `datasource` connection string, so this chart always
connects that way and sets the string's `encrypt`/`trustservercertificate`
DSN parameters (from the underlying `go-mssqldb` driver) from
`mssql.tls.enabled`/`mssql.tls.trustServerCertificate`.

Set `mssql.tls.enabled: true` to encrypt the connection, and
`mssql.tls.trustServerCertificate: true` to skip certificate validation —
useful for self-signed certs in test environments, but weakens the
connection's security guarantees. This has been confirmed to render a
schema-valid `datasource` string via `ct install`; the actual TLS handshake
behavior against a real SQL Server instance requiring encryption is still
unverified — see `TESTING.md`.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring login
(`mssql.username`/`mssql.existingSecret`) and grants it read-only access
(`VIEW SERVER STATE`, `VIEW ANY DEFINITION`, `VIEW ANY DATABASE`, and
per-database `VIEW DATABASE STATE`), using a separate admin credential
(`setupJob.sqlAdmin.existingSecret` — **required**, no plain-value path,
since it can create logins and grant broad `VIEW` access). This admin
credential must be able to run `CREATE LOGIN` and server-level `GRANT`
statements — a `sysadmin`-role login (e.g. `sa`, or an RDS master user).

This requires a `sqlcmd`-capable image. Unlike Oracle's Instant Client,
Microsoft does publish a freely, anonymously pullable image with `sqlcmd`
at `mcr.microsoft.com/mssql-tools:latest` — no license click-through
required. However, that image is dated **2017** and appears unmaintained
(classic ODBC-based `sqlcmd`, not the current `mssql-tools18`/go-sqlcmd).
**Confirm you're comfortable with that image's age (including any
unpatched CVEs) before using it, or build a current image yourself from
Microsoft's `mssql-tools18` apt packages** — this README intentionally does
not default `setupJob.image.repository`/`tag` to it, since a chart default
shouldn't silently commit users to a stale base image.

If you'd rather not grant this chart admin-level SQL Server access at all,
leave `setupJob.enabled: false` and run `files/setup/grants.sql` yourself,
as a `sysadmin`, before installing.

## Testing

See [`TESTING.md`](./TESTING.md) for a full local/EC2 setup and end-to-end
validation runbook, including a disposable SQL Server instance for testing
without touching production.

## Values

| Key | Description | Default |
|---|---|---|
| `image.repository` | Collector image | `newrelic/nrdot-collector` |
| `image.tag` | Collector image tag | `2.4.0` |
| `mssql.topology` | `self-hosted` or `rds` — always required | `""` |
| `mssql.server` | SQL Server host/endpoint | `""` |
| `mssql.port` | SQL Server port | `1433` |
| `mssql.username` / `mssql.password` | Plain-value monitoring credentials | `""` |
| `mssql.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `mssql.collectionInterval` | Scrape interval | `15s` |
| `mssql.maxConcurrentQueries` | Max concurrent scrape queries | `4` |
| `mssql.tls.enabled` | Encrypt the connection to SQL Server | `false` |
| `mssql.tls.trustServerCertificate` | Skip SQL Server TLS certificate validation | `false` |
| `otlpEndpoint` | New Relic OTLP endpoint for your account's region | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into the `nrsqlserver` receiver block | `{}` |
| `setupJob.enabled` | Run the automated login-creation Job | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | `sqlcmd`-capable image | `""` |
| `setupJob.sqlAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if enabled | `""` |
