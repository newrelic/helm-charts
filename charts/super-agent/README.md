[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# super-agent

Bootstraps New Relic' Super Agent

# Helm installation

You can install this chart using directly this Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade --install super-agent newrelic/super-agent -f your-custom-values.yaml
```

## Values managed globally

This chart implements the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

> **Warning**: Note that the flux chart is not maintained by New Relic and thus does not support the `common-library`. Everything under the
`flux2` belongs to the upstream chart and does not honor the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library).
>
> For a complete list of `values.yaml` of this chart you can refer to the [upstream chart's `values.yaml`](https://github.com/fluxcd-community/helm-charts/blob/flux2-2.10.2/charts/flux2/values.yaml).

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations`, `proxy` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

## Test custom agentTypes

In order to test custom agentTypes is possible to leverage `extraVolumeMounts` and `extraVolumes` once you have created the configMap in the namespace.

You can run the following commands to create in the newrelic namespace a configMap containing a dynamic agentType:
```bash
$ kubectl create configmap dynamic-agent --from-file=dynamic-agent-type=./local/values-dynamic-agent-type.yaml -n default
```

Then you can mount such agentType leveraging extra volumes in the values.yaml
```yaml
super-agent-deployment:
# [...]
  extraVolumeMounts:
    - name: dynamic
      mountPath: /etc/newrelic-super-agent/dynamic-agent-type.yaml
      subPath: dynamic-agent-type.yaml
      readOnly: true
  extraVolumes:
    - name: dynamic
      configMap:
        name: dynamic-agent
        items:
          - key: dynamic-agent-type
            path: dynamic-agent-type.yaml
```

## Chart particularities

> **TODO:** Here is where you should add particularities for this chart like what does the chart do with the privileged and
low data modes or any other quirk that it could have.

As of the creation of the chart, it has no particularities and this section can be removed safely.


## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| flux2 | object | See `values.yaml` | Values for the Flux chat. Ref.: https://github.com/fluxcd-community/helm-charts/blob/flux2-2.10.2/charts/flux2/values.yaml |
| flux2.clusterDomain | string | `"cluster.local"` | This is the domain name of the cluster. |
| flux2.enabled | bool | `true` | Enable or disable FluxCD installation. New Relic' Super Agent need Flux to work, but the user can use an already existing Flux deployment. With that use case, the use can disable Flux and use this chart to only install the CRs to deploy the Super Agent. |
| flux2.helmController | object | Enabled | Helm controller is a Kubernetes operator that allows to declaratively manage Helm chart releases with Kubernetes manifests. The Helm release is defined in a CR ([Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-resources)) named `HelmRelease` that the operator will reconcile on the apply, edit, or deletion of a `HelmRelease` resource.  New Relic' Super Agent will use this controller by creating `HelmRelease` CRs based in the configuration stored on OpAmp. This is the only controller that the Super Agent need for now, the other controllers are disabled by default.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. Take a look to the `values.yaml` to see how to enable other controllers. |
| flux2.installCRDs | bool | `true` | The installation of the CRDs is managed by the chart itself. |
| flux2.rbac | object | Enabled (See `values.yaml`) | Create RBAC rules for FluxCD is able to deploy all kind of workloads on the cluster. |
| flux2.sourceController | object | Enabled | Source controller provides a way to fetch artifacts to the rest of controllers. The source API (which reference [can be read here](https://fluxcd.io/flux/components/source/api/v1/)) is used by admins and various automated operators to offload the Git, OCO, and Helm repositories management. |
| flux2.watchAllNamespaces | bool | `false` | As we are using Flux as a tool from the super agent to release new workloads, we do not want Flux to listen to all CRs created on the whole cluster. If the user does not want to use Flux and is only using it because of the super agent, this is the way to go so the cluster has deployed all operators needed by the super agent. But if the user want to use Flux for other purposes besides the super agent, this toggle can be used to allow Flux to work on the whole cluster. |
| fullnameOverride | string | `""` | Override the full name of the release |
| nameOverride | string | `""` | Override the name of the chart |
| super-agent-deployment | object | See `values.yaml` | Values related to the super agent's Helm chart release. |
| super-agent-deployment.affinity | object | `{}` | Sets pod/node affinities. Can be configured also with `global.affinity` |
| super-agent-deployment.cleanupManagedResources | bool | `true` | Enable the cleanup of super-agent managed resources when the chart is uninstalled. If disabled, agents and/or agent configurations managed by the super-agent will not be deleted when the chart is uninstalled. |
| super-agent-deployment.cluster | string | `""` | Name of the Kubernetes cluster monitored. Can be configured also with `global.cluster`. |
| super-agent-deployment.config.opamp.auth.organizationId | string | `""` | Organization ID where fleets will live. |
| super-agent-deployment.config.opamp.auth.secret.client_id.base64 | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set client ID directly as base64. This options is mutually exclusive with `plain`. |
| super-agent-deployment.config.opamp.auth.secret.client_id.plain | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set client ID directly as plain text. This options is mutually exclusive with `base64`. |
| super-agent-deployment.config.opamp.auth.secret.client_id.secret_key | string | `client_id` | Key inside the secret containing the client ID. |
| super-agent-deployment.config.opamp.auth.secret.name | string | release name suffixed with "-auth" | Name auth' secret provided by the user. If the creation of this secret is set to `true`, this is the same the secret will have. |
| super-agent-deployment.config.opamp.auth.secret.private_key.base64_pem | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set private key directly as base64. This options is mutually exclusive with `plain_pem`. |
| super-agent-deployment.config.opamp.auth.secret.private_key.plain_pem | string | `nil` | In case `.config.auth.secret.create` is true, you can set these keys to set private key directly as plain text. This options is mutually exclusive with `base64_pem`. |
| super-agent-deployment.config.opamp.auth.secret.private_key.secret_key | string | `private_key` | Key inside the secret containing the private key. |
| super-agent-deployment.config.opamp.enabled | bool | `true` | Enables or disables the auth against fleet control. It implies to disable any fleet communication and running the agent in stand alone mode where only the agents specified on `.config.subAgents` will be launched. |
| super-agent-deployment.config.subAgents | string | `newrelic/io.opentelemetry.collector` (See `values.yaml`) | Values that the fleet is going to have in the deployment. If empty, chart will automatically add `newrelic/io.opentelemetry.collector` subagent. On the other hand, if populated the list of agent created is the one specified overwriting the default. |
| super-agent-deployment.config.superAgent | object | See `values.yaml` | Configuration for the Super Agent. |
| super-agent-deployment.config.superAgent.content | object | `{}` | Overrides the configuration that has been created automatically by the chart. This configuration here will be **MERGED** with the configuration specified above. If you need to have you own configuration, disabled the creation of this configMap and create your own. |
| super-agent-deployment.config.superAgent.create | bool | `true` | Set if the configMap is going to be created by this chart or the user will provide its own. |
| super-agent-deployment.containerSecurityContext | object | `{}` | Sets security context (at container level). Can be configured also with `global.containerSecurityContext` |
| super-agent-deployment.customAttributes | object | `{}` | TODO: Adds extra attributes to the cluster and all the metrics emitted to the backend. Can be configured also with `global.customAttributes` |
| super-agent-deployment.customSecretLicenseKey | string | `""` | In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey` |
| super-agent-deployment.customSecretName | string | `""` | In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName` |
| super-agent-deployment.dnsConfig | object | `{}` | Sets pod's dnsConfig. Can be configured also with `global.dnsConfig` |
| super-agent-deployment.enabled | bool | `true` | Enable the installation of the Super Agent. This an advanced/debug flag. It should be always be true unless you know what you are going. |
| super-agent-deployment.extraEnv | list | `[]` | Add user environment variables to the agent |
| super-agent-deployment.extraEnvFrom | list | `[]` | Add user environment from configMaps or secrets as variables to the agent |
| super-agent-deployment.extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| super-agent-deployment.extraVolumes | list | `[]` | Volumes to mount in the containers |
| super-agent-deployment.fedramp.enabled | bool | `false` | TODO: Enables FedRAMP. Can be configured also with `global.fedramp.enabled` |
| super-agent-deployment.hostNetwork | bool | `false` | Sets pod's hostNetwork. Can be configured also with `global.hostNetwork` |
| super-agent-deployment.image | object | See `values.yaml` | Image for the New Relic Super Agent |
| super-agent-deployment.image.pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| super-agent-deployment.labels | object | `{}` | Additional labels for chart objects. Can be configured also with `global.labels` |
| super-agent-deployment.licenseKey | string | `""` | This set this license key to use. Can be configured also with `global.licenseKey` |
| super-agent-deployment.nodeSelector | object | `{}` | Sets pod's node selector. Can be configured also with `global.nodeSelector` |
| super-agent-deployment.nrStaging | bool | `false` | Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging` |
| super-agent-deployment.podAnnotations | object | `{}` | Annotations to be added to all pods created by the integration. |
| super-agent-deployment.podLabels | object | `{}` | Additional labels for chart pods. Can be configured also with `global.podLabels` |
| super-agent-deployment.podSecurityContext | object | `{}` | Sets security context (at pod level). Can be configured also with `global.podSecurityContext` |
| super-agent-deployment.priorityClassName | string | `""` | Sets pod's priorityClassName. Can be configured also with `global.priorityClassName` |
| super-agent-deployment.proxy | string | `""` | TODO: Configures the integration to send all HTTP/HTTPS request through the proxy in that URL. The URL should have a standard format like `https://user:password@hostname:port`. Can be configured also with `global.proxy` |
| super-agent-deployment.rbac.create | bool | `true` | Whether the chart should automatically create the RBAC objects required to run. |
| super-agent-deployment.resources | object | `{}` | Resource limits to be added to all pods created by the integration. |
| super-agent-deployment.serviceAccount | object | See `values.yaml` | Settings controlling ServiceAccount creation. |
| super-agent-deployment.serviceAccount.create | bool | `true` | Whether the chart should automatically create the ServiceAccount objects required to run. |
| super-agent-deployment.tolerations | list | `[]` | Sets pod's tolerations to node taints. Can be configured also with `global.tolerations` |
| super-agent-deployment.verboseLog | bool | `false` | Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog` |

## Maintainers

* [alvarocabanas](https://github.com/alvarocabanas)
* [DavSanchez](https://github.com/DavSanchez)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [paologallinaharbur](https://github.com/paologallinaharbur)
* [rubenruizdegauna](https://github.com/rubenruizdegauna)
* [sigilioso](https://github.com/sigilioso)
