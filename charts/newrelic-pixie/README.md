# newrelic-pixie

## Chart Details

This chart will deploy the New Relic Pixie Integration.

IMPORTANT: this chart has to be deployed in the same namespace as Pixie. This is required because
it needs to access the cluster id inside the Pixie secrets. By default, Pixie is installed in the `pl` namespace.

## Configuration

| Parameter                     | Description                                                  | Default                    |
| ----------------------------- | ------------------------------------------------------------ | -------------------------- |
| `global.cluster` - `cluster`  | The cluster name for the Kubernetes cluster. Required.       |                            |
| `global.licenseKey` - `licenseKey` | The New Relic license key (stored in a secret). Required.    |                            |
| `apiKey`                      | The Pixie API key (stored in a secret). Required.            |                            |
| `verbose`                     | Whether the integration should run in verbose mode or not.   | false                      |
| `global.customSecretName` - `customSecretName` | Name of the Secret object where the New Relic license and Pixie API key are stored                                                                                                                                                                         |                                 |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the Secret object where the New Relic license key is stored.                                                                                                                                                             |                                 |
| `global.customSecretApiKeyKey` - `customSecretApiKeyKey` | Key in the Secret object where the Pixie API key is stored.                                                                                                                                                             |                                 |

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

## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    memory: 150M
  requests:
    cpu: 100m
    memory: 30M
```

