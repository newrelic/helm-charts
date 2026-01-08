<a href="https://opensource.newrelic.com/oss-category/#community-plus"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Plus.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"><img alt="New Relic Open Source community plus project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"></picture></a>

# nr-ebpf-agent

A Helm chart to monitor a Kubernetes Cluster using the eBPF agent.

# Helm installation

1. Download and modify the default configuration file [values.yaml](https://github.com/newrelic/helm-charts/blob/master/charts/nr-ebpf-agent/values.yaml#L1-L4). At minimum, you will need populate the `licenseKey` field with a valid New Relic Ingest key and the `cluster` field with the name of the cluster to monitor.

Example:
```
licenseKey: "EXAMPLEINGESTLICENSEKEY345878592NRALL"
cluster: "name-of-cluster-to-monitor"
```

2. Install the helm chart, passing the configuration file created above.
```sh
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade nr-ebpf-agent newrelic/nr-ebpf-agent -f your-custom-values.yaml -n newrelic --create-namespace --install
```

## Source Code

* <https://github.com/newrelic/>

## Confirm installation
### Watch pods spin up:

```
kubectl get pods -n newrelic --watch
```

### Check the logs of the eBPF agent pod:
```
# The agent container logs detail probe attachment and data collection.
kubectl logs <ebpf-pod-name> -c nr-ebpf-agent -n newrelic
```

### Confirm data ingest to New Relic
You should see data reporting into New Relic within a couple of seconds to the `Metric` and `Span` tables.
```
FROM Metric SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'

FROM Span SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```
The entities view should show OTel services and an "APM-lite" rendition of the data for each entity when clicked on.

## Uninstall

Run the following command.

```
helm uninstall ebpf-agent -n newrelic
```

## Values managed globally

This chart implements the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Sets all pods' affinities. Can be configured also with `global.affinity` |
| allDataFilters | object | `{"dropApmAgentEnabledEntity":false,"dropNamespaces":["kube-system"],"dropNewRelicBundle":true,"dropServiceNameRegex":"","keepServiceNameRegex":""}` | All data drop filters configuration Configure filters to drop all types of data (Network Metrics and APM data) based on config provided |
| allDataFilters.dropApmAgentEnabledEntity | bool | `false` | Drop all data for applications/entities that have NewRelic/OTEL APM agents running |
| allDataFilters.dropNamespaces | list | `["kube-system"]` | List of Kubernetes namespaces for which all data should be dropped by the agent. RENAMED from 'dropDataForNamespaces' for clarity. The old name is deprecated but still supported for backward compatibility. |
| allDataFilters.dropNewRelicBundle | bool | `true` | Drop data from the newrelic namespace and newrelic-bundle services. RENAMED from 'dropDataNewRelic' for clarity. The old name is deprecated but still supported for backward compatibility. |
| allDataFilters.dropServiceNameRegex | string | `""` | Define a regex to match k8s service names to drop. Example "kube-dns|otel-collector|\\bblah\\b" RENAMED from 'dropServiceNameRegex' for clarity. The old name is deprecated but still supported for backward compatibility. |
| allDataFilters.keepServiceNameRegex | string | `""` | This config acts as a bypass for the dropServiceNameRegex config. Service names that match this regex will not have their data dropped by the dropServiceNameRegex. RENAMED from 'allowServiceNameRegex' for clarity. The old name is deprecated but still supported for backward compatibility. |
| apmDataFilters | object | `{"apmAgentEnabledEntity":false,"dropEntityName":[],"dropPodLabels":{},"keepEntityName":[]}` | APM data filters configuration Configure filters to drop ebpf APM data based on config provided |
| apmDataFilters.apmAgentEnabledEntity | bool | `false` | Drop eBPF APM data for applications/entities that have NewRelic APM/OTel agents running |
| apmDataFilters.dropEntityName | list | `[]` | List of entity names to drop ebpf APM data for |
| apmDataFilters.dropPodLabels | object | `{}` | Pod labels to match for filtering APM data. Empty map means no label-based filtering Example: dropPodLabels: { "app": "frontend", "env": "production" } |
| apmDataFilters.keepEntityName | list | `[]` | This config bypasses dropEntityName filter. |
| apmDataReporting | bool | `true` | Enable APM data reporting. When enabled, the agent collects and reports application performance monitoring data |
| cluster | string | `""` | Name of the Kubernetes cluster to be monitored. Mandatory. Can be configured with `global.cluster` |
| containerSecurityContext | object | `{}` | Sets all pods' containerSecurityContext. Can be configured also with `global.securityContext.container` |
| customSecretLicenseKey | string | `""` | In case you don't want to have the license key in your values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | In case you don't want to have the license key in your values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| ebpfAgent.affinity | object | `{}` | Sets ebpfAgent pod affinities. Overrides `affinity` and `global.affinity` |
| ebpfAgent.containerSecurityContext | object | `{}` | Sets ebpfAgent pod containerSecurityContext. Overrides `containerSecurityContext` and `global.securityContext.container` |
| ebpfAgent.distroKernelHeadersPath | string | `""` |  |
| ebpfAgent.downloadedPackagedHeadersPath | string | `""` |  |
| ebpfAgent.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| ebpfAgent.image.repository | string | `"docker.io/newrelic/newrelic-ebpf-agent"` | eBPF agent image to be deployed. |
| ebpfAgent.image.tag | string | `""` | The tag of the eBPF agent image to be deployed. If empty, uses Chart.AppVersion. |
| ebpfAgent.podAnnotations | object | `{}` | Sets ebpfAgent pod Annotations. Overrides `podAnnotations` and `global.podAnnotations` |
| ebpfAgent.podSecurityContext | object | `{}` | Sets ebpfAgent pod podSecurityContext. Overrides `podSecurityContext` and `global.securityContext.pod` |
| ebpfAgent.resources.limits.memory | string | `"2Gi"` | Max memory allocated to the container. |
| ebpfAgent.resources.requests.cpu | string | `"100m"` | Min CPU allocated to the container. |
| ebpfAgent.resources.requests.memory | string | `"250Mi"` | Min memory allocated to the container. |
| ebpfAgent.serviceAccount.annotations | object | `{}` |  |
| ebpfAgent.tolerations | list | `[]` | Sets ebpfAgent pod tolerations. Overrides `tolerations` and `global.tolerations` |
| kubernetesClusterDomain | string | `"cluster.local"` | Kubernetes cluster domain. |
| labels | object | `{}` | Additional labels for chart objects. |
| licenseKey | string | `""` | The license key to use. Can be configured with `global.licenseKey` |
| logFilePath | string | `""` | To configure log file path of eBPF Agent. If logging to this path fails, logs will be directed to stdout. |
| logLevel | string | `"INFO"` | OFF, FATAL, ERROR, WARNING, INFO, DEBUG |
| networkMetricsDataFilter | object | `{"dropEntityName":[],"dropPodLabels":{},"keepEntityName":[]}` | Network metrics Data filter / TCP stats filters Configure filters to drop/keep Network metrics data based on config provided |
| networkMetricsDataFilter.dropEntityName | list | `[]` | List of entity names to drop Network metrics data for |
| networkMetricsDataFilter.dropPodLabels | object | `{}` | Pod labels to match for filtering Network metrics data. Empty map means no label-based filtering Example: dropPodLabels: { "app": "frontend", "env": "production" } |
| networkMetricsDataFilter.keepEntityName | list | `[]` | This config bypasses dropEntityName filter. |
| networkMetricsReporting | bool | `true` | Enable network metrics reporting. When enabled, the agent collects and reports network metrics including TCP statistics RENAMED from 'tcpStatsReporting' for clarity. The old name is deprecated but still supported for backward compatibility. |
| nodeSelector | object | `{}` | Sets all pods' node selector. Can be configured also with `global.nodeSelector` |
| podLabels | object | `{}` | Additional labels for chart pods. |
| podSecurityContext | object | `{}` | Sets all pods' podSecurityContext. Can be configured also with `global.securityContext.pod` |
| priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| protocols.amqp.enabled | bool | `true` |  |
| protocols.amqp.spans.enabled | bool | `true` |  |
| protocols.amqp.spans.samplingLatency | string | `""` |  |
| protocols.cass.enabled | bool | `true` |  |
| protocols.cass.spans.enabled | bool | `true` |  |
| protocols.cass.spans.samplingLatency | string | `""` |  |
| protocols.dns.enabled | bool | `true` |  |
| protocols.dns.spans.enabled | bool | `true` |  |
| protocols.dns.spans.samplingLatency | string | `""` |  |
| protocols.http.enabled | bool | `true` |  |
| protocols.http.spans.enabled | bool | `true` |  |
| protocols.http.spans.samplingErrorRate | string | `""` | samplingErrorRate represents the error rate threshold for an HTTP route where surpassing it would mean the corresponds spans of the route are exported. Options: 1-100 |
| protocols.http.spans.samplingLatency | string | `"p50"` |  |
| protocols.kafka.enabled | bool | `true` |  |
| protocols.kafka.spans.enabled | bool | `true` |  |
| protocols.kafka.spans.samplingLatency | string | `""` |  |
| protocols.mongodb.enabled | bool | `true` |  |
| protocols.mongodb.spans.enabled | bool | `true` |  |
| protocols.mongodb.spans.samplingLatency | string | `""` |  |
| protocols.mysql.enabled | bool | `true` |  |
| protocols.mysql.spans.enabled | bool | `true` |  |
| protocols.mysql.spans.samplingLatency | string | `""` |  |
| protocols.pgsql.enabled | bool | `true` |  |
| protocols.pgsql.spans.enabled | bool | `true` |  |
| protocols.pgsql.spans.samplingLatency | string | `""` |  |
| protocols.redis.enabled | bool | `true` |  |
| protocols.redis.spans.enabled | bool | `true` |  |
| protocols.redis.spans.samplingLatency | string | `""` |  |
| proxy | string | `""` | Configures the agent to send all data through the proxy specified via the otel collector. |
| pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| region | string | `""` | If using a customSecretLicenseKey, you must supply your region "US"/"EU". Otherwise, leave this value as an empty string. |
| tableStoreDataLimitMB | string | `"250"` | The primary lever to control RAM use of the eBPF agent. Specified in MiB. |
| tolerations | list | `[]` | Sets all pods' tolerations to node taints. Can be configured also with `global.tolerations` |

## Common Errors

### Exporting Errors

If the `nr-ebpf-agent` container logs indicate that the agent is failing to export data, ensure that Linux headers are installed on the host. Verify that the `nr-ebpf-agent` container logs indicate that the Linux header files were found and that the Stirling data tables were initialized. These logs should be written as the agent is booting up (towards the beginning of the output).

## Maintainers

* kkhandelwal
* burhan-nr