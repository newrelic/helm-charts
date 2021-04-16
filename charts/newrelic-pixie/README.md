# newrelic-pixie

## Chart Details

This chart will deploy the New Relic Pixie Integration.

## Configuration

| Parameter                     | Description                                                  | Default                    |
| ----------------------------- | ------------------------------------------------------------ | -------------------------- |
| `cluster`                     | The cluster name for the Kubernetes cluster.                 |                            |`                                |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-pixie --set cluster=my_cluster_name
```
