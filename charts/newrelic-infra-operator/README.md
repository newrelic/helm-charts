# newrelic-infra-operator

## Chart Details

This chart will deploy the [New Relic Infrastructure Operator][1], which injects the New Relic Infrastructure solution as a sidecar to specific pods. This is typically used in environments where DaemonSets are not available, such as EKS Fargate.

## Configuration

| Parameter                     | Description                                                  | Default                    |
| ----------------------------- | ------------------------------------------------------------ | -------------------------- |
| `cluster`                     | The cluster name for the Kubernetes cluster.                 |                            |

> TBD

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm upgrade --install newrelic/newrelic-infra-operator --set cluster=my_cluster_name
```

## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    memory: 80M
  requests:
    cpu: 100m
    memory: 30M
```

[1]: https://github.com/newrelic/newrelic-infra-operator
[2]: https://cert-manager.io/
