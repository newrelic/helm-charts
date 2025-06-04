[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# CHART-TEMPLATE

![Version: 1.3.0](https://img.shields.io/badge/Version-1.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes showing how to use/implement the common-library

# Helm installation

You can install this chart using [`nri-bundle`](https://github.com/newrelic/helm-charts/tree/master/charts/nri-bundle) located in the
[helm-charts repository](https://github.com/newrelic/helm-charts) or directly from this repository by adding this Helm repository:

```shell
helm repo add newrelic https://newrelic.github.io/helm-charts
helm upgrade --install newrelic/CHART-TEMPLATE -f your-custom-values.yaml
```

## Values managed globally

This chart implements the [New Relic's common Helm library](https://github.com/newrelic/helm-charts/tree/master/library/common-library) which
means that it honors a wide range of defaults and globals common to most New Relic Helm charts.

Options that can be defined globally include `affinity`, `nodeSelector`, `tolerations`, `proxy` and others. The full list can be found at
[user's guide of the common library](https://github.com/newrelic/helm-charts/blob/master/library/common-library/README.md).

## Chart particularities

# Chart particularities

Here is where you should add particularities for this chart like what does the chart do with the privileged and
low data modes or any other quirk that it could have.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| cluster | string | `"barfoo"` |  |
| containerSecurityContext | object | `{}` |  |
| customInsightsKeySecretKey | string | `""` |  |
| customInsightsKeySecretName | string | `""` |  |
| customSecretLicenseKey | string | `""` |  |
| customSecretName | string | `""` |  |
| customUserKeySecretKey | string | `""` |  |
| customUserKeySecretName | string | `""` |  |
| deploymentAnnotations | object | `{}` |  |
| dnsconfig | object | `{}` |  |
| fedRamp.enabled | string | `nil` |  |
| fullnameOverride | string | `""` |  |
| global.affinity | object | `{}` |  |
| global.cluster | string | `""` |  |
| global.containerSecurityContext | object | `{}` |  |
| global.customInsightsKeySecretKey | string | `""` |  |
| global.customInsightsKeySecretName | string | `""` |  |
| global.customSecretLicenseKey | string | `""` |  |
| global.customSecretName | string | `""` |  |
| global.customUserKeySecretKey | string | `""` |  |
| global.customUserKeySecretName | string | `""` |  |
| global.deploymentAnnotations | object | `{}` |  |
| global.dnsconfig | object | `{}` |  |
| global.fedRamp.enabled | string | `nil` |  |
| global.hostNetwork | string | `nil` |  |
| global.image.pullPolicy | list | `[]` |  |
| global.image.registry | string | `nil` |  |
| global.insightsKey | string | `""` |  |
| global.labels | object | `{}` |  |
| global.licenseKey | string | `""` |  |
| global.lowDataMode | string | `nil` |  |
| global.nodeSelector | object | `{}` |  |
| global.nrStaging | string | `nil` |  |
| global.podAnnotations | object | `{}` |  |
| global.podLabels | object | `{}` |  |
| global.podSecurityContext | object | `{}` |  |
| global.priorityClassName | string | `""` |  |
| global.privileged | string | `nil` |  |
| global.proxy | string | `nil` |  |
| global.region | string | `""` |  |
| global.serviceAccount.annotations | string | `nil` |  |
| global.serviceAccount.create | string | `nil` |  |
| global.serviceAccount.name | string | `nil` |  |
| global.tolerations | list | `[]` |  |
| global.userKey | string | `""` |  |
| global.verboseLog | string | `nil` |  |
| hostNetwork | string | `nil` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `nil` |  |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| insightsKey | string | `"foobaz"` |  |
| labels | object | `{}` |  |
| licenseKey | string | `"foobar"` |  |
| lowDataMode | string | `nil` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| nrStaging | string | `nil` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| priorityClassName | string | `""` |  |
| privileged | string | `nil` |  |
| proxy | string | `nil` |  |
| region | string | `""` |  |
| resources | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | string | `nil` |  |
| serviceAccount.create | string | `nil` |  |
| serviceAccount.name | string | `nil` |  |
| tolerations | list | `[]` |  |
| userKey | string | `"barqux"` |  |
| verboseLog | string | `nil` |  |

## Maintainers

* [juanjjaramillo](https://github.com/juanjjaramillo)
* [csongnr](https://github.com/csongnr)
* [dbudziwojskiNR](https://github.com/dbudziwojskiNR)
