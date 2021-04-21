# newrelic-pixie

## Chart Details

This chart will deploy the New Relic Pixie Integration.

Note: the namespace is hardcoded to be `pl`, matching the namespace used by the Pixie chart. This is required because
we need access to the cluster id inside the Pixie secrets.

## Configuration

| Parameter                     | Description                                                  | Default                    |
| ----------------------------- | ------------------------------------------------------------ | -------------------------- |
| `cluster`                     | The cluster name for the Kubernetes cluster.                 |                            |
| `licenseKey`                  | The New Relic license key (stored in a secret)               |                            |
| `apiKey`                      | The Pixie API key  (stored in a secret)                      |                            |
| `verbose`                     | Whether the integration should run in verbose mode or not    | false                      |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-pixie \
  --set cluster=<Kubernetes cluster name> \
  --set licenseKey=<Your New Relic license key> \
  --set apiKey=<Your Pixie API key>
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

