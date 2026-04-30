{{/* resolve
Used to lookup generic values that can be overridden at the global or chart level. Resolve will first check if the value is set at the chart level, then it will check if the value is set at the global level.
If the value is not set at either level, it will return an empty string.

We have this exact logic implemented in multiple places across the charts, so we are centralizing it here to avoid duplication
and to enforce a consistent override pattern across the charts.

Hierarchy should be: values → global values → defaults.

use:
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "myKey" ) -}}
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "myKey" "default" "defaulValue" ) -}}

examples:
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "collector_endpoint") -}}
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "collector_endpoint" "default" "some value") -}}
*/}}

{{- define "newrelic.common.resolve" -}}
  {{- $ctx := .ctx -}}
  {{- $keys := splitList "." .key -}}
  {{- $root := $ctx.Values | default $ctx -}}

  {{- $value := $root -}}
  {{- range $keys -}}
    {{- if ($value) -}}
      {{- $value = index $value . -}}
    {{- else -}}
      {{- $value = "" -}}
    {{- end -}}
  {{- end -}}

  {{- if ($value) -}}
    {{- $value -}}
  {{- else if (kindIs "bool" $value) -}}
    {{/* If we get here, we know $value is a falsy bool, so let's return a falsy statement */}}
  {{- else if $root.global -}}
    {{- include "newrelic.common.resolve" (dict "ctx" $root.global "key" .key) -}}
  {{- else if .default -}}
    .default
  {{- end -}}
{{- end -}}
