# otel-k8s-prometheus

## Chart Details

This chart deploys the [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector-contrib)
preconfigured to scrape prometheus endpoints from a Kubernetes cluster.

Reasonable flexibility is offered to add extra processors, and change the labels or annotations that are used to
identify prometheus endpoints, filter metrics, etc.

## Configuration

Most relevant values for the chart are listed below. For a complete list, please check the `values.yml` file.

| Parameter                                                                       | Description                                                                                                                                                                                                                                                                                                                                 | Default                                                                                              |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `global.cluster` - `cluster` | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                                                                                                                |                                                                                                      |
| `global.licenseKey` - `licenseKey` | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified.                                                                                                       |                                                                                                      |
| `global.customSecretName` - `customSecretName` | Instead of creating a secret with the License Key above, read it from this externally created one |  |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key holding the License Key in the secret defined above |  |
| `config.labels` | List of labels used to identify pods or services that export prometheus metrics | `prometheus.io/scrape` |
| `config.annotations` | List of annotations used to identify pods or services that export prometheus metrics | `prometheus.io/scrape` |
| `config.interval` | Interval at which metrics will be scraped and pushed | `30s` |
| `config.jobs.podsEndpoints.enabled` | Whether to scrape annotated pods and endpoints behind annotated services. | `true` |
| `config.jobs.headless.enabled` | Whether to scrape annotated headless services. | `true` |
| `config.extraScrapeConfigs` | List of [Prometheus server `scrape_config`s](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config) to add to the two jobs above. | `[]` |
| `config.extraProcessors` | Additional [otelcol processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor) to use in the pipeline. | `{}` |
| `config.otlpExporter` | Config for the OTLP exporter. |  |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#install)

Then, to install this chart, run the following command:

```sh
helm upgrade --install [release-name] newrelic/otel-k8s-prometheus --set cluster=my_cluster_name --set licenseKey=[your-license-key]
```
