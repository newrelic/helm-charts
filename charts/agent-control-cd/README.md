[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# agent-control-cd

A Helm chart to install New Relic Agent Control CD (Flux) on Kubernetes

# Helm installation

This chart is not intended to be installed on its own. Instead, it is designed to be installed as part of the [agent-control](https://github.com/newrelic/helm-charts/tree/master/charts/agent-control) chart.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| flux2 | object | See `values.yaml` | Default Values for the Flux chart. Full list Ref.: https://github.com/fluxcd-community/helm-charts/blob/flux2-2.10.2/charts/flux2/values.yaml |
| flux2.enabled | bool | `true` | Enable or disable FluxCD installation. New Relic' Agent Control need Flux to work, but the user can use an already existing Flux deployment. With that use case, the use can disable Flux and use this chart to only install the CRs to deploy the Agent Control. |
| flux2.clusterDomain | string | `"cluster.local"` | This is the domain name of the cluster. |
| flux2.helmController | object | Enabled | Helm controller is a Kubernetes operator that allows to declaratively manage Helm chart releases with Kubernetes manifests. The Helm release is defined in a CR ([Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-resources)) named `HelmRelease` that the operator will reconcile on the apply, edit, or deletion of a `HelmRelease` resource.  New Relic' Agent Control will use this controller by creating `HelmRelease` CRs based in the configuration stored on Fleet Control. This is the only controller that the Agent Control need for now, the other controllers are disabled by default.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. Take a look to the `values.yaml` to see how to enable other controllers. |
| flux2.installCRDs | bool | `true` | The installation of the CRDs is managed by the chart itself. |
| flux2.rbac | object | Enabled (See `values.yaml`) | Create RBAC rules for FluxCD is able to deploy all kind of workloads on the cluster. |
| flux2.sourceController | object | Enabled | Source controller provides a way to fetch artifacts to the rest of controllers. The source API (which reference [can be read here](https://fluxcd.io/flux/components/source/api/v1/)) is used by admins and various automated operators to offload the Git, OCO, and Helm repositories management. |
| flux2.watchAllNamespaces | bool | `false` | As we are using Flux as a tool from the agent control to release new workloads, we do not want Flux to listen to all CRs created on the whole cluster. If the user does not want to use Flux and is only using it because of the agent control, this is the way to go so the cluster has deployed all operators needed by the agent control. But if the user want to use Flux for other purposes besides the agent control, this toggle can be used to allow Flux to work on the whole cluster. |

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
