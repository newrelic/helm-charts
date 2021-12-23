# nri-kubernetes

![Version: 3.0.0](https://img.shields.io/badge/Version-3.0.0-informational?style=flat-square) ![AppVersion: 3.0.0](https://img.shields.io/badge/AppVersion-3.0.0-informational?style=flat-square)

A Helm chart to deploy the New Relic Kubernetes monitoring solution

**Homepage:** <https://hub.docker.com/r/newrelic/nri-kubernetes/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| alvarocabanas |  |  |
| carlossscastro |  |  |
| gsanchezgavier |  |  |
| kang-makes |  |  |
| paologallinaharbur |  |  |
| roobre |  |  |

## Source Code

* <https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-infrastructure>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| common.agentConfig.eventQueueDepth | int | `2000` |  |
| common.config.interval | string | `"15s"` |  |
| common.config.timeout | string | `"30s"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | string | `"node-role.kubernetes.io/control-plane"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | string | `"Exists"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[1].matchExpressions[0].key | string | `"node-role.kubernetes.io/controlplane"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[1].matchExpressions[0].operator | string | `"Exists"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[2].matchExpressions[0].key | string | `"node-role.kubernetes.io/etcd"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[2].matchExpressions[0].operator | string | `"Exists"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[3].matchExpressions[0].key | string | `"node-role.kubernetes.io/master"` |  |
| controlPlane.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[3].matchExpressions[0].operator | string | `"Exists"` |  |
| controlPlane.annotations | object | `{}` |  |
| controlPlane.config.apiServer.autodiscover[0].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.apiServer.autodiscover[0].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[0].endpoints[0].url | string | `"https://localhost:8443"` |  |
| controlPlane.config.apiServer.autodiscover[0].endpoints[1].url | string | `"http://localhost:8080"` |  |
| controlPlane.config.apiServer.autodiscover[0].matchNode | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[0].namespace | string | `"kube-system"` |  |
| controlPlane.config.apiServer.autodiscover[0].selector | string | `"tier=control-plane,component=kube-apiserver"` |  |
| controlPlane.config.apiServer.autodiscover[1].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.apiServer.autodiscover[1].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[1].endpoints[0].url | string | `"https://localhost:8443"` |  |
| controlPlane.config.apiServer.autodiscover[1].endpoints[1].url | string | `"http://localhost:8080"` |  |
| controlPlane.config.apiServer.autodiscover[1].matchNode | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[1].namespace | string | `"kube-system"` |  |
| controlPlane.config.apiServer.autodiscover[1].selector | string | `"k8s-app=kube-apiserver"` |  |
| controlPlane.config.apiServer.autodiscover[2].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.apiServer.autodiscover[2].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[2].endpoints[0].url | string | `"https://localhost:8443"` |  |
| controlPlane.config.apiServer.autodiscover[2].matchNode | bool | `true` |  |
| controlPlane.config.apiServer.autodiscover[2].namespace | string | `"kube-system"` |  |
| controlPlane.config.apiServer.autodiscover[2].selector | string | `"app=openshift-kube-apiserver,apiserver=true"` |  |
| controlPlane.config.apiServer.enabled | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[0].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.controllerManager.autodiscover[0].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[0].endpoints[0].url | string | `"https://localhost:10257"` |  |
| controlPlane.config.controllerManager.autodiscover[0].matchNode | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[0].namespace | string | `"kube-system"` |  |
| controlPlane.config.controllerManager.autodiscover[0].selector | string | `"tier=control-plane,component=kube-controller-manager"` |  |
| controlPlane.config.controllerManager.autodiscover[1].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.controllerManager.autodiscover[1].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[1].endpoints[0].url | string | `"https://localhost:10257"` |  |
| controlPlane.config.controllerManager.autodiscover[1].matchNode | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[1].namespace | string | `"kube-system"` |  |
| controlPlane.config.controllerManager.autodiscover[1].selector | string | `"k8s-app=kube-controller-manager"` |  |
| controlPlane.config.controllerManager.autodiscover[2].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.controllerManager.autodiscover[2].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[2].endpoints[0].url | string | `"https://localhost:10257"` |  |
| controlPlane.config.controllerManager.autodiscover[2].matchNode | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[2].namespace | string | `"kube-system"` |  |
| controlPlane.config.controllerManager.autodiscover[2].selector | string | `"app=kube-controller-manager,kube-controller-manager=true"` |  |
| controlPlane.config.controllerManager.autodiscover[3].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.controllerManager.autodiscover[3].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[3].endpoints[0].url | string | `"https://localhost:10257"` |  |
| controlPlane.config.controllerManager.autodiscover[3].matchNode | bool | `true` |  |
| controlPlane.config.controllerManager.autodiscover[3].namespace | string | `"kube-system"` |  |
| controlPlane.config.controllerManager.autodiscover[3].selector | string | `"app=controller-manager,controller-manager=true"` |  |
| controlPlane.config.controllerManager.enabled | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[0].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.etcd.autodiscover[0].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[0].endpoints[0].url | string | `"https://localhost:4001"` |  |
| controlPlane.config.etcd.autodiscover[0].endpoints[1].url | string | `"http://localhost:2381"` |  |
| controlPlane.config.etcd.autodiscover[0].matchNode | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[0].namespace | string | `"kube-system"` |  |
| controlPlane.config.etcd.autodiscover[0].selector | string | `"tier=control-plane,component=etcd"` |  |
| controlPlane.config.etcd.autodiscover[1].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.etcd.autodiscover[1].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[1].endpoints[0].url | string | `"https://localhost:4001"` |  |
| controlPlane.config.etcd.autodiscover[1].matchNode | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[1].namespace | string | `"kube-system"` |  |
| controlPlane.config.etcd.autodiscover[1].selector | string | `"k8s-app=etcd-manager-main"` |  |
| controlPlane.config.etcd.autodiscover[2].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.etcd.autodiscover[2].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[2].endpoints[0].url | string | `"https://localhost:4001"` |  |
| controlPlane.config.etcd.autodiscover[2].matchNode | bool | `true` |  |
| controlPlane.config.etcd.autodiscover[2].namespace | string | `"kube-system"` |  |
| controlPlane.config.etcd.autodiscover[2].selector | string | `"k8s-app=etcd"` |  |
| controlPlane.config.etcd.enabled | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[0].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.scheduler.autodiscover[0].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[0].endpoints[0].url | string | `"https://localhost:10259"` |  |
| controlPlane.config.scheduler.autodiscover[0].matchNode | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[0].namespace | string | `"kube-system"` |  |
| controlPlane.config.scheduler.autodiscover[0].selector | string | `"tier=control-plane,component=kube-scheduler"` |  |
| controlPlane.config.scheduler.autodiscover[1].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.scheduler.autodiscover[1].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[1].endpoints[0].url | string | `"https://localhost:10259"` |  |
| controlPlane.config.scheduler.autodiscover[1].matchNode | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[1].namespace | string | `"kube-system"` |  |
| controlPlane.config.scheduler.autodiscover[1].selector | string | `"k8s-app=kube-scheduler"` |  |
| controlPlane.config.scheduler.autodiscover[2].endpoints[0].auth.type | string | `"bearer"` |  |
| controlPlane.config.scheduler.autodiscover[2].endpoints[0].insecureSkipVerify | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[2].endpoints[0].url | string | `"https://localhost:10259"` |  |
| controlPlane.config.scheduler.autodiscover[2].matchNode | bool | `true` |  |
| controlPlane.config.scheduler.autodiscover[2].namespace | string | `"kube-system"` |  |
| controlPlane.config.scheduler.autodiscover[2].selector | string | `"app=openshift-kube-scheduler,scheduler=true"` |  |
| controlPlane.config.scheduler.enabled | bool | `true` |  |
| controlPlane.enabled | bool | `true` |  |
| controlPlane.extraEnv | list | `[]` |  |
| controlPlane.extraEnvFrom | list | `[]` |  |
| controlPlane.extraVolumes | list | `[]` |  |
| controlPlane.kind | string | `"DaemonSet"` |  |
| controlPlane.nodeSelector | object | `{}` |  |
| controlPlane.resources.limits.memory | string | `"300M"` |  |
| controlPlane.resources.requests.cpu | string | `"100m"` |  |
| controlPlane.resources.requests.memory | string | `"150M"` |  |
| controlPlane.tolerations[0].effect | string | `"NoSchedule"` |  |
| controlPlane.tolerations[0].operator | string | `"Exists"` |  |
| controlPlane.tolerations[1].effect | string | `"NoExecute"` |  |
| controlPlane.tolerations[1].operator | string | `"Exists"` |  |
| customAttributes.clusterName | string | `"$(CLUSTER_NAME)"` |  |
| fullnameOverride | string | `""` |  |
| images.agent.pullPolicy | string | `"Never"` |  |
| images.agent.registry | string | `"docker.io"` |  |
| images.agent.repository | string | `"newrelic/infrastructure-bundle"` |  |
| images.agent.tag | string | `"dev"` |  |
| images.forwarder.pullPolicy | string | `"IfNotPresent"` |  |
| images.forwarder.registry | string | `"docker.io"` |  |
| images.forwarder.repository | string | `"newrelic/k8s-events-forwarder"` |  |
| images.forwarder.tag | string | `"1.20.5"` |  |
| images.pullSecrets | list | `[]` |  |
| images.scraper.pullPolicy | string | `"IfNotPresent"` |  |
| images.scraper.registry | string | `"docker.io"` |  |
| images.scraper.repository | string | `"newrelic/nri-kubernetes"` |  |
| images.scraper.tag | string | `"0.1.2"` |  |
| integrations_config | list | `[]` |  |
| ksm.affinity.nodeAffinity | list | `[]` |  |
| ksm.affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchLabels."app.kubernetes.io/name" | string | `"kube-state-metrics"` |  |
| ksm.affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey | string | `"kubernetes.io/hostname"` |  |
| ksm.affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight | int | `100` |  |
| ksm.annotations | object | `{}` |  |
| ksm.config | object | `{}` |  |
| ksm.enabled | bool | `true` |  |
| ksm.extraEnv | list | `[]` |  |
| ksm.extraEnvFrom | list | `[]` |  |
| ksm.extraVolumeMounts | list | `[]` |  |
| ksm.extraVolumes | list | `[]` |  |
| ksm.nodeSelector | object | `{}` |  |
| ksm.resources.limits.memory | string | `"300M"` |  |
| ksm.resources.requests.cpu | string | `"100m"` |  |
| ksm.resources.requests.memory | string | `"150M"` |  |
| ksm.tolerations[0].effect | string | `"NoSchedule"` |  |
| ksm.tolerations[0].operator | string | `"Exists"` |  |
| ksm.tolerations[1].effect | string | `"NoExecute"` |  |
| ksm.tolerations[1].operator | string | `"Exists"` |  |
| kubelet.affinity.nodeAffinity | list | `[]` |  |
| kubelet.annotations | object | `{}` |  |
| kubelet.config | object | `{}` |  |
| kubelet.enabled | bool | `true` |  |
| kubelet.extraEnv | list | `[]` |  |
| kubelet.extraEnvFrom | list | `[]` |  |
| kubelet.extraVolumes | list | `[]` |  |
| kubelet.nodeSelector | object | `{}` |  |
| kubelet.resources.limits.memory | string | `"300M"` |  |
| kubelet.resources.requests.cpu | string | `"100m"` |  |
| kubelet.resources.requests.memory | string | `"150M"` |  |
| kubelet.tolerations[0].effect | string | `"NoSchedule"` |  |
| kubelet.tolerations[0].operator | string | `"Exists"` |  |
| kubelet.tolerations[1].effect | string | `"NoExecute"` |  |
| kubelet.tolerations[1].operator | string | `"Exists"` |  |
| nameOverride | string | `""` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| prefixDisplayNameWithCluster | bool | `false` |  |
| priorityClassName | string | `""` |  |
| privileged | bool | `true` |  |
| rbac.create | bool | `true` |  |
| rbac.pspEnabled | bool | `false` |  |
| runAsGroup | int | `2000` |  |
| runAsUser | int | `1000` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| updateStrategy.rollingUpdate.maxUnavailable | int | `1` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |
| useNodeNameAsDisplayName | bool | `true` |  |
| verboseLog | bool | `false` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
