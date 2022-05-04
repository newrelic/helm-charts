# nri-bundle

## Chart Details

This chart groups together the individual charts for the New Relic Kubernetes solution for more comfortable deployment.

## Configuration

The following properties can be configured in the `values.yml` file:

| Parameter                         | Description                                                                                                                                          | Default |
|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `global.cluster`                  | The cluster name for the Kubernetes cluster.                                                                                                         |         |
| `global.licenseKey`               | The [license key][1] for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified.  |         |
| `global.insightsKey`              | The [license key][1] for your New Relic Account. This will be preferred configuration option if both `insightsKey` and `customSecret` are specified. |         |
| `global.customSecretName`         | Name of the Secret object where the license key is stored                                                                                            |         |
| `global.customSecretLicenseKey`   | Key in the Secret object where the license key is stored.                                                                                            |         |
| `global.customSecretInsightsKey`  | Key in the Secret object where the insights key is stored.                                                                                           |         |
| `global.lowDataMode`              | Enable Low Data mode: apply more sampling on Pixie data, send minimal attributes on Logs and filter KSM metrics from Prometheus.                     | false   |
| `global.fargate`                  | Must be set to `true` when deploying in an EKS Fargate environment.                                                                                  | false   |
| `infrastructure.enabled`          | Install the [`newrelic-infrastructure` chart][3]                                                                                                     | true    |
| `prometheus.enabled`              | Install the [`nri-prometheus` chart][4]                                                                                                              | false   |
| `webhook.enabled`                 | Install the [`nri-metadata-injection` chart][5]                                                                                                      | true    |
| `ksm.enabled`                     | Install the [`kube-state-metrics` chart from the stable helm charts repository][2]                                                                   | false   |
| `kubeEvents.enabled`              | Install the [`nri-kube-events` chart][6]                                                                                                             | false   |
| `logging.enabled`                 | Install the [`newrelic-logging` chart][7]                                                                                                            | false   |
| `newrelic-pixie.enabled`          | Install the [`newrelic-pixie`][8] chart                                                                                                              | false   |
| `pixie-chart.enabled`             | Install the [`pixie-chart` chart][9]                                                                                                                 | false   |
| `newrelic-infra-operator.enabled` | Install the [`newrelic-infra-operator` chart][10] (Beta)                                                                                             | false   |
| `metrics-adapter.enabled`         | Install the [`newrelic-k8s-metrics-adapter.` chart][11] (Beta)                                                                                             | false   |

## Configure components

It is possible to configure settings for the individual charts this chart groups by specifying values for them under a key using the name of the chart, as specified in [helm documentation](https://helm.sh/docs/chart_template_guide/subcharts_and_globals).

For example, by adding the following to the `values.yml` file:

```yaml
# Configuration settings for the newrelic-infrastructure chart
newrelic-infrastructure:
  # Any key defined in the values.yml file for the newrelic-infrastructure chart can be configured here:
  # https://github.com/newrelic/helm-charts/blob/master/charts/newrelic-infrastructure/values.yaml

  verboseLog: false

  resources:
    limits:
      memory: 512M

  daemonSet:
    annotations:
      example.org/annotation: value
```

It is possible to override the `verboseLog`, `resources`, or `daemonSet` entries of the [`newrelic-infrastructure`](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infrastructure) chart, as defined in their [`values.yml` file](https://github.com/newrelic/helm-charts/blob/master/charts/newrelic-infrastructure/values.yaml).

As another example, the following snippet allows specifying config options for the infrastructure-agent, which again is part of the `newrelic-infrastructure` chart:

```yaml
newrelic-infrastructure:
  # Enable verbose logging
  verboseLog: true

  # Configure advanced options for the infrastructure-agent itself
  config:
    # Set up a proxy
    proxy: https://user:password@hostname:port
    # Log sent data to stderr
    trace:
      - connect
```

Everything under the `config` key will be mapped to the agent config file. For more details about which configuration options can be set for the New Relic Infrastructure Agent, please check [our documentation](https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/).

The same approach can be followed to update any of the subcharts.

After making this changes to the `values.yml` file, or a custom values file, make sure to apply them using:

```
$ helm upgrade --reuse-values -f values.yaml [RELEASE] newrelic/nri-bundle
```

Where `[RELEASE]` is the name of the helm release, e.g. `newrelic-bundle`.

### Monitor on host integrations

If you wish to monitor services running on Kubernetes you can provide integrations
configuration under `integrations_config` that it will passed down to the `newrelic-infrastructure` chart.

You just need to create a new entry where the "name" is the filename of the configuration file and the data is the content of
the integration configuration. The name must end in ".yaml" as this will be the
filename generated and the Infrastructure agent only looks for YAML files. 

The data part is the actual integration configuration as described in the spec here:
https://docs.newrelic.com/docs/integrations/integrations-sdk/file-specifications/integration-configuration-file-specifications-agent-v180

In the following example you can see how to monitor a Redis integration with autodiscovery

```yaml
newrelic-infrastructure:
  integrations_config:
    - name: nri-redis.yaml
      data:
        discovery:
          command:
            # Run NRI Discovery for Kubernetes
            # https://github.com/newrelic/nri-discovery-kubernetes
            exec: /var/db/newrelic-infra/nri-discovery-kubernetes
            match:
              label.app: redis
        integrations:
          - name: nri-redis
            env:
              # using the discovered IP as the hostname address
              HOSTNAME: ${discovery.ip}
              PORT: 6379
            labels:
              env: test
```
## Upgrade dependency version

Dependencies are managed using [Helm Dependency](https://helm.sh/docs/helm/helm_dependency/). 
In order to update any of the dependency versions you should bump the version in `requirements.yaml` and run `helm dependency update` 
command to update chart packages under `/charts` and also the `requirements.lock` file.

ATTENTION: do not commit the internal dependencies. We only commit *kube-state-metrics* and `pixie-chart` because we 
don't own their distribution but would like to be resilient to failures of their repository.

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/nri-bundle \
--set global.licenseKey=<New Relic License key> \
--set global.cluster=<Cluster name> \
--set infrastructure.enabled=true \
--set prometheus.enabled=true \
--set webhook.enabled=true \
--set ksm.enabled=true \
--set kubeEvents.enabled=true \
--set logging.enabled=true \
--generate-name
```

### Example with Pixie

```sh
helm install newrelic/nri-bundle \
--set global.licenseKey=<New Relic License key> \
--set global.cluster=<Cluster name> \
--set infrastructure.enabled=true \
--set prometheus.enabled=true \
--set webhook.enabled=true \
--set ksm.enabled=true \
--set kubeEvents.enabled=true \
--set logging.enabled=true \
--set newrelic-pixie.enabled=true \
--set newrelic-pixie.apiKey=<Pixie API key> \
--set pixie-chart.enabled=true \
--set pixie-chart.deployKey=<Pixie Deploy key> \
--set pixie-chart.clusterName=<Cluster name> \ 
--generate-name
```

[1]: https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key
[2]: https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics
[3]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infrastructure
[4]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-prometheus
[5]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-metadata-injection
[6]: https://github.com/newrelic/helm-charts/tree/master/charts/nri-kube-events
[7]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging
[8]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-pixie
[9]: https://docs.pixielabs.ai/installing-pixie/install-schemes/helm/#3.-deploy
[10]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infra-operator
[11]: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-k8s-metrics-adapter
