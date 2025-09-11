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
$ kubectl create configmap dynamic-agent --from-file=dynamic-agent-type=./local/values-dynamic-agent-type.yaml -n default
```

Then you can mount such agentType leveraging extra volumes in the values.yaml
```yaml
agent-control-deployment:
# [...]
  extraVolumeMounts:
    - name: dynamic
      mountPath: /etc/newrelic-agent-control/dynamic-agent-type.yaml
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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agentControlCd.chartName | string | agent-control-cd | The name of the CD chart that will be installed by the installation job. |
| agentControlCd.chartRepositoryUrl | string | https://helm-charts.newrelic.com | The repository URL from where the `agent-control-cd` chart will be installed. When not leveraging the default, you may also need to allow the url in `agentControlDeployment.chartValues.config.allowedChartRepositoryUrl`. Ref.: https://github.com/newrelic/helm-charts/blob/master/charts/agent-control-deployment/values.yaml |
| agentControlCd.chartValues | string | See `values.yaml` | Values for the agent-control-deployment chart. Ref.: https://github.com/newrelic/helm-charts/blob/master/charts/agent-control-cd/values.yaml |
| agentControlCd.chartVersion | string | `.Chart.annotations.agentControlCdVersion` | The version of the CD chart that will be installed by the installation job. |
| agentControlCd.enabled | bool | `true` | Enable the installation of a Continuous Deployment system that can be managed by Agent Control. |
| agentControlCd.releaseName | string | agent-control-cd | The name of the release for the CD chart. |
| agentControlCd.repositoryCertificateSecretReferenceName | string | `nil` | Optional name of the secret containing TLS certificates for the Helm repository. Ref.: https://fluxcd.io/flux/components/source/helmrepositories/#cert-secret-reference |
| agentControlCd.repositorySecretReferenceName | string | `nil` | Optional name of the secret containing credentials for the Helm repository. Ref.: https://fluxcd.io/flux/components/source/helmrepositories/#secret-reference |
| agentControlDeployment.chartName | string | agent-control-deployment | The name of the chart that will be installed by the installation job. |
| agentControlDeployment.chartRepositoryUrl | string | https://helm-charts.newrelic.com | The repository URL from where the `agent-control-deployment` chart will be installed. When not leveraging the default, you may also need to allow the url in `agentControlDeployment.chartValues.config.allowedChartRepositoryUrl`. Ref.: https://github.com/newrelic/helm-charts/blob/master/charts/agent-control-deployment/values.yaml |
| agentControlDeployment.chartValues | object | See `values.yaml` | Values for the agent-control-deployment chart. Ref.: https://github.com/newrelic/helm-charts/blob/master/charts/agent-control-deployment/values.yaml |
| agentControlDeployment.chartValues.subAgentsNamespace | string | "newrelic" | Namespace where agents are deployed |
| agentControlDeployment.chartVersion | string | `.Chart.appVersion` | The version of the Agent Control chart that will be installed by the installation job. |
| agentControlDeployment.enabled | bool | `true` | Enable the installation of Agent Control. |
| agentControlDeployment.releaseName | string | agent-control-deployment | The name of the release for the deployment chart. |
| agentControlDeployment.repositoryCertificateSecretReferenceName | string | `nil` | Optional name of the secret containing TLS certificates for the Helm repository. Ref.: https://fluxcd.io/flux/components/source/helmrepositories/#cert-secret-reference |
| agentControlDeployment.repositorySecretReferenceName | string | `nil` | Optional name of the secret containing credentials for the Helm repository. Ref.: https://fluxcd.io/flux/components/source/helmrepositories/#secret-reference |
| fullnameOverride | string | `""` | Override the full name of the release |
| installation.extraEnv | list | `[]` | Extra environment variables |
| installation.extraVolumeMounts | list | `[]` | Defines where to mount volumes specified with `extraVolumes` |
| installation.extraVolumes | list | `[]` | Volumes to mount in the containers |
| installation.log.level | string | debug | Log level for installation. |
| nameOverride | string | `""` | Override the name of the chart |
| toolkitImage | object | `{"pullPolicy":"IfNotPresent","pullSecrets":[],"registry":null,"repository":"newrelic/newrelic-agent-control-cli","tag":"0.48.0"}` | The image that contains the necessary tools to install and uninstall the Agent Control components. |
| toolkitImage.pullSecrets | list | `[]` | The secrets that are needed to pull images from a custom registry. |
| uninstallation.log.level | string | debug | Log level for installation. |

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
