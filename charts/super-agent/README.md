[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# super-agent

![Version: 0.0.8-beta](https://img.shields.io/badge/Version-0.0.8--beta-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

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
| super-agent-deployment | object | See `values.yaml` | Values related to the super agent's Helm chart release. |
| super-agent-deployment.enabled | bool | `true` | Enable the installation of the Super Agent. This an advanced/debug flag. It should be always be true unless  you know what you are going. |

## Maintainers

* [sigilioso](https://github.com/sigilioso)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [kang-makes](https://github.com/kang-makes)
* [marcsanmi](https://github.com/marcsanmi)
* [paologallinaharbur](https://github.com/paologallinaharbur)
