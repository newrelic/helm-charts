# newrelic-pixie

## Chart Details

This chart will deploy the New Relic Pixie Integration.

IMPORTANT: make sure you deploy this chart in the same namespace as Pixie.
It needs to access the cluster id inside the Pixie secrets.
By default, Pixie is installed in the `pl` namespace.

## Configuration

| Parameter                                                  | Description                                                                                                                                                                                        | Default               |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster. Required.                                                                                                                                             |                       |
| `global.licenseKey` - `licenseKey`                         | The New Relic license key (stored in a secret). Required.                                                                                                                                          |                       |
| `global.lowDataMode` - `lowDataMode`                       | If `true`, the integration performs heavier sampling on the Pixie span data and sets the collect interval to 15 seconds instead of 10 seconds.                                                     | false                 |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key).                                                                                                                                             | false                 |
| `apiKey`                                                   | The Pixie API key (stored in a secret). Required.                                                                                                                                                  |                       |
| `verbose`                                                  | Whether the integration should run in verbose mode or not.                                                                                                                                         | false                 |
| `global.customSecretName` - `customSecretName`             | Name of an existing Secret object, not created by this chart, where the New Relic license is stored                                                                                                |                       |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the existing Secret object, indicated by `customSecretName`, where the New Relic license key is stored.                                                                                     |                       |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                | `nil`                 |
| `customSecretApiKeyName`                                   | Name of an existing Secret object, not created by this chart, where the Pixie API key is stored.                                                                                                   |                       |
| `customSecretApiKeyKey`                                    | Key in the existing Secret object, indicated by `customSecretApiKeyName`, where the Pixie API key is stored.                                                                                       |                       |
| `nodeSelector`                                             | Node label to use for scheduling                                                                                                                                                                                                      | `{}`                                   |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                          | `[]`                                   |
| `affinity`                                                 | Node affinity to use for scheduling                                                                                                                                                                                            | `{}`                  |
| `proxy`                                                    | Set proxy to connect to Pixie Cloud and New Relic.                                                                                                                                                 |                       |
| `excludeNamespacesRegex`                                   | Observability data for namespaces matching this RE2 regex is not sent to New Relic. If empty, observability data for all namespaces is sent to New Relic.                                          |                       |
| `excludePodsRegex`                                         | Observability data for pods (across all namespaces) matching this RE2 regex is not sent to New Relic. If empty, observability data for all pods (in non-excluded namespaces) is sent to New Relic. |                       |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-pixie \
  --set cluster=<Kubernetes cluster name> \
  --set licenseKey=<Your New Relic license key> \
  --set apiKey=<Your Pixie API key> \ 
  --namespace pl \
  --generate-name
```

## Globals

**Important:** global parameters have higher precedence than locals with the same name.

These are meant to be used when you are writing a chart with subcharts. It helps to avoid
setting values multiple times on different subcharts.

More information on globals and subcharts can be found at [Helm's official documentation](https://helm.sh/docs/topics/chart_template_guide/subcharts_and_globals/).

| Parameter                       |
| ------------------------------- |
| `global.cluster`                |
| `global.licenseKey`             |
| `global.customSecretName`       |
| `global.customSecretLicenseKey` |
| `global.lowDataMode`            |
| `global.nrStaging`              |

## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    memory: 250M
  requests:
    cpu: 100m
    memory: 250M
```

