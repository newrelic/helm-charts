[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# agent-control-deployment

A Helm chart to install New Relic Agent Control on Kubernetes

# Helm installation

This chart is not intended to be installed on its own. Instead, it is designed to be installed as part of the [agent-control](https://github.com/newrelic/helm-charts/tree/master/charts/agent-control) chart.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| acRemoteUpdate | bool | "true" | enables or disables remote update from Fleet Control for the agent-control-deployment chart |
| affinity | object | `{}` | Sets pod/node affinities. Can be configured also with `global.affinity` |
| cdRemoteUpdate | bool | "true" | enables or disables remote update from Fleet Control for the agent-control-cd chart |
| cluster | string | `""` | Name of the Kubernetes cluster monitored. Can be configured also with `global.cluster`. |
| config | object | See `values.yaml` | Config for agent control used to generate the file passed via configMap.  You can overwrite the generated config with the key config.agentControl.content |
| config.agentControl | object | See `values.yaml` | Configuration for the Agent Control. |
| config.agentControl.content | object | `{}` | Overrides the configuration that has been created automatically by the chart. This configuration here will be **MERGED** with the configuration specified above. If you need to have you own configuration, disabled the creation of this configMap and create your own. |
| config.agentControl.create | bool | `true` | Set if the configMap is going to be created by this chart or the user will provide its own. |
| config.allowedChartRepositoryUrl | list | `[]`(Only newrelic chart repositories allowed: ["https://helm-charts.newrelic.com","https://newrelic.github.io/<>"]) | List of allowed chart repository URLs. The Agent Control will only allow to deploy agents from these repositories. |
| config.fleet_control.auth.organizationId | string | `""` | Organization ID where fleets will live. |
| config.fleet_control.auth.secret.client_id.base64 | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set client ID directly as base64 if you want to skip its creation. This options is mutually exclusive with `plain`. |
| config.fleet_control.auth.secret.client_id.plain | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set client ID directly as plain text if you want to skip its creation. This options is mutually exclusive with `base64`. |
| config.fleet_control.auth.secret.name | string | release name suffixed with "-auth" | Name auth' secret provided by the user. If the creation of this secret is set to `true`, this is the same the secret will have. |
| config.fleet_control.auth.secret.private_key.base64_pem | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set private key directly as base64 if you want to skip its creation. This options is mutually exclusive with `plain_pem`. |
| config.fleet_control.auth.secret.private_key.plain_pem | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set private key directly as plain text if you want to skip its creation. This options is mutually exclusive with `base64_pem`. |
| config.fleet_control.enabled | bool | `true` | Enables or disables the auth against fleet control. It implies to disable any fleet communication and running the agent in stand alone mode where only the agents specified on `.config.subAgents` will be launched. |
| config.fleet_control.fleet_id | string | `""` | Specify a fleet_id to automatically connect the Agent Control to an existing fleet. |
| config.status_server.port | int | See `values.yaml` | Set the status server port |
| config.subAgents | string | `{}` (See `values.yaml`) | List of managed agents that will be deployed. The key represents the name of the agent and the value holds the configuration. |
| containerSecurityContext | object | `{}` | Sets security context (at container level). Can be configured also with `global.containerSecurityContext` |
| customIdentitySecretName | string | `""` | In case you don't want to have the clientId and clientSecret/clientAuthToken in your values, this allows you to point to a user created secret to get the key from there. The secret is mounted in the job and used to generate the system identity. |
| customSecretLicenseKey | string | `""` | In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| extraEnv | list | `[]` | Add user environment variables to the agent |
| extraEnvFrom | list | `[]` | Add user environment from configMaps or secrets as variables to the agent |
| extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| extraVolumes | list | `[]` | Volumes to mount in the containers |
| hostNetwork | bool | `false` | Sets pod's hostNetwork. Can be configured also with `global.hostNetwork` |
| identityClientAuthToken | string | `""` | Identity auth token. This option takes precedence over identityClientSecret and skips authentication. |
| identityClientId | string | `""` | Identity client_id to use. |
| identityClientSecret | string | `""` | Identity client_secret to use. |
| image | object | See `values.yaml` | Image for the New Relic Agent Control |
| image.pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| labels | object | `{}` | Additional labels for chart objects. Can be configured also with `global.labels` |
| licenseKey | string | `""` | This set this license key to use. Can be configured also with `global.licenseKey` |
| nameOverride | string | See `values.yaml` | Override the name of the chart used to template resource names. |
| nodeSelector | object | `{}` | Sets pod's node selector. Can be configured also with `global.nodeSelector` |
| nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| podAnnotations | object | `{}` | Annotations to be added to all pods created by the integration. |
| podLabels | object | `{}` | Additional labels for chart pods. Can be configured also with `global.podLabels` |
| podSecurityContext | object | `{}` | Sets security context (at pod level). Can be configured also with `global.podSecurityContext` |
| priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| proxy | string | `nil` | proxy configuration. It is propagated to both the system identity creation job, and to the agent control instance |
| rbac.create | bool | `true` | Whether the chart should automatically create the RBAC objects required to run. |
| resources | object | `{}` | Resource limits to be added to all pods created by the integration. |
| serviceAccount | object | See `values.yaml` | Settings controlling ServiceAccount creation. |
| serviceAccount.create | bool | `true` | Whether the chart should automatically create the ServiceAccount objects required to run. |
| subAgentsNamespace | string | "newrelic" | Namespace where the sub-agents will be deployed. |
| systemIdentityRegistration | object | See `values.yaml` | Image for the system identity registration process |
| systemIdentityRegistration.extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| systemIdentityRegistration.extraVolumes | list | `[]` | Volumes to mount in the containers |
| tolerations | list | `[]` | Sets pod's tolerations to node taints. Can be configured also with `global.tolerations` |
| verboseLog | bool | `false` | Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog` |

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
