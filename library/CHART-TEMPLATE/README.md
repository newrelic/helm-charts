[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# CHART-TEMPLATE

![Version: 1.0.3](https://img.shields.io/badge/Version-1.0.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes showing how to use/implement the common-library

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../common-library | common-library | 1.0.3 |

Note that the values in this chart are not important:
This is a example of a chart and how to used it combined with the `common-library`. Values are simply to test
that the charts are templating correctly and to do unittest over the common-library.

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
| serviceAccount.annotations | string | `nil` |  |
| serviceAccount.create | string | `nil` |  |
| serviceAccount.name | string | `nil` |  |
| tolerations | list | `[]` |  |
| verboseLog | string | `nil` |  |

## Maintainers

* [Alvaro Cabanas](https://github.com/alvarocabanas)
* [Carlos Castro](https://github.com/carlossscastro)
* [Christian Felipe](https://github.com/sigilioso)
* [Guillermo Sanchez](https://github.com/gsanchezgavier)
* [Juan Manuel Perez](https://github.com/kang-makes)
* [Marc Sanmiquel](https://github.com/marcsanmi)
* [Paolo Gallina](https://github.com/paologallinaharbur)
* [Roberto Santalla](https://github.com/roobre)
