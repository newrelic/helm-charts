<a href="https://opensource.newrelic.com/oss-category/#community-plus"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Plus.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"><img alt="New Relic Open Source community plus project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"></picture></a>

# nr-ebpf-agent

A Helm chart to monitor a Kubernetes Cluster using the eBPF agent.

# Helm installation

1. Download and modify the default configuration file [values.yaml](https://github.com/newrelic/helm-charts/blob/master/charts/nr-ebpf-agent/values.yaml#L1-L4). At minimum, you will need populate the `licenseKey` field with a valid New Relic Ingest key and the `cluster` field with the name of the cluster to monitor.

**NOTE: From chart version 0.2.x onwards, please use the latest [values.yaml](https://github.com/newrelic/helm-charts/blob/master/charts/nr-ebpf-agent/values.yaml) bundled with each Helm release. This will ensure compatibility with new features and configuration options.**

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
# The client container logs report data export metrics.
kubectl logs <ebpf-pod-name> -c nr-ebpf-client -n newrelic

# The agent container logs detail probe attachment and data collection.
kubectl logs <ebpf-pod-name> -c nr-ebpf-agent -n newrelic
```

### Check the logs of the OpenTelemetry collector pod:
```
kubectl logs <otel-pod-name> -n newrelic
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
| allowServiceNameRegex | string | `""` | This config acts as a bypass for the dropDataServiceNameRegex config. Service names that match this regex will not have their data dropped by the dropDataServiceNameRegex. If dropDataServiceNameRegex is not defined, this config has no impact on the eBPF agent. |
| cluster | string | `""` | Name of the Kubernetes cluster to be monitored. Mandatory. Can be configured with `global.cluster` |
| containerSecurityContext | object | `{}` | Sets all pods' containerSecurityContext. Can be configured also with `global.securityContext.container` |
| customSecretLicenseKey | string | `""` | In case you don't want to have the license key in your values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | In case you don't want to have the license key in your values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| logLevel | string | `INFO` | To configure the log level in increasing order of verboseness. OFF, FATAL, ERROR, WARNING, INFO, DEBUG |
| logFilePath | string | `""` | To configure log file path of eBPF Agent. If logging to this path fails, logs will be directed to stdout. |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| dropAPMEnabledPods | bool | `false` | Drop data from pods that are monitored by New Relic APM via auto attach. |
| dropDataIpServiceNames | bool | `true` | Drop data when service names map to an IP address. |
| dropDataNewRelic | bool | `true` | Drop data from the newrelic namespace and newrelic-bundle services. |
| dropDataForEntity | list | `[]` | list entity to ignore the process monitoring based on `NEW_RELIC_APP_NAME` |
| dropDataForNamespaces | list | `[]` | List of Kubernetes namespaces for which all data should be dropped by the agent. |
| dropDataServiceNameRegex | string | `""` | Define a regex to match service names to drop. Example "kube-dns|otel-collector|\\bblah\\b" see Golang Docs for Regex syntax https://github.com/google/re2/wiki/Syntax |
| ebpfAgent.affinity | object | `{}` | Sets ebpfAgent pod affinities. Overrides `affinity` and `global.affinity` |
| ebpfAgent.containerSecurityContext | object | `{}` | Sets ebpfAgent pod containerSecurityContext. Overrides `containerSecurityContext` and `global.securityContext.container` |
| ebpfAgent.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| ebpfAgent.image.repository | string | `"docker.io/newrelic/newrelic-ebpf-agent"` | eBPF agent image to be deployed. |
| ebpfAgent.image.tag | string | `"agent-nr-ebpf-agent_0.0.9"` | The tag of the eBPF agent image to be deployed. |
| ebpfAgent.podAnnotations | object | `{}` | Sets ebpfAgent pod Annotations. Overrides `podAnnotations` and `global.podAnnotations` |
| ebpfAgent.podSecurityContext | object | `{}` | Sets ebpfAgent pod podSecurityContext. Overrides `podSecurityContext` and `global.securityContext.pod` |
| ebpfAgent.resources.limits.memory | string | `"2Gi"` | Max memory allocated to the container. |
| ebpfAgent.resources.requests.cpu | string | `"100m"` | Min CPU allocated to the container. |
| ebpfAgent.resources.requests.memory | string | `"250Mi"` | Min memory allocated to the container. |
| ebpfAgent.tolerations | list | `[]` | Sets ebpfAgent pod tolerations. Overrides `tolerations` and `global.tolerations` |
| ebpfClient.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is set to Always. |
| ebpfClient.image.repository | string | `"docker.io/newrelic/newrelic-ebpf-agent"` | eBPF client image to be deployed. |
| ebpfClient.image.tag | string | `"client-nr-ebpf-client_0.0.12"` | The tag of the eBPF client image to be deployed. |
| ebpfClient.resources.limits.memory | string | `"100Mi"` | Max memory allocated to the container. |
| ebpfClient.resources.requests.cpu | string | `"50m"` | Min CPU allocated to the container. |
| ebpfClient.resources.requests.memory | string | `"50Mi"` | Min memory allocated to the container. |
| kubernetesClusterDomain | string | `"cluster.local"` | Kubernetes cluster domain. |
| labels | object | `{}` | Additional labels for chart objects. |
| licenseKey | string | `""` | The license key to use. Can be configured with `global.licenseKey` |
| nodeSelector | object | `{}` | Sets all pods' node selector. Can be configured also with `global.nodeSelector` |
| nrStaging | bool | `false` | Endpoint to export data to via the otel collector. NR prod (otlp.nr-data.net:4317) by default. Staging (staging-otlp.nr-data.net:4317) otherwise. |
| otelCollector.affinity | object | `{}` | Sets otelCollector pod affinities. Overrides `affinity` and `global.affinity` |
| otelCollector.collector.serviceAccount.annotations | object | `{}` | Annotations for the OTel collector service account. |
| otelCollector.containerSecurityContext | object | `{}` | Sets otelCollector pod containerSecurityContext. Overrides `containerSecurityContext` and `global.securityContext.container` |
| otelCollector.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is set to Always. |
| otelCollector.image.repository | string | `"docker.io/newrelic/newrelic-ebpf-agent"` | OpenTelemetry collector image to be deployed. |
| otelCollector.image.tag | string | `"nr-ebpf-otel-collector_0.0.1"` | The tag of the OpenTelemetry collector image to be deployed. |
| otelCollector.podAnnotations | object | `{}` | Sets otelCollector pod Annotations. Overrides `podAnnotations` and `global.podAnnotations` |
| otelCollector.podSecurityContext | object | `{}` | Sets otelCollector pod podSecurityContext. Overrides `podSecurityContext` and `global.securityContext.pod` |
| otelCollector.resources.limits.cpu | string | `"100m"` | Max CPU allocated to the container. |
| otelCollector.resources.limits.memory | string | `"200Mi"` | Max memory allocated to the container. |
| otelCollector.resources.requests.cpu | string | `"100m"` | Min CPU allocated to the container. |
| otelCollector.resources.requests.memory | string | `"200Mi"` | Min memory allocated to the container. |
| otelCollector.tolerations | list | `[]` | Sets otelCollector pod tolerations. Overrides `tolerations` and `global.tolerations` |
| podLabels | object | `{}` | Additional labels for chart pods. |
| podSecurityContext | object | `{}` | Sets all pods' podSecurityContext. Can be configured also with `global.securityContext.pod` |
| priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| protocols.amqp.enabled | bool | `false` |  |
| protocols.amqp.spans.enabled | bool | `false` |  |
| protocols.amqp.spans.samplingLatency | string | `""` |  |
| protocols.cass.enabled | bool | `true` |  |
| protocols.cass.spans.enabled | bool | `false` |  |
| protocols.cass.spans.samplingLatency | string | `""` |  |
| protocols.dns.enabled | bool | `false` |  |
| protocols.dns.spans.enabled | bool | `false` |  |
| protocols.dns.spans.samplingLatency | string | `""` |  |
| protocols.http.enabled | bool | `true` |  |
| protocols.http.spans.enabled | bool | `true` |  |
| protocols.http.spans.samplingErrorRate | string | `""` | samplingErrorRate represents the error rate threshold for an HTTP route where surpassing it would mean the corresponds spans of the route are exported. Options: 1-100 |
| protocols.http.spans.samplingLatency | string | `"p50"` |  |
| protocols.kafka.enabled | bool | `false` |  |
| protocols.kafka.spans.enabled | bool | `false` |  |
| protocols.kafka.spans.samplingLatency | string | `""` |  |
| protocols.mongodb.enabled | bool | `true` |  |
| protocols.mongodb.spans.enabled | bool | `false` |  |
| protocols.mongodb.spans.samplingLatency | string | `""` |  |
| protocols.mysql.enabled | bool | `true` |  |
| protocols.mysql.spans.enabled | bool | `false` |  |
| protocols.mysql.spans.samplingLatency | string | `""` |  |
| protocols.pgsql.enabled | bool | `true` |  |
| protocols.pgsql.spans.enabled | bool | `false` |  |
| protocols.pgsql.spans.samplingLatency | string | `""` |  |
| protocols.redis.enabled | bool | `true` |  |
| protocols.redis.spans.enabled | bool | `false` |  |
| protocols.redis.spans.samplingLatency | string | `""` |  |
| proxy | string | `""` | Configures the agent to send all data through the proxy specified via the otel collector. |
| stirlingSources | string | `"socket_tracer,tcp_stats"` | The source connectors (and data export scripts) to enable. Note that socket_tracer tracks http, mysql, redis, mongodb, amqp, cassandra, dns, and postgresql while tcp_stats tracks TCP metrics. |
| tableStoreDataLimitMB | string | `"250"` | The primary lever to control RAM use of the eBPF agent. Specified in MiB. |
| tls.certPath | string | `"/etc/newrelic-ebpf-agent/certs/"` | Certificates path. |
| tls.autoGenerateCert.certPeriodDays | int | `365` | Cert validity period time in days. |
| tls.autoGenerateCert.enabled | bool | `true` | If true, Helm will automatically create a self-signed cert and secret for you. |
| tls.autoGenerateCert.recreate | bool | `true` | If set to true, a new key/certificate is generated on helm upgrade. |
| tls.caFile | string | `""` | Path to the CA cert. |
| tls.certFile | string | `""` | Path to your own PEM-encoded certificate. |
| tls.enabled | bool | `true` | Enable TLS communication between the eBPF client and agent. |
| tls.keyFile | string | `""` | Path to your own PEM-encoded private key. |
| tolerations | list | `[]` | Sets all pods' tolerations to node taints. Can be configured also with `global.tolerations` |
| verboseLog | bool | `false` | Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog` |

## Common Errors

### Exporting Errors

If the `nr-ebpf-client` or `nr-ebpf-agent` container logs indicate that the scripts are failing to export data, ensure that Linux headers are installed on the host. Verify that the `nr-ebpf-agent` container logs indicate that the Linux header files were found and that the Stirling data tables were initialized. These logs should be written as the agent is booting up (towards the beginning of the output).

## Maintainers

* ramkrishankumarN
* kpattaswamy
* benkilimnik