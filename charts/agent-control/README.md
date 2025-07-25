[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# agent-control

Bootstraps New Relic' Agent Control

# Helm installation

You can install this chart using directly this Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade --install agent-control newrelic/agent-control -f your-custom-values.yaml
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

## Flux Integration

Agent Control leverages [Flux](https://github.com/fluxcd/flux2) custom resources to automate the deployment of New Relic agents. This chart includes Flux as a dependency by default, eliminating the need for separate installation.

### Using an Existing Flux Installation

To use an existing Flux setup, disable the default installation by setting `flux2.enabled` to `false` in your values. Ensure your existing Flux installation meets the following requirements:

- Agent control is compatible with **Flux Versions**: 2.3.x, 2.4.x, or 2.5.x.
- **CRDs Required**:
  - `source.toolkit.fluxcd.io/v1` for HelmRepository
  - `helm.toolkit.fluxcd.io/v2` for HelmRelease
- **Namespace Access**: Must be configured to watch resources in the `newrelic` namespace, or the namespace where Agent Control is deployed.

## Test custom agentTypes

In order to test custom agentTypes is possible to leverage `extraVolumeMounts` and `extraVolumes` once you have created the configMap in the namespace.

You can run the following commands to create in the newrelic namespace a configMap containing a dynamic agentType:
```bash
$ kubectl create configmap dynamic-agent --from-file=dynamic-agent-type=./local/values-dynamic-agent-type.yaml -n <your-namespace>
```

Then you can mount such agentType leveraging extra volumes in the values.yaml
```yaml
agent-control-deployment:
# [...]
  extraVolumeMounts:
- name: dynamic
  mountPath: /etc/newrelic-agent-control/dynamic-agent-types
  readOnly: true
  extraVolumes:
- name: dynamic
  configMap:
name: dynamic-agent
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent-control-deployment | object | See `values.yaml` | Values for the agent-control-deployment chart. Ref.: https://github.com/newrelic/helm-charts/blob/master/charts/agent-control-deployment/values.yaml |
| agent-control-deployment.enabled | bool | `true` | Enable the installation of the Agent Control. |
| agent-control-deployment.subAgentsNamespace | string | "newrelic" | Namespace where the sub-agents will be deployed. |
| flux2 | object | See `values.yaml` | Values for the Flux chart. Ref.: https://github.com/fluxcd-community/helm-charts/blob/flux2-2.10.2/charts/flux2/values.yaml |
| flux2.clusterDomain | string | `"cluster.local"` | This is the domain name of the cluster. |
| flux2.enabled | bool | `true` | Enable or disable FluxCD installation. New Relic' Agent Control need Flux to work, but the user can use an already existing Flux deployment. With that use case, the use can disable Flux and use this chart to only install the CRs to deploy the Agent Control. |
| flux2.helmController | object | Enabled | Helm controller is a Kubernetes operator that allows to declaratively manage Helm chart releases with Kubernetes manifests. The Helm release is defined in a CR ([Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-resources)) named `HelmRelease` that the operator will reconcile on the apply, edit, or deletion of a `HelmRelease` resource.  New Relic' Agent Control will use this controller by creating `HelmRelease` CRs based in the configuration stored on Fleet Control. This is the only controller that the Agent Control need for now, the other controllers are disabled by default.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. Take a look to the `values.yaml` to see how to enable other controllers. |
| flux2.installCRDs | bool | `true` | The installation of the CRDs is managed by the chart itself. |
| flux2.rbac | object | Enabled (See `values.yaml`) | Create RBAC rules for FluxCD is able to deploy all kind of workloads on the cluster. |
| flux2.sourceController | object | Enabled | Source controller provides a way to fetch artifacts to the rest of controllers. The source API (which reference [can be read here](https://fluxcd.io/flux/components/source/api/v1/)) is used by admins and various automated operators to offload the Git, OCO, and Helm repositories management. |
| flux2.watchAllNamespaces | bool | `false` | As we are using Flux as a tool from the agent control to release new workloads, we do not want Flux to listen to all CRs created on the whole cluster. If the user does not want to use Flux and is only using it because of the agent control, this is the way to go so the cluster has deployed all operators needed by the agent control. But if the user want to use Flux for other purposes besides the agent control, this toggle can be used to allow Flux to work on the whole cluster. |
| fullnameOverride | string | `""` | Override the full name of the release |
| installationJob.chartRepositoryUrl | string | `"https://helm-charts.newrelic.com"` | The repository URL from where the `agent-control-deployment` chart will be installed. |
| installationJob.logLevel | string | info | Log level for the installation job. |
| nameOverride | string | `""` | Override the name of the chart |
| toolkitImage | object | `{"pullPolicy":"IfNotPresent","pullSecrets":[],"registry":null,"repository":"newrelic/newrelic-agent-control-cli","tag":"0.41.0"}` | The image that contains the necessary tools to install and uninstall Agent Control. |
| toolkitImage.pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| uninstallationJob.logLevel | string | info | Log level for the uninstallation job. |

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
