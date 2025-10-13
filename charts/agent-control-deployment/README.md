[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# agent-control-deployment

A Helm chart to install New Relic Agent Control on Kubernetes

# Helm installation

This chart is not intended to be installed on its own. Instead, it is designed to be installed as part of the [agent-control](https://github.com/newrelic/helm-charts/tree/master/charts/agent-control) chart.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Sets pod/node affinities. Can be configured also with `global.affinity` |
| agentsConfig | object | `{}` (See `values.yaml`) | List of managed agents configs. The key represents the name of the agent that should match the one specified in .config.agents. |
| cluster | string | `""` | Name of the Kubernetes cluster monitored. Can be configured also with `global.cluster`. |
| config | object | See `values.yaml` | AgentControl config options used to generate the configFile passed to the binary. You can overwrite the configFile generated with a raw one via config.override |
| config.acRemoteUpdate | bool | "true" | enables or disables remote update from Fleet Control for the agent-control-deployment chart |
| config.agents | string | `{}` (See `values.yaml`) | List of managed agents that will be deployed. The key represents the name of the agent that should used when defining its configuration. |
| config.allowedChartRepositoryUrl | list | `[]`(Only newrelic chart repositories allowed: ["https://helm-charts.newrelic.com","https://newrelic.github.io/<>"]) | List of allowed chart repository URLs. The Agent Control will only allow to deploy agents from these repositories. |
| config.cdReleaseName | string | agent-control-cd | The name of the release for the CD chart. |
| config.cdRemoteUpdate | bool | "true" | enables or disables remote update from Fleet Control for the agent-control-cd chart |
| config.fleet_control.enabled | bool | `true` | Enables or disables the auth against fleet control. It implies to disable any fleet communication and running the agent in stand alone mode where only the agents specified on `.config.subAgents` will be launched. |
| config.fleet_control.fleet_id | string | `""` | Specify a fleet_id to automatically connect the Agent Control to an existing fleet. |
| config.log | string | `{}` (See `values.yaml`) | Log configuration. The log level can be overwritten as well via verboseLog |
| config.override | object | `{}` | Overrides the configuration that has been created automatically by the chart. This configuration here will be **MERGED** with the configuration specified above. |
| config.status_server | object | See `values.yaml` | Set the status server port |
| containerSecurityContext | object | `{}` | Sets security context (at container level). Can be configured also with `global.containerSecurityContext` |
| customSecretLicenseKey | string | `""` | In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| customSecretName | string | `""` | In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| extraEnv | list | `[]` | Add user environment variables to the agent |
| extraEnvFrom | list | `[]` | Add user environment from configMaps or secrets as variables to the agent |
| extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| extraVolumes | list | `[]` | Volumes to mount in the containers |
| hostNetwork | bool | `false` | Sets pod's hostNetwork. Can be configured also with `global.hostNetwork` |
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
| systemIdentity | object | See `values.yaml` | Configuration for the system identity registration process. These options provides the required data to run the pre-install job that creates the system identitythat is used when communicating via OpAMP. System identity registration is executed only once. Subsequent upgrades will not attempt to create the identity again. Therefore, `Helm Upgrade` works even though the identityClientSecret or the identityClientAuthToken are expired. |
| systemIdentity.create | bool | `true` | Set it to false to disable the registration of a new system identity. Set this to `false` to configure a pre-existing system identity via secret. The secret should be already created in the namespace having as keys "CLIENT_ID" and "private_key" of the identity to leverage. |
| systemIdentity.extraVolumeMounts | list | `[]` | Defines where, in the systemIdentity job, to mount volumes specified with `extraVolumes` |
| systemIdentity.extraVolumes | list | `[]` | Volumes to mount in the systemIdentity job |
| systemIdentity.organizationId | string | `""` | Organization ID used to create the system identity. |
| systemIdentity.parentIdentity | object | `{"authToken":"","clientId":"","clientSecret":"","fromSecret":""}` | Configuration for the parent identity You can either authenticate via ClientId/ClientSecret or pass directly an `AuthToken` and manage locally the authentication. The authToken can be retrieve via the cli command "newrelic-auth-cli authenticate ...". |
| systemIdentity.parentIdentity.authToken | string | `""` | Identity auth token. This option takes precedence over secret and skips authentication. |
| systemIdentity.parentIdentity.clientId | string | `""` | Identity clientId to use. |
| systemIdentity.parentIdentity.clientSecret | string | `""` | Identity clientSecret to use. |
| systemIdentity.parentIdentity.fromSecret | string | `""` | In case you don't want to have the clientId, the clientSecret and the clientAuthToken in your values, you can point to a secret to get the data from there. The secret data is mounted in the job via environment variables to generate the system identity. |
| systemIdentity.secretName | string | `nil` | if create is set to false a secret having this name is expected in the AC namespace |
| tolerations | list | `[]` | Sets pod's tolerations to node taints. Can be configured also with `global.tolerations` |
| verboseLog | bool | `false` | Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog`. If you need to change the logs to trace or change more complex options, please refer to config.log |

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
