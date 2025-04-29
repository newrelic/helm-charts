<a href="https://opensource.newrelic.com/oss-category/#community-plus"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Plus.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"><img alt="New Relic Open Source community plus project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"></picture></a>

# nr-k8s-otel-collector

A Helm chart to monitor a Kubernetes Cluster using an OpenTelemetry Collector.

# Helm installation

Download and Update config [here](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/values.yaml#L20-L24) to add a cluster name, and New Relic Ingest - License key

Example:
```
licenseKey: "EXAMPLEINGESTLICENSEKEY345878592NRALL"
cluster: "SampleApp"
```

You can install this chart using directly this Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade nr-k8s-otel-collector newrelic/nr-k8s-otel-collector -f your-custom-values.yaml -n newrelic --create-namespace --install
```

## Confirm installation
### Watch pods spin up:

```
kubectl get pods -n newrelic --watch
```

### Check logs of opentelemetry pod that spins up:
```
kubectl logs <otel-pod-name> -n newrelic
```

### Confirm data coming through in New Relic
You should see data reporting into New Relic within a couple of seconds to the `InfrastructureEvent` table, `Metric` table, and `Log` tables.
```
FROM Metric SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```
```
FROM InfrastructureEvent SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```
```
FROM Log SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```
## Uninstall

Run the following command.

```
helm uninstall nr-k8s-otel-collector -n newrelic
```

## Values managed globally

This chart implements the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

## GKE Autopilot

If using GKE Autopilot, please set the following configuration in your values.yaml file in order for the agent to work with GKE Autopilot.

```
gkeAutopilot: true
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Sets all pods' affinities. Can be configured also with `global.affinity` |
| cluster | string | `""` | Name of the Kubernetes cluster monitored. Mandatory. Can be configured also with `global.cluster` |
| containerSecurityContext | object | `{}` | Sets all security context (at container level). Can be configured also with `global.securityContext.container` |
| customSecretLicenseKey | string | `""` | In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| daemonset.affinity | object | `{}` | Sets daemonset pod affinities. Overrides `affinity` and `global.affinity` |
| daemonset.configMap | object | See `values.yaml` | Settings for daemonset configmap |
| daemonset.configMap.config | object | `{}` | OpenTelemetry config for the daemonset. If set, overrides default config and disables configuration parameters for the daemonset. |
| daemonset.containerSecurityContext | object | `{"privileged":true}` | Sets security context (at container level) for the daemonset. Overrides `containerSecurityContext` and `global.containerSecurityContext` |
| daemonset.envs | list | `[]` | Sets additional environment variables for the daemonset. |
| daemonset.envsFrom | list | `[]` | Sets additional environment variable sources for the daemonset. |
| daemonset.nodeSelector | object | `{}` | Sets daemonset pod node selector. Overrides `nodeSelector` and `global.nodeSelector` |
| daemonset.podAnnotations | object | `{}` | Annotations to be added to the daemonset. |
| daemonset.podSecurityContext | object | `{}` | Sets security context (at pod level) for the daemonset. Overrides `podSecurityContext` and `global.podSecurityContext` |
| daemonset.resources | object | `{}` | Sets resources for the daemonset. |
| daemonset.tolerations | list | `[]` | Sets daemonset pod tolerations. Overrides `tolerations` and `global.tolerations` |
| deployment.affinity | object | `{}` | Sets deployment pod affinities. Overrides `affinity` and `global.affinity` |
| deployment.configMap | object | See `values.yaml` | Settings for deployment configmap |
| deployment.configMap.config | object | `{}` | OpenTelemetry config for the deployment. If set, overrides default config and disables configuration parameters for the deployment. |
| deployment.containerSecurityContext | object | `{}` | Sets security context (at container level) for the deployment. Overrides `containerSecurityContext` and `global.containerSecurityContext` |
| deployment.envs | list | `[]` | Sets additional environment variables for the deployment. |
| deployment.envsFrom | list | `[]` | Sets additional environment variable sources for the deployment. |
| deployment.nodeSelector | object | `{}` | Sets deployment pod node selector. Overrides `nodeSelector` and `global.nodeSelector` |
| deployment.podAnnotations | object | `{}` | Annotations to be added to the deployment. |
| deployment.podSecurityContext | object | `{}` | Sets security context (at pod level) for the deployment. Overrides `podSecurityContext` and `global.podSecurityContext` |
| deployment.resources | object | `{}` | Sets resources for the deployment. |
| deployment.tolerations | list | `[]` | Sets deployment pod tolerations. Overrides `tolerations` and `global.tolerations` |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| gkeAutopilot | bool | `false` | If deploying to a GKE autopilot cluster, set to true |
| image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| image.repository | string | `"newrelic/nrdot-collector-k8s"` | OTel collector image to be deployed. You can use your own collector as long it accomplish the following requirements mentioned below. |
| image.tag | string | `"1.0.3"` | Overrides the image tag whose default is the chart appVersion. |
| kube-state-metrics.enabled | bool | `true` | Install the [`kube-state-metrics` chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) from the stable helm charts repository. This is mandatory if `infrastructure.enabled` is set to `true` and the user does not provide its own instance of KSM version >=1.8 and <=2.0. Note, kube-state-metrics v2+ disables labels/annotations metrics by default. You can enable the target labels/annotations metrics to be monitored by using the metricLabelsAllowlist/metricAnnotationsAllowList options described [here](https://github.com/prometheus-community/helm-charts/blob/159cd8e4fb89b8b107dcc100287504bb91bf30e0/charts/kube-state-metrics/values.yaml#L274) in your Kubernetes clusters. |
| kube-state-metrics.prometheusScrape | bool | `false` | Disable prometheus from auto-discovering KSM and potentially scraping duplicated data |
| labels | object | `{}` | Additional labels for chart objects |
| licenseKey | string | `""` | This set this license key to use. Can be configured also with `global.licenseKey` |
| lowDataMode | bool | `true` | Send only the [metrics required](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/docs/metrics-lowDataMode.md) to light up the NR kubernetes UI |
| nodeSelector | object | `{}` | Sets all pods' node selector. Can be configured also with `global.nodeSelector` |
| nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| podLabels | object | `{}` | Additional labels for chart pods |
| podSecurityContext | object | `{}` | Sets all security contexts (at pod level). Can be configured also with `global.securityContext.pod` |
| priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| rbac.create | bool | `true` | Specifies whether RBAC resources should be created |
| receivers.filelog.enabled | bool | `true` | Specifies whether the `filelog` receiver is enabled |
| receivers.hostmetrics.enabled | bool | `true` | Specifies whether the `hostmetrics` receiver is enabled |
| receivers.hostmetrics.scrapeInterval | string | `1m` | Sets the scrape interval for the `hostmetrics` receiver |
| receivers.k8sEvents.enabled | bool | `true` | Specifies whether the `k8s_events` receiver is enabled |
| receivers.kubeletstats.enabled | bool | `true` | Specifies whether the `kubeletstats` receiver is enabled |
| receivers.kubeletstats.scrapeInterval | string | `1m` | Sets the scrape interval for the `kubeletstats` receiver |
| receivers.prometheus.enabled | bool | `true` | Specifies whether the `prometheus` receiver is enabled |
| receivers.prometheus.scrapeInterval | string | `1m` | Sets the scrape interval for the `prometheus` receiver |
| serviceAccount | object | See `values.yaml` | Settings controlling ServiceAccount creation |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created |
| tolerations | list | `[]` | Sets all pods' tolerations to node taints. Can be configured also with `global.tolerations` |
| verboseLog | bool | `false` | Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog` |

**Note:** If all receivers are disabled in the deployment or in the daemonset, the agent will not start.

## Metrics

* [Metrics - Full list](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/docs/metrics-full.md)
* [Metrics - LowDataMode list](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/docs/metrics-lowDataMode.md)

## Common Errors

### Exporting Errors

Timeout errors while starting up the collector are expected as the collector attempts to establish a connection with NR.
These timeout errors can also pop up over time as the collector is running but are transient and expected to self-resolve. Further improvements are underway to mitigate the amount of timeout errors we're seeing from the NR1 endpoint.

```
info	exporterhelper/retry_sender.go:154	Exporting failed. Will retry the request after interval.	{"kind": "exporter", "data_type": "metrics", "name": "otlphttp/newrelic", "error": "failed to make an HTTP request: Post \"https://staging-otlp.nr-data.net/v1/metrics\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)", "interval": "5.445779213s"}
```

### No such file or directory

Sometimes we see failed to open file errors on the `filelog` and `hostmetrics` receiver because of a race condition where the file or directory no longer exists, as the pod or process was ephemeral (e.g. a cronjob, sleep) and the pod or process was terminated before the collector could read the file.

`filelog` error:
```
Failed to open file	{"kind": "receiver", "name": "filelog", "data_type": "logs", "component": "fileconsumer", "error": "open /var/log/pods/<podname>/<containername>/0.log: no such file or directory"}
```
`hostmetrics` error:
```
Error scraping metrics	{"kind": "receiver", "name": "hostmetrics", "data_type": "metrics", "error": "error reading <metric> for process \"<process>\" (pid <PID>): open /hostfs/proc/<PID>/stat: no such file or directory; error reading <metric> info for process \"<process>\" (pid 511766): open /hostfs/proc/<PID>/<metric>: no such file or directory", "scraper": "process"}
```

## Maintainers

* [dbudziwojskiNR](https://github.com/dbudziwojskiNR)
* [kpattaswamy](https://github.com/kpattaswamy)
* [Philip-R-Beckwith](https://github.com/Philip-R-Beckwith)
