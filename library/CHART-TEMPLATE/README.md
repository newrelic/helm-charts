[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# CHART-TEMPLATE

![Version: 1.0.3](https://img.shields.io/badge/Version-1.0.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes showing how to use/implement the common-library

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../common-library | common-library | 1.0.3 |

Note that values in this chart are not important:
This is an example of a chart and how to use it combined with the `common-library`. Values are simply to test
that the charts are templating correctly and to do unittest over the common-library.

# Chart particularities

Here is where you should add particularities for this chart like what does the chart do with the privileged and
low data modes or any other quirk that it could have.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| agent | string | `nil` |  |
| cluster | string | `"barfoo"` |  |
| fullnameOverride | string | `""` |  |
| global.affinity | object | `{}` |  |
| global.hostNetwork | string | `nil` |  |
| global.image.pullPolicy | list | `[]` |  |
| global.image.registry | string | `nil` |  |
| global.lowDataMode | string | `nil` |  |
| global.nodeSelector | object | `{}` |  |
| global.serviceAccount.annotations | string | `nil` |  |
| global.serviceAccount.create | string | `nil` |  |
| global.serviceAccount.name | string | `nil` |  |
| global.tolerations | list | `[]` |  |
| global.verboseLog | string | `nil` |  |
| hostNetwork | string | `nil` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `nil` |  |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| licenseKey | string | `"foobar"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | string | `nil` |  |
| serviceAccount.create | string | `nil` |  |
| serviceAccount.name | string | `nil` |  |
| tolerations | list | `[]` |  |
| verboseLog | string | `nil` |  |

## Maintainers

* [alvarocabanas](https://github.com/alvarocabanas)
* [carlossscastro](https://github.com/carlossscastro)
* [sigilioso](https://github.com/sigilioso)
* [gsanchezgavier](https://github.com/gsanchezgavier)
* [kang-makes](https://github.com/kang-makes)
* [marcsanmi](https://github.com/marcsanmi)
* [paologallinaharbur](https://github.com/paologallinaharbur)
* [roobre](https://github.com/roobre)
