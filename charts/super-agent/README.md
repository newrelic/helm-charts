[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# super-agent

![Version: 0.0.0-beta](https://img.shields.io/badge/Version-0.0.0--beta-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Bootstraps New Relic' Super Agent

# Helm installation

You can install this chart using directly this Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm upgrade --install newrelic/super-agent -f your-custom-values.yaml
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
| flux2.helmController | object | Enabled | Helm controller is a Kubernetes operator that allows to declaratively manage Helm chart releases with Kubernetes manifests. The Helm release is defined in a CR ([Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#custom-resources)) named `HelmRelease` that the operator will reconcile on the apply, edit, or deletion of a `HelmRelease` resource.  New Relic' Super Agent will use this controller by creating `HelmRelease` CRs based in the configuration stored on OpAmp. |
| flux2.imageAutomationController | object | Disabled | The image automation controller updates YAML files based on the latest images scanned by image reflector controller, and commits the changes to a given Git repository.  From New Relic, all releases are managed via OpAmp and there is no need to touch user's repositories.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. |
| flux2.imageReflectionController | object | Disabled | The image reflector controller scans image repositories and reflects the image metadata in Kubernetes resources ready to be used by other controllers.  From New Relic, all releases are managed via OpAmp and there is no need to touch user's repositories.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. |
| flux2.installCRDs | bool | `true` | The installation of the CRDs is managed by the chart itself. |
| flux2.kustomizeController | object | Disabled | This controller is exactly the same as the Helm controller (refer to it) but assembling manifests with Kustomize instead of using templating systems like Helm.  From New Relic, all releases managed via OpAmp install helm charts so there is no need for this controller to be up.  On the other hand, user might want to leverage having FluxCD installed for their own purposes. |
| flux2.notificationController | object | Disabled | The notification controller handles events coming from external systems (GitHub, GitLab, Bitbucket, Harbor, Jenkins, etc) and notifies the GitOps toolkit controllers about source changes. The controller also handles events emitted by the GitOps toolkit controllers (source, kustomize, helm) and dispatches them to external systems (Slack, Microsoft Teams, Discord) based on event severity and involved objects.   New Relic provides a powerful alert system with multiple policies and routes to alert users so it is disabled by default on our FluxCD distribution. |
| flux2.policies | object | Disabled | Upstream chart create Network Policies. They are relaxed to enough to not cut any malicious attack and not reduce the attack surface enough on environments where the security is a must. |
| flux2.rbac | object | Enabled (See `values.yaml`) | Create RBAC rules for FluxCD is able to deploy all kind of workloads on the cluster. |
| flux2.sourceController | object | Enabled | Source controller provides a way to fetch artifacts to the rest of controllers. The source API (which reference [can be read here](https://fluxcd.io/flux/components/source/api/v1/)) is used by admins and various automated operators to offload the Git, OCO, and Helm repositories management. |
| flux2.watchAllNamespaces | bool | `false` | As we are using Flux as a tool from the super agent to release new workloads, we do not want Flux to listen to all CRs created on the whole cluster. If the user does not want to use Flux and is only using it because of the super agent, this is the way to go so the cluster has deployed all operators needed by the super agent. But if the user want to use Flux for other purposes besides the super agent, this toggle can be used to allow Flux to work on the whole cluster.   |
| helm.create | bool | `true` | Enable the installation of the CRs so FluxCD deploy the Super Agent is deployed. This an advanced/debug flag. It should be always be true unless you know what you are going.  |
| helm.release | object | See `values.yaml` | Values related to the super agent's Helm chart release. |
| helm.release.chart | string | `"super-agent-deployment"` | The Helm chart of the super-agent. This values is meant to be changed only on air-gapped environments or for development/testing purposes. |
| helm.release.install | object | See `values.yaml` | Change the behavior of the operator while installing the chart for the first time. This should only be changed by advanced users that know what they are doing. Exposes the remediations that the operator is going to try before give up installing the chart in case it hits an error. |
| helm.release.upgrade | object | See `values.yaml` | Change the behavior of the operator while upgrading the chart. This should only be changed by advanced users that know what they are doing. Exposes the remediations that the operator is going to try before give up installing the chart in case it hits an error. |
| helm.release.values | string | no values | Set values to the super agent helm release directly from this `values.yaml` file. Refer to https://fluxcd.io/flux/components/helm/helmreleases/#values-overrides |
| helm.release.valuesFrom | string | empty | Set values from a `configMap` or a `secret`. You can see examples and better documentation inside the `values.yaml` file. Also refer to https://fluxcd.io/flux/components/helm/helmreleases/#values-overrides |
| helm.release.version | string | `"0.0.0-beta"` | The Helm chart of the super-agent. This values is meant to be changed only on air-gapped environments or for development/testing purposes.  TODO: Point renovatebot here. |
| helm.repository | object | See `values.yaml` | Values related to the Helm repository where to download the super agent's chart. |
| helm.repository.certSecretRef | string | `nil` (no secret reference)  | secret of type `kubernetes.io/tls` with the standard keys `tls.crt`, `tls.key`, and `ca.crt` |
| helm.repository.secretRef | string | `nil` (no secret reference)  | A reference to a secret with the keys username and password to authenticate to the repository. |
| helm.repository.updateInterval | string | `"24h"` | Sets the interval the repository is going to be updated on the controller. |
| helm.repository.url | string | `"https://helm-charts.newrelic.com"` | The repository where the super-agent has the chart. This values is meant to be changed only on air-gapped  environments or for development/testing purposes. |

