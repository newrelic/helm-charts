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
| cluster | string | `""` | Name of the Kubernetes cluster monitored. Mandatory. Can be configured also with `global.cluster` |
| licenseKey | string | `""` | The NR license key to use. Can be configured also with `global.licenseKey` |
| nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| tableStoreDataLimitMB | string | `"250"` | The primary lever to control RAM use of the eBPF agent. Specified in MiB. |
| stirlingSources | string | `"socket_tracer,tcp_stats,jvm_stats"` | The source connectors (and data export scripts) to enable. Note that socket_tracer tracks http, mysql, redis, mongodb, amqp, cassandra, dns, and postgresql while tcp_stats tracks TCP metrics and jvm_stats tracks JVM metrics. |
| protocols.http | bool | `true` | Enable tracing of HTTP and HTTP2. |
| protocols.kafka | bool | `true` | Enable tracing of Kafka. |
| protocols.mysql | bool | `true` | Enable tracing of MySQL. |
| protocols.redis | bool | `true` | Enable tracing of Redis. |
| protocols.mongodb | bool | `true` | Enable tracing of MongoDB. |
| protocols.amqp | bool | `true` | Enable tracing of AMQP. |
| protocols.cass | bool | `true` | Enable tracing of Cassandra. |
| protocols.dns | bool | `true` | Enable tracing of DNS. |
| protocols.pgsql | bool | `true` | Enable tracing of Postgres. |
| ebpfAgent.image.repository | string | `"us-west1-docker.pkg.dev/pl-dev-infra/nr-ebpf-agent-lp/ebpf-agent"` | eBPF agent image to be deployed. |
| ebpfAgent.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| ebpfAgent.image.tag | string | `"0.0.1"` | Tag of the image to deploy. |
| ebpfAgent.resources.limits.memory | string | `"2Gi"` | Max memory allocatable to the container. |
| ebpfAgent.resources.requests.cpu | string | `"100m"` | Minimum cpu allocated to the container. |
| ebpfAgent.resources.requests.memory | string | `"250Mi"` | Minimum memory allocated to the container. |
| ebpfClient.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| ebpfClient.image.repository | string | `"us-west1-docker.pkg.dev/pl-dev-infra/nr-ebpf-agent-lp/ebpf-client"` | eBPF client image to be deployed. |
| ebpfClient.image.tag | string | `"0.0.1"` | Tag of the image to deploy. |
| ebpfClient.resources.limits.memory | string | `"100Mi"` | Max memory allocatable to the container. |
| ebpfClient.resources.requests.cpu | string | `"50m"` | Minimum cpu allocated to the container. |
| ebpfClient.resources.requests.memory | string | `"50Mi"` | Minimum memory allocated to the container. |
| otelCollector.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| otelCollector.image.repository | string | `"us-west1-docker.pkg.dev/pl-dev-infra/nr-ebpf-agent-lp/nr-ebpf-otel-collector"` | New Relic custom OTel collector image to be deployed. |
| otelCollector.image.tag | string | `"0.0.1"` | Tag of the image to deploy. |
| otelCollector.resources.limits.cpu | string | `"100m"` | Max memory allocatable to the container. |
| otelCollector.resources.limits.memory | string | `"200Mi"` | Max memory allocatable to the container. |
| otelCollector.resources.requests.cpu | string | `"100m"` | Minimum cpu allocated to the container. |
| otelCollector.resources.requests.memory | string | `"200Mi"` | Minimum memory allocated to the container. |
| otelCollector.collector.serviceAccount.annotations | object | `{}` | Annotations for the OTel collector service account. |
| podLabels | object | `{}` | Additional labels for chart pods |
| labels | object | `{}` | Additional labels for chart objects |
| nodeSelector | object | `{}` | Sets all pods' node selector. Can be configured also with `global.nodeSelector` |
| tolerations | list | `[]` | Sets all pods' tolerations to node taints. Can be configured also with `global.tolerations` |
| affinity | object | `{}` | Sets all pods' affinities. Can be configured also with `global.affinity` |

## Common Errors

### Exporting Errors

If the `nr-ebpf-client` or `nr-ebpf-agent` container logs indicate that the scripts are failing to export data, ensure that Linux headers are installed on the host. Verify that the `nr-ebpf-agent` container logs indicate that the Linux header files were found and that the Stirling data tables were initialized. These logs should be written as the agent is booting up (towards the beginning of the output).

## Maintainers

* ramkrishankumarN
* kpattaswamy
* Philip-R-Beckwith
