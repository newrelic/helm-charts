# nri-bundle

## Chart Details

This chart bundles multiple New Relic products helm-charts.

## Configuration

| Parameter                        | Description | Default |
| -------------------------------- | ----------- | ------- |
| `global.cluster`                 | The cluster name for the Kubernetes cluster. | |
| `global.licenseKey`              | The [license key][1] for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified. | |
| `global.insightsKey`             | The [license key][1] for your New Relic Account. This will be preferred configuration option if both `insightsKey` and `customSecret` are specified. | |
| `global.customSecretName`        | Name of the Secret object where the license key is stored | |
| `global.customSecretLicenseKey`  | Key in the Secret object where the license key is stored. | |
| `global.customSecretInsightsKey` | Key in the Secret object where the insights key is stored. | |
| `infrastructure.enabled`         | Install the [`newrelic-infrastructure` chart][3] | true |
| `prometheus.enabled`             | Install the [`nri-prometheus` chart][4] | false |
| `webhook.enabled`                | Install the [`nri-metadata-injection` chart][5] | true |
| `ksm.enabled`                    | Install the [`kube-state-metrics` chart from the stable helm charts repository][2] | false |
| `kubeEvents.enabled`             | Install the [`nri-kube-events` chart][6] | false |
| `logging.enabled`                | Install the [`newrelic-logging` chart][7] | false |

## Upgrade dependency version

Dependencies are managed using [Helm Dependency](https://helm.sh/docs/helm/helm_dependency/). In order to update any of the dependency versions you should bump the version in `requirements.yaml` and run `helm dependency update` command to update chart packages under `/charts` and also the `requirements.lock` file  

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/nri-bundle \
--set global.licenseKey=<enter_new_relic_license_key> \
--set global.cluster=my-k8s-cluster
--set infrastructure.enabled=true
--set prometheus.enabled=true
--set webhook.enabled=true
--set ksm.enabled=true
--set kubeEvents.enabled=true
--set logging.enabled=true
```

[1]: https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key
[2]: https://github.com/helm/charts/tree/master/stable/kube-state-metrics
[3]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infrastructure
[4]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-prometheus
[5]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-metadata-injection
[6]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-kube-events
[7]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging
