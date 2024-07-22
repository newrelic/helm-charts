[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# ebpf-agent

A Helm chart to monitor a Kubernetes Cluster using the eBPF agent.

# Helm installation

Download and Update config [here](https://github.com/newrelic/helm-charts/tree/master/charts/ebpf-agent/values.yaml#L1-L4) to add a cluster name, and New Relic Ingest - License key

Example:
```
licenseKey: "EXAMPLEINGESTLICENSEKEY345878592NRALL"
cluster: "SampleApp"
```

You can install this chart directly using this Helm repository:

```shell
# Use Options 1-3 to easily deploy the helm chart.
# Option 1:
helm install ebpf-agent-chart \ 
  --set licenseKey=<License Key> \
  --set cluster=<Name of Kubernetes cluster> \
  --create-namespace --namespace newrelic \
  --generate-name

# Option 2:
helm install ebpf-agent -f your-custom-values.yaml -n newrelic --create-namespace ebpf-agent-chart

# Option 3:
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade ebpf-agent newrelic/ebpf-agent -f your-custom-values.yaml -n newrelic --create-namespace --install
```

## Confirm installation
### Watch pods spin up:

```
kubectl get pods -n newrelic --watch
```

### Check the logs of the eBPF agent pod that spins up:
```
kubectl logs <ebpf-pod-name> -n newrelic
```

### Check the logs of the OpenteTemetry collector pod that spins up:
```
kubectl logs <otel-pod-name> -n newrelic
```

### Confirm data coming through in New Relic
You should see data reporting into New Relic within a couple of seconds to the `Metric` and `Span` tables.
```
FROM Metric SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```
```
FROM Span SELECT * WHERE k8s.cluster.name='<CLUSTER_NAME>'
```

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
| cluster | string | `""` | Name of the Kubernetes cluster monitored. Mandatory. Can be configured also with `global.cluster` |
| ebpfAgent.image.pullPolicy | string | `"IfNotPresent"` | The pull policy is defaulted to IfNotPresent, which skips pulling an image if it already exists. If pullPolicy is defined without a specific value, it is also set to Always. |
| ebpfAgent.image.repository | string | `"us-west1-docker.pkg.dev/pl-dev-infra/nr-ebpf-agent-lp/ebpf-agent"` | eBPF agent image to be deployed. |
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
| labels | object | `{}` | Additional labels for chart objects |
| licenseKey | string | `""` | This set this license key to use. Can be configured also with `global.licenseKey` |
| nodeSelector | object | `{}` | Sets all pods' node selector. Can be configured also with `global.nodeSelector` |
| nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| podLabels | object | `{}` | Additional labels for chart pods |
| tolerations | list | `[]` | Sets all pods' tolerations to node taints. Can be configured also with `global.tolerations` |

## Common Errors

### Exporting Errors

If the `nr-ebpf-client` or `nr-ebpf-agent` container logs indicate that the scripts are failing to export data, ensure that Linux headers are installed on the host. Verify that the `nr-ebpf-agent` container logs indicate that the Linux header files were found and that the Stirling data tables were initialized. These logs should be written as the agent is booting up (towards the beginning of the output).

## Maintainers
* [ramkrishankumarN](https://github.com/ramkrishankumarN)
* [kpattaswamy](https://github.com/kpattaswamy)
* [benkilimnik](https://github.com/benkilimnik)
