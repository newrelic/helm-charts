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

## Choosing `oracle.topology`

| Your setup | `oracle.topology` |
|---|---|
| Amazon RDS for Oracle | `rds` |
| Self-hosted, multitenant (you connect to the container database) | `cdb` |
| Self-hosted, single pluggable database only | `pdb` |

This value is only required when `setupJob.enabled: true` — it selects which
grant script the setup Job runs, since RDS, CDB, and PDB each require a
different user-creation and permission-granting procedure. It also determines
whether the monitoring username must carry a `C##` prefix (CDB only, enforced
by Oracle itself) and which metrics are disabled by default (RDS hides a few
that are always empty there).

## Networking prerequisites

- **Self-hosted**: the collector Pod needs a routed path to `oracle.endpoint`
  (VPN, peering, or shared network), DNS resolution if it's a hostname, and
  the Oracle-side firewall must allow the connection's actual source IP
  (which may be a NAT gateway, not the Pod IP itself).
- **RDS**: your cluster needs VPC peering, a transit gateway, or shared-VPC
  placement with the RDS instance, and the RDS security group must allow the
  Oracle port from the cluster's egress source.

## Automated setup (`setupJob.enabled: true`)

If enabled, a Helm hook Job creates the monitoring user (`oracle.username`/
`oracle.existingSecret`) and grants it read access, using a separate admin
credential (`setupJob.oracleAdmin.existingSecret` — **required**, no
plain-value path, since it can create users and grant broad access).

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
| `oracle.topology` | `cdb`, `pdb`, or `rds` — required if `setupJob.enabled` | `""` |
| `oracle.endpoint` | Oracle listener `host:port` | `""` |
| `oracle.service` | CDB/PDB service name, or RDS DB name | `""` |
| `oracle.username` / `oracle.password` | Plain-value monitoring credentials | `""` |
| `oracle.existingSecret` | Pre-existing Secret (keys `username`, `password`), wins over plain values | `""` |
| `oracle.collectionInterval` | Scrape interval | `10s` |
| `otlpEndpoint` | New Relic OTLP endpoint for your account's region | `""` |
| `licenseKey` / `customSecretName` / `customSecretLicenseKey` | New Relic license key, standard `common-library` fields | `""` |
| `additionalReceiverConfig` | Merged into the `nroracledb` receiver block | `{}` |
| `setupJob.enabled` | Run the automated user-creation Job | `false` |
| `setupJob.image.repository` / `setupJob.image.tag` | Oracle Instant Client image | `""` |
| `setupJob.oracleAdmin.existingSecret` | Admin credential Secret (keys `username`, `password`) — required if enabled | `""` |
