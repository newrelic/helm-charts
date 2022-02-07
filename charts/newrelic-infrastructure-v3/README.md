[![New Relic Experimental header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Experimental.png)](https://opensource.newrelic.com/oss-category/#new-relic-experimental)

# newrelic-infrastructure-v3

![Version: 3.0.16](https://img.shields.io/badge/Version-3.0.16-informational?style=flat-square) ![AppVersion: 3.0.0](https://img.shields.io/badge/AppVersion-3.0.0-informational?style=flat-square)

A Helm chart to deploy the New Relic Kubernetes monitoring solution

**Homepage:** <https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/get-started/introduction-kubernetes-integration/>

## Source Code

* <https://github.com/newrelic/nri-kubernetes/>
* <https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infrastructure>

## Requirements

Kubernetes: `>=1.16.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| common | object | See `values.yaml` | Config that applies to all instances of the solution: kubelet, ksm, control plane and sidecars. |
| common.agentConfig | object | `{}` | Config for the Infrastructure agent. Will be used by the forwarder sidecars and the agent running integrations. See: https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/ |
| common.config.interval | duration | `15s` if `lowDataMode == false`, `30s` otherwise. | Intervals larger than 40s are not supported and will cause the NR UI to not behave properly. Any non-nil value will override the `lowDataMode` default. |
| controlPlane | object | See `values.yaml` | Configuration for the control plane scraper. |
| controlPlane.affinity | object | Deployed only in master nodes. | Affinity for the control plane DaemonSet. |
| controlPlane.config.apiServer | object | Common settings for most K8s distributions. | API Server monitoring configuration |
| controlPlane.config.apiServer.enabled | bool | `true` | Enable API Server monitoring |
| controlPlane.config.controllerManager | object | Common settings for most K8s distributions. | Controller manager monitoring configuration |
| controlPlane.config.controllerManager.enabled | bool | `true` | Enable controller manager monitoring. |
| controlPlane.config.etcd | object | Common settings for most K8s distributions. | ETCD monitoring configuration |
| controlPlane.config.etcd.enabled | bool | `true` | Enable etcd monitoring. Might require manual configuration in some environments. |
| controlPlane.config.retries | int | `3` | Number of retries after timeout expired |
| controlPlane.config.scheduler | object | Common settings for most K8s distributions. | Scheduler monitoring configuration |
| controlPlane.config.scheduler.enabled | bool | `true` | Enable scheduler monitoring. |
| controlPlane.config.timeout | string | `"10s"` | Timeout for the Kubernetes APIs contacted by the integration |
| controlPlane.enabled | bool | `true` | Deploy control plane monitoring component. |
| controlPlane.kind | string | `"DaemonSet"` | How to deploy the control plane scraper. If autodiscovery is in use, it should be `DaemonSet`. Advanced users using static endpoints set this to `Deployment` to avoid reporting metrics twice. |
| controlPlane.unprivilegedHostNetwork | bool | `false` | Run Control Plane scraper with `hostNetwork` even if `privileged` is set to false. `hostNetwork` is required for most control plane configurations, as they only accept connections from localhost. This is meant to be used with DaemonSets over on-premise clusters. |
| customAttributes | object | `{}` | Custom attributes to be added to the data reported by all integrations reporting in the cluster. |
| images | object | See `values.yaml` | Images used by the chart for the integration and agents. |
| images.agent.repository | string | `"newrelic/infrastructure-bundle"` | Image for the agent and integrations bundle. |
| images.agent.tag | string | `"2.8.2"` | Tag for the agent and integrations bundle. |
| images.forwarder.repository | string | `"newrelic/k8s-events-forwarder"` | Image for the agent sidecar. |
| images.forwarder.tag | string | `"1.23.0"` | Tag for the agent sidecar. |
| images.integration.repository | string | `"newrelic/nri-kubernetes"` | Image for the kubernetes integration. |
| images.integration.tag | string | `"3.0.0"` | Tag for the kubernetes integration. |
| integrations | object | `{}` | Config files for other New Relic integrations that should run in this cluster. |
| ksm | object | See `values.yaml` | Configuration for the Deployment that collects state metrics from KSM (kube-state-metrics). |
| ksm.config.retries | int | `3` | Number of retries after timeout expired |
| ksm.config.timeout | string | `"10s"` | Timeout for the ksm API contacted by the integration |
| ksm.enabled | bool | `true` | Enable cluster state monitoring. Advanced users only. Setting this to `false` is not supported and will break the New Relic experience. |
| ksm.resources | object | 100m/150M -/850M | Resources for the KSM scraper pod. Keep in mind that sharding is not supported at the moment, so memory usage for this component ramps up quickly on large clusters. |
| kubelet | object | See `values.yaml` | Configuration for the DaemonSet that collects metrics from the Kubelet. |
| kubelet.config.retries | int | `3` | Number of retries after timeout expired |
| kubelet.config.timeout | string | `"10s"` | Timeout for the kubelet APIs contacted by the integration |
| kubelet.enabled | bool | `true` | Enable kubelet monitoring. Advanced users only. Setting this to `false` is not supported and will break the New Relic experience. |
| lowDataMode | bool | `false` | Send less data by incrementing the interval from `15s` (the default when `lowDataMode` is `false` or `nil`) to `30s`. Non-nil values of `common.config.interval` will override this value. |
| podAnnotations | object | `{}` | Annotations to be added to all pods created by the integration. |
| podLabels | object | `{}` | Labels to be added to all pods created by the integration. |
| priorityClassName | string | `""` | Pod scheduling priority Ref: https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/ |
| privileged | bool | `true` | Run the integration with full access to the host filesystem and network. Running in this mode allows reporting fine-grained cpu, memory, process and network metrics for your nodes. Additionally, it allows control plane monitoring, which requires hostNetwork to work. |
| rbac | object | `{"create":true,"pspEnabled":false}` | Settings controlling RBAC objects creation. |
| rbac.create | bool | `true` | Whether the chart should automatically create the RBAC objects required to run. |
| rbac.pspEnabled | bool | `false` | Whether the chart should create Pod Security Policy objects. |
| securityContext | object | See `values.yaml` | Security context used in all the containers of the pods When `privileged == true`, the Kubelet scraper will run as root and ignore these settings. |
| serviceAccount | object | See `values.yaml` | Settings controlling ServiceAccount creation. |
| serviceAccount.create | bool | `true` | Whether the chart should automatically create the ServiceAccount objects required to run. |
| updateStrategy | object | See `values.yaml` | Update strategy for the DaemonSets deployed. |
| verboseLog | bool | `false` | Enable verbose logging for all components. |

## Maintainers

* [alvarocabanas](https://github.com/alvarocabanas)
* [carlossscastro](https://github.com/carlossscastro)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [kang-makes](https://github.com/kang-makes)
* [paologallinaharbur](https://github.com/paologallinaharbur)
* [roobre](https://github.com/roobre)

## Past Contributors

Previous iterations of this chart started as a community project in the [stable Helm chart repository](github.com/helm/charts/). New Relic is very thankful for all the 15+ community members that contributed and helped maintain the chart there over the years:

* coreypobrien
* sstarcher
* jmccarty3
* slayerjain
* ryanhope2
* rk295
* michaelajr
* isindir
* idirouhab
* ismferd
* enver
* diclophis
* jeffdesc
* costimuraru
* verwilst
* ezelenka
