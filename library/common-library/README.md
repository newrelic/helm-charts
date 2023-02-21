# Helm Common library

The common library is a way to unify the UX through all the Helm charts that implement it.

The tooling suite that New Relic is huge and growing and this allows to set things globally
and locally for a single chart.

## Documentation for chart writers

If you are writing a chart that is going to use this library you can check the [developers guide](/library/common-library/DEVELOPERS.md) to see all
the functions/templates that we have implemented, what they do and how to use them.

## Values managed globally

We want to have a seamless experience through all the charts so we created this library that tries to standardize the behaviour
of all the charts. Sadly, because of the complexity of all these integrations, not all the charts behave exactly as expected.

An example is `newrelic-infrastructure` that ignores `hostNetwork` in the control plane scraper because most of the users has the
control plane listening in the node to `localhost`.

For each chart that has a special behavior (or further information of the behavior) there is a "chart particularities" section
in its README.md that explains which is the expected behavior.

At the time of writing this, all the charts from `nri-bundle` except `newrelic-logging` and `synthetics-minion` implements this
library and honors global options as described in this document.

Here is a list of global options:

| Global keys | Local keys | Default | Merged[<sup>1</sup>](#values-managed-globally-1) | Description |
|-------------|------------|---------|--------------------------------------------------|-------------|
| global.cluster | cluster | `""` |  | Name of the Kubernetes cluster monitored |
| global.licenseKey | licenseKey | `""` |  | This set this license key to use |
| global.customSecretName | customSecretName | `""` |  | In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there |
| global.customSecretLicenseKey | customSecretLicenseKey | `""` |  | In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located |
| global.podLabels | podLabels | `{}` | yes | Additional labels for chart pods |
| global.labels | labels | `{}` | yes | Additional labels for chart objects |
| global.priorityClassName | priorityClassName | `""` |  | Sets pod's priorityClassName |
| global.hostNetwork | hostNetwork | `false` |  | Sets pod's hostNetwork |
| global.dnsConfig | dnsConfig | `{}` |  | Sets pod's dnsConfig |
| global.images.registry | See [Further information](#values-managed-globally-2) | `""` |  | Changes the registry where to get the images. Useful when there is an internal image cache/proxy |
| global.images.pullSecrets | See [Further information](#values-managed-globally-2) | `[]` | yes | Set secrets to be able to fetch images |
| global.podSecurityContext | podSecurityContext | `{}` |  | Sets security context (at pod level) |
| global.containerSecurityContext | containerSecurityContext | `{}` |  | Sets security context (at container level) |
| global.affinity | affinity | `{}` |  | Sets pod/node affinities |
| global.nodeSelector | nodeSelector | `{}` |  | Sets pod's node selector |
| global.tolerations | tolerations | `[]` |  | Sets pod's tolerations to node taints |
| global.serviceAccount.create | serviceAccount.create | `true` |  | Configures if the service account should be created or not |
| global.serviceAccount.name | serviceAccount.name | name of the release |  | Change the name of the service account. This is honored if you disable on this cahrt the creation of the service account so you can use your own. |
| global.serviceAccount.annotations | serviceAccount.annotations | `{}` | yes | Add these annotations to the service account we create |
| global.customAttributes | customAttributes | `{}` |  | Adds extra attributes to the cluster and all the metrics emitted to the backend |
| global.fedramp | fedramp | `false` |  | Enables FedRAMP |
| global.lowDataMode | lowDataMode | `false` |  | Reduces number of metrics sent in order to reduce costs |
| global.privileged | privileged | Depends on the chart |  | In each integration it has different behavior. See [Further information](#values-managed-globally-3) but all aims to send less metrics to the backend to try to save costs |
| global.proxy | proxy | `""` |  | Configures the integration to send all HTTP/HTTPS request through the proxy in that URL. The URL should have a standard format like `https://user:password@hostname:port` |
| global.nrStaging | nrStaging | `false` |  | Send the metrics to the staging backend. Requires a valid staging license key |
| global.verboseLog | verboseLog | `false` |  | Sets the debug/trace logs to this integration or all integrations if it is set globally |

### Further information
<a name="values-managed-globally-1"></a>
#### 1. Merged

Merged means that the values from global are not replaced by the local ones. Think in this example:
```yaml
global:
  labels:
    global: global
  hostNetwork: true
  nodeSelector:
    global: global

labels:
  local: local
nodeSelector:
  local: local
hostNetwork: false
```

This values will template `hostNetwork` to `false`, a map of labels `{ "global": "global", "local": "local" }` and a `nodeSelector` with
`{ "local": "local" }`.

As Helm by default merges all the maps it could be confusing that we have two behaviors (merging `labels` and replacing `nodeSelector`)
the `values` from global to local. This is the rationale behind this:
* `hostNetwork` is templated to `false` because is overriding the value defined globally.
* `labels` are merged because the user may want to label all the New Relic pods at once and label other solution pods differently for
  clarity' sake.
* `nodeSelector` does not merge as `labels` because could make it harder to overwrite/delete a selector that comes from global because
  of the logic that Helm follows merging maps.

<a name="values-managed-globally-2"></a>
#### 2. Fine grain registries

Some charts only have 1 image while others that can have 2 or more images. The local path for the registry can change depending
on the chart itself.

As this is mostly unique per helm chart, you should take a look to the chart's values table (or directly to the `values.yaml` file to see all the
images that you can change.

This should only be needed if you have an advanced setup that forces you to have granularity enough to force a proxy/cache registry per integration.


<a name="values-managed-globally-3"></a>
#### 3. Privileged mode

By default, from the common library, the privileged mode is set to false. But most of the helm charts require this to be true to fetch more
metrics so could see a true in some charts. The consequences of the privileged mode differ from one chart to another so for each chart that
honors the privileged mode toggle should be a section in the README explaining which is the behavior with it enabled or disabled.
