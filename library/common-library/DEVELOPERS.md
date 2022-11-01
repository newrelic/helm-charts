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
is no reason to keep it "private".

Usage:
```mustache
{{ include "newrelic.common.naming.chart" . }}
```

### `newrelic.common.naming.truncateToDNS`
This is a useful template that could be used to trim a string to 63 chars and does not end with a dash (`-`).
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
podLabels: {}  # included in all the pods of this chart
labels: {}  # included in all the objects of this chart
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
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  priorityClassName: ""
priorityClassName: ""
```

Be careful: chart writers should put an empty string (or any kind of Helm falsiness) for this
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
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  hostNetwork:  # Note that this is empty (nil)
hostNetwork:  # Note that this is empty (nil)
```

Be careful: chart writers should NOT PUT ANY VALUE for this library to work properly. If in you
values a `hostNetwork` is defined, the global one is going to be always ignored.

This function returns "true" of "" (empty string) so it can be used for evaluating conditionals.

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
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  dnsConfig: {}
dnsConfig: {}
```

Be careful: chart writers should put an empty string (or any kind of Helm falsiness) for this
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
These functions help us to deal with how images are templated. This allows setting `registries`
where to fetch images globally while being flexible enough to fit in different maps of images
and deployments with one or more images. This is the example of a complex `values.yaml` that
we are going to use during the documentation of these functions:

```yaml
global:
  images:
    registry: nexus-3-instance.internal.clients-domain.tld
jobImage:
  registry: # defaults to "example.tld" when empty in these examples
  repository: ingress-nginx/kube-webhook-certgen
  tag: v1.1.1
  pullPolicy: IfNotPresent
  pullSecrets: []
images:
  integration:
    registry:
    repository: newrelic/nri-kube-events
    tag: 1.8.0
    pullPolicy: IfNotPresent
  agent:
    registry:
    repository: newrelic/k8s-events-forwarder
    tag: 1.22.0
    pullPolicy: IfNotPresent
  pullSecrets: []
```

### `newrelic.common.images.image`
This will return a string with the image ready to be downloaded that includes the registry, the image and the tag.
`defaultRegistry` is used to keep `registry` field empty in `values.yaml` so you can override the image using
`global.images.registry`, your local `jobImage.registry` and be able to fallback to a registry that is not `docker.io`
(Or the default repository that the client could have set in the CRI).

Usage:
```mustache
{{- /* For the integration */}}
{{ include "newrelic.common.images.image" ( dict "imageRoot" .Values.images.integration "context" .) }}
{{- /* For the agent */}}
{{ include "newrelic.common.images.image" ( dict "imageRoot" .Values.images.agent "context" .) }}
{{- /* For jobImage */}}
{{ include "newrelic.common.images.image" ( dict "defaultRegistry" "example.tld" "imageRoot" .Values.jobImage "context" .) }}
```

### `newrelic.common.images.registry`
It returns the registry from the global or local values. You should avoid using this helper to create your image
URL and use `newrelic.common.images.image` instead, but it is there to be used in case it is needed.

Usage:
```mustache
{{- /* For the integration */}}
{{ include "newrelic.common.images.registry" ( dict "imageRoot" .Values.images.integration "context" .) }}
{{- /* For the agent */}}
{{ include "newrelic.common.images.registry" ( dict "imageRoot" .Values.images.agent "context" .) }}
{{- /* For jobImage */}}
{{ include "newrelic.common.images.registry" ( dict "defaultRegistry" "example.tld" "imageRoot" .Values.jobImage "context" .) }}
```

### `newrelic.common.images.repository`
It returns the image from the values. You should avoid using this helper to create your image
URL and use `newrelic.common.images.image` instead, but it is there to be used in case it is needed.

Usage:
```mustache
{{- /* For jobImage */}}
{{ include "newrelic.common.images.repository" ( dict "imageRoot" .Values.jobImage "context" .) }}
{{- /* For the integration */}}
{{ include "newrelic.common.images.repository" ( dict "imageRoot" .Values.images.integration "context" .) }}
{{- /* For the agent */}}
{{ include "newrelic.common.images.repository" ( dict "imageRoot" .Values.images.agent "context" .) }}
```

### `newrelic.common.images.tag`
It returns the image's tag from the values. You should avoid using this helper to create your image
URL and use `newrelic.common.images.image` instead, but it is there to be used in case it is needed.

Usage:
```mustache
{{- /* For jobImage */}}
{{ include "newrelic.common.images.tag" ( dict "imageRoot" .Values.jobImage "context" .) }}
{{- /* For the integration */}}
{{ include "newrelic.common.images.tag" ( dict "imageRoot" .Values.images.integration "context" .) }}
{{- /* For the agent */}}
{{ include "newrelic.common.images.tag" ( dict "imageRoot" .Values.images.agent "context" .) }}
```

### `newrelic.common.images.renderPullSecrets`
If returns a merged map that contains the pull secrets from the global configuration and the local one.  

Usage:
```mustache
{{- /* For jobImage */}}
{{ include "newrelic.common.images.renderPullSecrets" ( dict "pullSecrets" .Values.jobImage.pullSecrets "context" .) }}
{{- /* For the integration */}}
{{ include "newrelic.common.images.renderPullSecrets" ( dict "pullSecrets" .Values.images.pullSecrets "context" .) }}
{{- /* For the agent */}}
{{ include "newrelic.common.images.renderPullSecrets" ( dict "pullSecrets" .Values.images.pullSecrets "context" .) }}
```



## _serviceaccount.tpl
These functions are used to evaluate if the service account should be created, with which name and add annotations to it.

The functions that the common library has implemented for service accounts are:
* `newrelic.common.serviceAccount.create`
* `newrelic.common.serviceAccount.name`
* `newrelic.common.serviceAccount.annotations`

Usage:
```mustache
{{- if include "newrelic.common.serviceAccount.create" . -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  {{- with (include "newrelic.common.serviceAccount.annotations" .) }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
  name: {{ include "newrelic.common.serviceAccount.name" . }}
  namespace: {{ .Release.Namespace }}
{{- end }}
```



## _affinity.tpl, _nodeselector.tpl and _tolerations.tpl
These three files are almost the same and they follow the idiomatic way of `helm create`.

Each function also looks if there is a global value like the other helpers.
```yaml
global:
  affinity: {}
  nodeSelector: {}
  tolerations: []
affinity: {}
nodeSelector: {}
tolerations: []
```

The values here are replaced instead of be merged. If a value at root level is found, the global one is ignored.

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
This returns a YAML that the agent can use directly as a config that includes other options from the values file like verbose mode,
custom attributes, FedRAMP and such.

Usage:
```mustache
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
  name: {{ include newrelic.common.naming.truncateToDNSWithSuffix (dict "name" (include "newrelic.common.naming.fullname" .) suffix "agent-config") }}
  namespace: {{ .Release.Namespace }}
data:
  newrelic-infra.yml: |-
    # This is the configuration file for the infrastructure agent. See:
    # https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings/
    {{- include "newrelic.common.agentConfig.defaults" . | nindent 4 }}
```



## _cluster.tpl
### `newrelic.common.cluster`
Returns the cluster name

Usage:
```mustache
{{ include "newrelic.common.cluster" . }}
```



## _custom-attributes.tpl
### `newrelic.common.customAttributes`
Return custom attributes in YAML format.

Usage:
```mustache
apiVersion: v1
kind: ConfigMap
metadata:
  name: example
data:
  custom-attributes.yaml: |
    {{- include "newrelic.common.customAttributes" . | nindent 4 }}
  custom-attributes.json: |
    {{- include "newrelic.common.customAttributes" . | fromYaml | toJson | nindent 4 }}
```



## _fedramp.tpl
### `newrelic.common.fedramp.enabled`
Returns true if FedRAMP is enabled or an empty string if not. It can be safely used in conditionals as an empty string is a Helm falsiness.

Usage:
```mustache
{{ include "newrelic.common.fedramp.enabled" . }}
```

### `newrelic.common.fedramp.enabled.value`
Returns true if FedRAMP is enabled or false if not. This is to have the value of FedRAMP ready to be templated.

Usage:
```mustache
{{ include "newrelic.common.fedramp.enabled.value" . }}
```



## _license.tpl
### `newrelic.common.license.secretName` and ### `newrelic.common.license.secretKeyName`
Returns the secret and key inside the secret where to read the license key.

The common library will take care of using a user-provided custom secret or creating a secret that contains the license key.

To create the secret use `newrelic.common.license.secret`.

Usage:
```mustache
{{- if and (.Values.controlPlane.enabled) (not (include "newrelic.fargate" .)) }}
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
  - name: agent
    env:
    - name: "NRIA_LICENSE_KEY"
      valueFrom:
        secretKeyRef:
          name: {{ include "newrelic.common.license.secretName" . }}
          key: {{ include "newrelic.common.license.secretKeyName" . }}
```



## _license_secret.tpl
### `newrelic.common.license.secret`
This function templates the secret that is used by agents and integrations with the license Key provided by the user. It will
template nothing (empty string) if the user provides a custom pair of secret name and key.

This template also fails in case the user has not provided any license key or custom secret so no safety checks have to be done
by chart writers.

You just must have a template with these two lines:
```mustache
{{- /* Common library will take care of creating the secret or not. */ -}}
{{- include "newrelic.common.license.secret" . -}}
```



## _low-data-mode.tpl
### `newrelic.common.lowDataMode`
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  lowDataMode:  # Note that this is empty (nil)
lowDataMode:  # Note that this is empty (nil)
```

Be careful: chart writers should NOT PUT ANY VALUE for this library to work properly. If in you
values a `lowdataMode` is defined, the global one is going to be always ignored.

This function returns "true" of "" (empty string) so it can be used for evaluating conditionals.

Usage:
```mustache
{{ include "newrelic.common.lowDataMode" . }}
```



## _privileged.tpl
### `newrelic.common.privileged`
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  privileged:  # Note that this is empty (nil)
privileged:  # Note that this is empty (nil)
```

Be careful: chart writers should NOT PUT ANY VALUE for this library to work properly. If in you
values a `privileged` is defined, the global one is going to be always ignored.

Chart writers could override this and put directly a `true` in the `values.yaml` to override the
default of the common library.

This function returns "true" of "" (empty string) so it can be used for evaluating conditionals.

Usage:
```mustache
{{ include "newrelic.common.privileged" . }}
```

### `newrelic.common.privileged.value`
Returns true if privileged mode is enabled or false if not. This is to have the value of privileged ready to be templated.

Usage:
```mustache
{{ include "newrelic.common.privileged.value" . }}
```



## _proxy.tpl
### `newrelic.common.proxy`
Returns the proxy URL configured by the user. 

Usage:
```mustache
{{ include "newrelic.common.proxy" . }}
```



## _security-context.tpl
Use these functions to share the security context among all charts. Useful in clusters that have security enforcing not to
use the root user (like OpenShift) or users that have an admission webhooks.

The functions are:
* `newrelic.common.securityContext.container`
* `newrelic.common.securityContext.pod`

Usage:
```mustache
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
    spec:
      {{- with include "newrelic.common.securityContext.pod" . }}
      securityContext:
        {{- . | nindent 8 }}
      {{- end }}

      containers:
        - name: example
          {{- with include "nriKubernetes.securityContext.container" . }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
```



## _staging.tpl
### `newrelic.common.nrStaging`
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  nrStaging:  # Note that this is empty (nil)
nrStaging:  # Note that this is empty (nil)
```

Be careful: chart writers should NOT PUT ANY VALUE for this library to work properly. If in you
values a `nrStaging` is defined, the global one is going to be always ignored.

This function returns "true" of "" (empty string) so it can be used for evaluating conditionals.

Usage:
```mustache
{{ include "newrelic.common.nrStaging" . }}
```

### `newrelic.common.nrStaging.value`
Returns true if staging is enabled or false if not. This is to have the staging value ready to be templated.

Usage:
```mustache
{{ include "newrelic.common.nrStaging.value" . }}
```



## _verbose-log.tpl
### `newrelic.common.verboseLog`
Like almost everything in this library, it reads global and local variables:
```yaml
global:
  verboseLog:  # Note that this is empty (nil)
verboseLog:  # Note that this is empty (nil)
```

Be careful: chart writers should NOT PUT ANY VALUE for this library to work properly. If in you
values a `verboseLog` is defined, the global one is going to be always ignored.

Usage:
```mustache
{{ include "newrelic.common.verboseLog" . }}
```

### `newrelic.common.verboseLog.valueAsBoolean`
Returns true if verbose is enabled or false if not. This is to have the verbose value ready to be templated as a boolean

Usage:
```mustache
{{ include "newrelic.common.verboseLog.valueAsBoolean" . }}
```

### `newrelic.common.verboseLog.valueAsInt`
Returns 1 if verbose is enabled or 0 if not. This is to have the verbose value ready to be templated as an integer

Usage:
```mustache
{{ include "newrelic.common.verboseLog.valueAsInt" . }}
```
