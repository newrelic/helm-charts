# Helm Common library

Common library is a way to unify the UX through all the Helm charts that implement it.

The tooling suite that New Relic is huge and growing and this allows to set things globally
and locally for a single chart.

Most of these functions are configured to read a variables from the `global` map that allows
to be overridden/merged with a variable that is defined at root level by the chart that chart
writer is implementing. e.g.:
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

this values will template `hostNetwork` to `false`, a map of labels `{ "global": "global",
"local": "local" }` and a `nodeSelector` with `{ "local": "local" }`.

This is the rationale behind of this behavior:
 * `hostNetwork` is templated to `false` because is overriding the value defined globally.
 * `labels` are merged because the use may want to label all the New Relic pods at once and
   label other solution pods differently for clarity' sake.
 * `nodeSelector` does not merge as `labels` because could make harder to overwrite/delete
   a selector that comes from global because of the logic that Helm follows merging maps.

It could be confusing to have two behaviours regarding when this chart merges or replaces the
`values` from global to local. All functions simply replace the value from `global` with the
one that is in the root of the chart except functions that template `labels`, `customAttributes`,
and service account's annotations.

# Functions/templates documented for chart writers
Here is some rough documentation separated by the file that contains the function, the function
name and how to use it. We are not covering functions that start with `_` (e.g.
`newrelic.common.license._licenseKey`) because they are used internally by this library for
other helpers. Helm does not have the concept of "public" or "private" functions/templates so
this is a convention of ours.

## _naming.tpl
These functions are used to name objects.

### `newrelic.common.naming.name`
This is the same as the idiomatic `CHART-NAME.name` that is created when you use `helm create`.

It honors `.Values.nameOverride`.

Usage:
```mustache
{{ include "newrelic.common.naming.name" . }}
```

### `newrelic.common.naming.fullname`
This is the same as the idiomatic `CHART-NAME.fullname` that is created when you use `helm create`

It honors `.Values.fullnameOverride`.

Usage:
```mustache
{{ include "newrelic.common.naming.fullname" . }}
```

### `newrelic.common.naming.chart`
This is the same as the idiomatic `CHART-NAME.chart` that is created when you use `helm create`.

It is mostly useless for chart writers. It is used internally for templating the labels but there
is no reason to keep them "private".

Usage:
```mustache
{{ include "newrelic.common.naming.chart" . }}
```

### `newrelic.common.naming.truncateToDNS`
This a useful template that could be used to trim a string to 63 chars and do not end with a dash (`-`).
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).

Usage:
```mustache
{{ $nameToTruncate := "a-really-really-really-really-REALLY-long-string-that-should-be-truncated-because-it-is-enought-long-to-brak-something"
{{- $truncatedName := include "newrelic.common.naming.truncateToDNS" $nameToTruncate }}
{{- $truncatedName }}
{{- /* This should print: a-really-really-really-really-REALLY-long-string-that-should-be */ -}}
```

### `newrelic.common.naming.truncateToDNSWithSuffix`
This template function is the same as the above but instead of receiving a string you should give a `dict`
with a `name` and a `suffix`. This function will join them with a dash (`-`) and trim the `name` so the
result of `name-suffix` is no more than 63 chars

Usage:
```mustache
{{ $nameToTruncate := "a-really-really-really-really-REALLY-long-string-that-should-be-truncated-because-it-is-enought-long-to-brak-something"
{{- $suffix := "A-NOT-SO-LONG-SUFFIX" }}
{{- $truncatedName := include "truncateToDNSWithSuffix" (dict "name" $nameToTruncate "suffix" $suffix) }}
{{- $truncatedName }}
{{- /* This should print: a-really-really-really-really-REALLY-long-A-NOT-SO-LONG-SUFFIX */ -}}
```



## _labels.tpl
### `newrelic.common.labels`, `newrelic.common.labels.selectorLabels` and `newrelic.common.labels.podLabels`
These are functions that are used to label objects. They are configured by this `values.yaml`
```yaml
global:
  podLabels: {}  # included in all the pods of all the charts that implement this library
  labels: {}  # included in all the objects of all the charts that implement this library
podLabels: {}  # included in all the pods of the chart that the chart writes is implementing
labels: {}  # included in all the objects of the chart that the chart writes is implementing
```

label maps are merged from global to local values.

And chart writer should use them like this:
```mustache
metadata:
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "newrelic.common.labels.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "newrelic.common.labels.podLabels" . | nindent 8 }}
```

`newrelic.common.labels.podLabels` includes `newrelic.common.labels.selectorLabels` automatically.



## _priority-class-name.tpl
### `newrelic.common.priorityClassName`
As almost everything in this library, it read global and local variables:
```yaml
global:
  priorityClassName: ""
priorityClassName: ""
```

Be careful: chart writer should put an empty string (or any kind of Helm falsiness) for this
library to work properly. If in your values a non-falsy `priorityClassName` is found, the global
one is going to be always ignored.

Usage (example in a pod spec):
```mustache
spec:
  {{- with include "newrelic.common.priorityClassName" . }}
  priorityClassName: {{ . }}
  {{- end }}
```



## _hostnetwork.tpl
### `newrelic.common.hostNetwork`
As almost everything in this library, it read global and local variables:
```yaml
global:
  hostNetwork:  # Note that this is empty (nil)
hostNetwork:  # Note that this is empty (nil)
```

Be careful: chart writer should NOT PUT ANY VALUE for this library to work properly. If in you
values a `hostNetwork` is defined, the global one is going to be always ignored.

This functions returns "true" of "" (empty string) so it can be used for evaluating conditionals.

Usage (example in a pod spec):
```mustache
spec:
  {{- with include "newrelic.common.hostNetwork" . }}
  hostNetwork: {{ . }}
  {{- end }}
```

### `newrelic.common.hostNetwork.value`
This function is an abstraction of the function above but this returns directly "true" or "false".

Be careful with using this with an `if` as Helm does evaluate "false" (string) as `true`.

Usage (example in a pod spec):
```mustache
spec:
  hostNetwork: {{ include "newrelic.common.hostNetwork.value" . }}
```



## _dnsconfig.tpl
### `newrelic.common.dnsConfig`
As almost everything in this library, it read global and local variables:
```yaml
global:
  dnsConfig: {}
dnsConfig: {}
```

Be careful: chart writer should put an empty string (or any kind of Helm falsiness) for this
library to work properly. If in your values a non-falsy `dnsConfig` is found, the global
one is going to be always ignored.

Usage (example in a pod spec):
```mustache
spec:
  {{- with include "newrelic.common.dnsConfig" . }}
  dnsConfig:
    {{- . | nindent 4 }}
  {{- end }}
```



## _images.tpl
These functions help us to deal with how images are templated. This allows to set `registries`
where to fetch images globally while being flexible enough to fit in different maps of images
and deployments with one or more images. This is the example of a complex `values.yaml` that
we are going to use during the documentation of these functions:

```yaml
global:
  registry: nexus-3-instance.internal.clients-domain.tld
patchJob:
  image:
```

### `newrelic.common.images.image`
Usage:
```mustache
{{ include "newrelic.common.images.image" . }}
```

### `newrelic.common.images.registry`
Usage:
```mustache
{{ include "newrelic.common.images.registry" . }}
```

### `newrelic.common.images.repository`
Usage:
```mustache
{{ include "newrelic.common.images.repository" . }}
```

### `newrelic.common.images.tag`
Usage:
```mustache
{{ include "newrelic.common.images.tag" . }}
```

### `newrelic.common.images.renderPullSecrets`
Usage:
```mustache
{{ include "newrelic.common.images.renderPullSecrets" . }}
```



## _affinity.tpl, _nodeselector.tpl and _tolerations.tpl
There three files are almost equal, follow the idiomatic way that `helm create` creates by
default. It also looks if there is a global value like other helpers.
```yaml
global:
  affinity: {}
  nodeSelector: {}
  tolerations: []
affinity: {}
nodeSelector: {}
tolerations: []
```

The values here are replaced. if a value at root level is found, global one is ignored.

Usage (example in a pod spec):
```mustache
spec:
  {{- with include "newrelic.common.nodeSelector" . }}
  nodeSelector:
    {{- . | nindent 4 }}
  {{- end }}
  {{- with include "newrelic.common.affinity" . }}
  affinity:
    {{- . | nindent 4 }}
  {{- end }}
  {{- with include "newrelic.common.tolerations" . }}
  tolerations:
    {{- . | nindent 4 }}
  {{- end }}
```

## _agent-config.tpl
### `newrelic.common.agentConfig.defaults`
Usage:
```mustache
{{ include "newrelic.common.agentConfig.defaults" . }}
```

## _cluster.tpl
### `newrelic.common.cluster`
Usage:
```mustache
{{ include "newrelic.common.cluster" . }}
```

## _custom-attributes.tpl
### `newrelic.common.customAttributes`
Usage:
```mustache
{{ include "newrelic.common.customAttributes" . }}
```

## _fedramp.tpl
### `newrelic.common.fedramp.enabled`
Usage:
```mustache
{{ include "newrelic.common.fedramp.enabled" . }}
```

### `newrelic.common.fedramp.enabled.value`
Usage:
```mustache
{{ include "newrelic.common.fedramp.enabled.value" . }}
```

## _license.tpl
### `newrelic.common.license.secretName`
Usage:
```mustache
{{ include "newrelic.common.license.secretName" . }}
```

### `newrelic.common.license.secretKeyName`
Usage:
```mustache
{{ include "newrelic.common.license.secretKeyName" . }}
```

### `newrelic.common.license._licenseKey`
Usage:
```mustache
{{ include "newrelic.common.license._licenseKey" . }}
```

### `newrelic.common.license._customSecretName`
Usage:
```mustache
{{ include "newrelic.common.license._customSecretName" . }}
```

### `newrelic.common.license._customSecretKey`
Usage:
```mustache
{{ include "newrelic.common.license._customSecretKey" . }}
```

## _license_secret.tpl
### `newrelic.common.license.secre`
Usage:
```mustache
{{ include "newrelic.common.license.secret". }}
```

## _low-data-mode.tpl
### `newrelic.common.lowDataMode`
Usage:
```mustache
{{ include "newrelic.common.lowDataMode" . }}
```

## _privileged.tpl
### `newrelic.common.privileged`
Usage:
```mustache
{{ include "newrelic.common.privileged" . }}
```

### `newrelic.common.privileged.value`
Usage:
```mustache
{{ include "newrelic.common.privileged.value" . }}
```

## _proxy.tpl
### `newrelic.common.proxy`
Usage:
```mustache
{{ include "newrelic.common.proxy" . }}
```

## _security-context.tpl
### `newrelic.common.securityContext.container`
Usage:
```mustache
{{ include "newrelic.common.securityContext.container" . }}
```

### `newrelic.common.securityContext.pod`
Usage:
```mustache
{{ include "newrelic.common.securityContext.pod" . }}
```

## _serviceaccount.tpl
### `newrelic.common.serviceAccount.create`
Usage:
```mustache
{{ include "newrelic.common.serviceAccount.create" . }}
```

### `newrelic.common.serviceAccount.name`
Usage:
```mustache
{{ include "newrelic.common.serviceAccount.name" . }}
```

### `newrelic.common.serviceAccount.annotations`
Usage:
```mustache
{{ include "newrelic.common.serviceAccount.annotations" . }}
```

## _staging.tpl
### `newrelic.common.nrStaging`
Usage:
```mustache
{{ include "newrelic.common.nrStaging" . }}
```

### `newrelic.common.nrStaging.value`
Usage:
```mustache
{{ include "newrelic.common.nrStaging.value" . }}
```

## _verbose-log.tpl
### `newrelic.common.verboseLog`
Usage:
```mustache
{{ include "newrelic.common.verboseLog" . }}
```

### `newrelic.common.verboseLog.valueAsBoolean`
Usage:
```mustache
{{ include "newrelic.common.verboseLog.valueAsBoolean" . }}
```

### `newrelic.common.verboseLog.valueAsInt`
Usage:
```mustache
{{ include "newrelic.common.verboseLog.valueAsInt" . }}
```

