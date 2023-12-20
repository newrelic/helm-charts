[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# super-agent-deployment

![Version: 0.0.5-beta](https://img.shields.io/badge/Version-0.0.5--beta-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: nightly](https://img.shields.io/badge/AppVersion-nightly-informational?style=flat-square)

A Helm chart to install New Relic Super agent on Kubernetes

# Helm installation

You can install this chart using directly this Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade --install newrelic/super-agent-deployment -f your-custom-values.yaml
```

## Values managed globally

This chart implements the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations`, `proxy` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

## Chart particularities

> **TODO:** Here is where you should add particularities for this chart like what does the chart do with the privileged and
low data modes or any other quirk that it could have.

At the point of the creation of the chart, it has no particularities and this section can be removed safely.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Sets pod/node affinities. Can be configured also with `global.affinity` |
| cluster | string | `""` | TODO: Name of the Kubernetes cluster monitored. Can be configured also with `global.cluster`. |
| config.subAgents | object | See `values.yaml` for examples | Values that the fleet is going to have in the deployment. |
| config.superAgent | object | See `values.yaml` | Configuration for the Super Agent. |
| config.superAgent.content | string | See `values.yaml` for examples | Here you can set New Relic' Super Agent configuration. |
| config.superAgent.create | bool | `true` | Set if the configMap is going to be created by this chart or the user will provide its own. |
| config.superAgent.key | string | `""` | The key in the configMap that has the configuration for the Super Agent. |
| config.superAgent.name | string | `""` | The name the configMap is going to have. If create is set to false, the name of an existing configMap that will be used to config the Super Agent. |
| containerSecurityContext | object | `{}` | Sets security context (at container level). Can be configured also with `global.containerSecurityContext` |
| customAttributes | object | `{}` | TODO: Adds extra attributes to the cluster and all the metrics emitted to the backend. Can be configured also with `global.customAttributes` |
| customSecretLicenseKey | string | `""` | TODO: In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | TODO: In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| extraEnv | list | `[]` | Add user environment variables to the agent |
| extraEnvFrom | list | `[]` | Add user environment from configMaps or secrets as variables to the agent |
| extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| extraVolumes | list | `[]` | Volumes to mount in the containers |
| fedramp.enabled | bool | `false` | TODO: Enables FedRAMP. Can be configured also with `global.fedramp.enabled` |
| fullnameOverride | string | `""` | Override the full name of the release |
| hostNetwork | bool | `false` | Sets pod's hostNetwork. Can be configured also with `global.hostNetwork` |
| image | object | See `values.yaml` | Image for the New Relic Super Agent |
| image.pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| labels | object | `{}` | Additional labels for chart objects. Can be configured also with `global.labels` |
| licenseKey | string | `""` | TODO: This set this license key to use. Can be configured also with `global.licenseKey` |
| nameOverride | string | `""` | Override the name of the chart |
| nodeSelector | object | `{}` | Sets pod's node selector. Can be configured also with `global.nodeSelector` |
| nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| podAnnotations | object | `{}` | Annotations to be added to all pods created by the integration. |
| podLabels | object | `{}` | Additional labels for chart pods. Can be configured also with `global.podLabels` |
| podSecurityContext | object | `{}` | Sets security context (at pod level). Can be configured also with `global.podSecurityContext` |
| priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| proxy | string | `""` | TODO: Configures the integration to send all HTTP/HTTPS request through the proxy in that URL. The URL should have a standard format like `https://user:password@hostname:port`. Can be configured also with `global.proxy` |
| rbac.create | bool | `true` | Whether the chart should automatically create the RBAC objects required to run. |
| resources | object | `{}` | Resource limits to be added to all pods created by the integration. |
| serviceAccount | object | See `values.yaml` | Settings controlling ServiceAccount creation. |
| serviceAccount.create | bool | `true` | Whether the chart should automatically create the ServiceAccount objects required to run. |
| tolerations | list | `[]` | Sets pod's tolerations to node taints. Can be configured also with `global.tolerations` |
| verboseLog | bool | `false` | TODO: Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog` |

## Maintainers

* [sigilioso](https://github.com/sigilioso)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [kang-makes](https://github.com/kang-makes)
* [marcsanmi](https://github.com/marcsanmi)
* [paologallinaharbur](https://github.com/paologallinaharbur)
