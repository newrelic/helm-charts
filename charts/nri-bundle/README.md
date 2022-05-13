# nri-bundle

![Version: 4.4.6](https://img.shields.io/badge/Version-4.4.6-informational?style=flat-square)

A chart groups together the individual charts for the New Relic Kubernetes solution for more comfortable deployment.

**Homepage:** <https://github.com/newrelic/helm-charts>

## Configure components

It is possible to configure settings for the individual charts this chart groups by specifying values for them under a key using the name of the chart,
as specified in [helm documentation](https://helm.sh/docs/chart_template_guide/subcharts_and_globals).

For example, by adding the following to the `values.yml` file:

```yaml
# Configuration settings for the newrelic-infrastructure chart
newrelic-infrastructure:
  # Any key defined in the values.yml file for the newrelic-infrastructure chart can be configured here:
  # https://github.com/newrelic/nri-kubernetes/blob/master/charts/newrelic-infrastructure/values.yaml

  verboseLog: false

  resources:
    limits:
      memory: 512M
```

It is possible to override any entry of the [`newrelic-infrastructure`](https://github.com/newrelic/nri-kubernetes/tree/master/charts/newrelic-infrastructure)
chart, as defined in their [`values.yml` file](https://github.com/newrelic/nri-kubernetes/blob/master/charts/newrelic-infrastructure/values.yaml).

The same approach can be followed to update any of the subcharts.

After making these changes to the `values.yml` file, or a custom values file, make sure to apply them using:

```
$ helm upgrade --reuse-values -f values.yaml [RELEASE] newrelic/nri-bundle
```

Where `[RELEASE]` is the name of the helm release, e.g. `newrelic-bundle`.

## Monitor on host integrations

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
  nri-redis-sampleapp:
    discovery:
      command:
        exec: /var/db/newrelic-infra/nri-discovery-kubernetes --tls --port 10250
        match:
          label.app: sampleapp
    integrations:
      - name: nri-redis
        env:
          # using the discovered IP as the hostname address
          HOSTNAME: ${discovery.ip}
          PORT: 6379
        labels:
          env: test
```

## Values managed globally

Some of the subchart implement the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations`, `proxy` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

At the time of writing this document, all the charts from `nri-bundle` except `newrelic-logging` and `synthetics-minion` implements this library and
honors global options as described below.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global | object | See [`values.yaml`](values.yaml) | change the behaviour globally to all the supported helm charts. See [user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md) for further information. |
| global.affinity | object | `{}` | Sets pod/node affinities |
| global.cluster | string | `""` | The cluster name for the Kubernetes cluster. |
| global.containerSecurityContext | object | `{}` | Sets security context (at container level) |
| global.customAttributes | object | `{}` | Adds extra attributes to the cluster and all the metrics emitted to the backend |
| global.customSecretLicenseKey | string | `""` | Key in the Secret object where the license key is stored |
| global.customSecretName | string | `""` | Name of the Secret object where the license key is stored |
| global.dnsConfig | object | `{}` | Sets pod's dnsConfig |
| global.fargate | bool | false | Must be set to `true` when deploying in an EKS Fargate environment |
| global.hostNetwork | bool | false | Sets pod's hostNetwork |
| global.images.pullSecrets | list | `[]` | Set secrets to be able to fetch images |
| global.images.registry | string | `""` | Changes the registry where to get the images. Useful when there is an internal image cache/proxy |
| global.insightsKey | string | `""` | The license key for your New Relic Account. This will be preferred configuration option if both `insightsKey` and `customSecret` are specified. |
| global.labels | object | `{}` | Additional labels for chart objects |
| global.licenseKey | string | `""` | The license key for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified. |
| global.lowDataMode | bool | false | Reduces number of metrics sent in order to reduce costs |
| global.nodeSelector | object | `{}` | Sets pod's node selector |
| global.nrStaging | bool | false | Send the metrics to the staging backend. Requires a valid staging license key |
| global.podLabels | object | `{}` | Additional labels for chart pods |
| global.podSecurityContext | object | `{}` | Sets security context (at pod level) |
| global.priorityClassName | string | `""` | Sets pod's priorityClassName |
| global.privileged | bool | false | In each integration it has different behavior. See [Further information](#values-managed-globally-3) but all aims to send less metrics to the backend to try to save costs | |
| global.proxy | string | `""` | Configures the integration to send all HTTP/HTTPS request through the proxy in that URL. The URL should have a standard format like `https://user:password@hostname:port` |
| global.serviceAccount.annotations | object | `{}` | Add these annotations to the service account we create |
| global.serviceAccount.create | string | `nil` | Configures if the service account should be created or not |
| global.serviceAccount.name | string | `nil` | Change the name of the service account. This is honored if you disable on this chart the creation of the service account so you can use your own |
| global.tolerations | list | `[]` | Sets pod's tolerations to node taints |
| global.verboseLog | bool | false | Sets the debug logs to this integration or all integrations if it is set globally |
| infrastructure.enabled | bool | `true` | Install the [`newrelic-infrastructure` chart](https://github.com/newrelic/nri-kubernetes/tree/main/charts/newrelic-infrastructure) |
| ksm.enabled | bool | `false` | Install the [`kube-state-metrics` chart from the stable helm charts repository](https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics) This is mandatory if `infrastructure.enabled` is set to `true` and the user does not provide its own instance of KSM version >=1.8 and <=2.0 |
| kubeEvents.enabled | bool | `false` | Install the [`nri-kube-events` chart](https://github.com/newrelic/nri-kube-events/tree/main/charts/nri-kube-events) |
| logging.enabled | bool | `false` | Install the [`newrelic-logging` chart](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging) |
| metrics-adapter.enabled | bool | `false` | Install the [`newrelic-k8s-metrics-adapter.` chart](https://github.com/newrelic/newrelic-k8s-metrics-adapter/tree/main/charts/newrelic-k8s-metrics-adapter) (Beta) |
| newrelic-infra-operator.enabled | bool | `false` | Install the [`newrelic-infra-operator` chart](https://github.com/newrelic/newrelic-infra-operator/tree/main/charts/newrelic-infra-operator) (Beta) |
| newrelic-pixie.enabled | bool | `false` | Install the [`newrelic-pixie`](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-pixie) |
| pixie-chart.enabled | bool | `false` | Install the [`pixie-chart` chart](https://docs.pixielabs.ai/installing-pixie/install-schemes/helm/#3.-deploy) |
| prometheus.enabled | bool | `false` | Install the [`nri-prometheus` chart](https://github.com/newrelic/nri-prometheus/tree/main/charts/nri-prometheus) |
| webhook.enabled | bool | `true` | Install the [`nri-metadata-injection` chart](https://github.com/newrelic/k8s-metadata-injection/tree/main/charts/nri-metadata-injection) |

## Maintainers

* [alvarocabanas](https://github.com/alvarocabanas)
* [carlossscastro](https://github.com/carlossscastro)
* [sigilioso](https://github.com/sigilioso)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [kang-makes](https://github.com/kang-makes)
* [marcsanmi](https://github.com/marcsanmi)
* [paologallinaharbur](https://github.com/paologallinaharbur)
* [roobre](https://github.com/roobre)
