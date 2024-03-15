# nri-bundle

Groups together the individual charts for the New Relic Kubernetes solution for a more comfortable deployment.

**Homepage:** <https://github.com/newrelic/helm-charts>

## Bundled charts

This chart does not deploy anything by itself but has many charts as dependencies. This allows you to easily install and upgrade the New Relic
Kubernetes Integration using only one chart.

In case you need more information about each component this chart installs, or you are an advanced user that want to install each component separately,
here is a list of components that this chart installs and where you can find more information about them:

| Component                    | Installed by default? | Description |
|------------------------------|-----------------------|-------------|
| [newrelic-infrastructure](https://github.com/newrelic/nri-kubernetes/tree/main/charts/newrelic-infrastructure) | Yes | Sends metrics about nodes, cluster objects (e.g. Deployments, Pods), and the control plane to New Relic. |
| [nri-metadata-injection](https://github.com/newrelic/k8s-metadata-injection/tree/main/charts/nri-metadata-injection) | Yes | Enriches New Relic-instrumented applications (APM) with Kubernetes information. |
| [kube-state-metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) | | Required for `newrelic-infrastructure` to gather cluster-level metrics. |
| [nri-kube-events](https://github.com/newrelic/nri-kube-events/tree/main/charts/nri-kube-events) | | Reports Kubernetes events to New Relic. |
| [newrelic-infra-operator](https://github.com/newrelic/newrelic-infra-operator/tree/main/charts/newrelic-infra-operator) | | (Beta) Used with Fargate or serverless environments to inject `newrelic-infrastructure` as a sidecar instead of the usual DaemonSet. |
| [newrelic-k8s-metrics-adapter](https://github.com/newrelic/newrelic-k8s-metrics-adapter/tree/main/charts/newrelic-k8s-metrics-adapter) |  | (Beta) Provides a source of data for Horizontal Pod Autoscalers (HPA) based on a NRQL query from New Relic. |
| [newrelic-logging](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging) |  | Sends logs for Kubernetes components and workloads running on the cluster to New Relic. |
| [nri-prometheus](https://github.com/newrelic/nri-prometheus/tree/main/charts/nri-prometheus) |  | Sends metrics from applications exposing Prometheus metrics to New Relic. |
| [newrelic-prometheus-configurator](https://github.com/newrelic/newrelic-prometheus-configurator/tree/master/charts/newrelic-prometheus-agent) |  | Configures instances of Prometheus in Agent mode to send metrics to the New Relic Prometheus endpoint. |
| [newrelic-pixie](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-pixie) |  | Connects to the Pixie API and enables the New Relic plugin in Pixie. The plugin allows you to export data from Pixie to New Relic for long-term data retention. |
| [Pixie](https://docs.pixielabs.ai/installing-pixie/install-schemes/helm/#3.-deploy) |  | Is an open source observability tool for Kubernetes applications that uses eBPF to automatically capture telemetry data without the need for manual instrumentation. |

## Configure components

It is possible to configure settings for the individual charts this chart groups by specifying values for them under a key using the name of the chart,
as specified in [helm documentation](https://helm.sh/docs/chart_template_guide/subcharts_and_globals).

For example, by adding the following to the `values.yml` file:

```yaml
# Configuration settings for the newrelic-infrastructure chart
newrelic-infrastructure:
  # Any key defined in the values.yml file for the newrelic-infrastructure chart can be configured here:
  # https://github.com/newrelic/nri-kubernetes/blob/main/charts/newrelic-infrastructure/values.yaml

  verboseLog: false

  resources:
    limits:
      memory: 512M
```

It is possible to override any entry of the [`newrelic-infrastructure`](https://github.com/newrelic/nri-kubernetes/tree/main/charts/newrelic-infrastructure)
chart, as defined in their [`values.yml` file](https://github.com/newrelic/nri-kubernetes/blob/main/charts/newrelic-infrastructure/values.yaml).

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
  integrations:
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

## Bring your own KSM

New Relic Kubernetes Integration requires an instance of kube-state-metrics (KSM) to be running in the cluster, which this chart pulls as a dependency. If you are already running or want to run your own KSM instance, you will need to make some small adjustments as described below.

### Bring your own KSM

If you already have one KSM instance running, you can point `nri-kubernetes` to your instance:

```yaml
kube-state-metrics:
  # Disable bundled KSM.
  enabled: false
newrelic-infrastructure:
  ksm:
    config:
      # Selector for your pre-installed KSM Service. You may need to adjust this to fit your existing installation.
      selector: "app.kubernetes.io/name=kube-state-metrics"
      # Alternatively, you can specify a fixed URL where KSM is available. Doing so will bypass autodiscovery.
      #staticUrl: http://ksm.ksm.svc.cluster.local:8080/metrics
```

### <span id="ksm-different-version">Run KSM alongside a different version</span>

If you need to run a different instance of KSM in your cluster, you can still run a separate instance for the Kubernetes Integration to work as intended:

```yaml
kube-state-metrics:
  # Enable bundled KSM.
  enabled: true
  prometheusScrape: false
  customLabels:
    # Label unique to this KSM instance.
    newrelic.com/custom-ksm: "true"
newrelic-infrastructure:
  ksm:
    config:
      # Use label above as a selector.
      selector: "newrelic.com/custom-ksm=true"
```

For more information on supported KSM version visit the [requirements documentation](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/get-started/kubernetes-integration-compatibility-requirements#reqs)

## Values managed globally

Some of the subchart implement the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations`, `proxy` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

At the time of writing this document, all the charts from `nri-bundle` except `newrelic-logging` and `synthetics-minion` implements this library and
honors global options as described below.

Note, the value table below is automatically generated from `values.yaml` by `helm-docs`. If you need to add new fields or update existing fields, please update the `values.yaml` and then run `helm-docs` to update this value table.

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
| kube-state-metrics.enabled | bool | `false` | Install the [`kube-state-metrics` chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) from the stable helm charts repository. This is mandatory if `infrastructure.enabled` is set to `true` and the user does not provide its own instance of KSM version >=1.8 and <=2.0. Note, kube-state-metrics v2+ disables labels/annotations metrics by default. You can enable the target labels/annotations metrics to be monitored by using the metricLabelsAllowlist/metricAnnotationsAllowList options described [here](https://github.com/prometheus-community/helm-charts/blob/159cd8e4fb89b8b107dcc100287504bb91bf30e0/charts/kube-state-metrics/values.yaml#L274) in your Kubernetes clusters. |
| newrelic-infra-operator.enabled | bool | `false` | Install the [`newrelic-infra-operator` chart](https://github.com/newrelic/newrelic-infra-operator/tree/main/charts/newrelic-infra-operator) (Beta) |
| newrelic-infrastructure.enabled | bool | `true` | Install the [`newrelic-infrastructure` chart](https://github.com/newrelic/nri-kubernetes/tree/main/charts/newrelic-infrastructure) |
| newrelic-k8s-metrics-adapter.enabled | bool | `false` | Install the [`newrelic-k8s-metrics-adapter.` chart](https://github.com/newrelic/newrelic-k8s-metrics-adapter/tree/main/charts/newrelic-k8s-metrics-adapter) (Beta) |
| newrelic-logging.enabled | bool | `false` | Install the [`newrelic-logging` chart](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging) |
| newrelic-pixie.enabled | bool | `false` | Install the [`newrelic-pixie`](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-pixie) |
| newrelic-prometheus-agent.enabled | bool | `false` | Install the [`newrelic-prometheus-agent` chart](https://github.com/newrelic/newrelic-prometheus-configurator/tree/main/charts/newrelic-prometheus-agent) |
| nri-kube-events.enabled | bool | `false` | Install the [`nri-kube-events` chart](https://github.com/newrelic/nri-kube-events/tree/main/charts/nri-kube-events) |
| nri-metadata-injection.enabled | bool | `true` | Install the [`nri-metadata-injection` chart](https://github.com/newrelic/k8s-metadata-injection/tree/main/charts/nri-metadata-injection) |
| nri-prometheus.enabled | bool | `false` | Install the [`nri-prometheus` chart](https://github.com/newrelic/nri-prometheus/tree/main/charts/nri-prometheus) |
| pixie-chart.enabled | bool | `false` | Install the [`pixie-chart` chart](https://docs.pixielabs.ai/installing-pixie/install-schemes/helm/#3.-deploy) |

## Maintainers

* [juanjjaramillo](https://github.com/juanjjaramillo)
* [csongnr](https://github.com/csongnr)
* [dbudziwojskiNR](https://github.com/dbudziwojskiNR)
