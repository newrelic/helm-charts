{{/* resolve
Used to lookup generic values that can be overridden at the global or chart level. Resolve will first check if the value is set at the chart level, then it will check if the value is set at the global level.
If the value is not set at either level, it will return an empty string.

We have this exact logic implemented in multiple places across the charts, so we are centralizing it here to avoid duplication
and to enforce a consistent override pattern across the charts.

Hierarchy should be: values → global values → defaults.

use:
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "myKey") -}}

example:
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "collector_endpoint") -}}
*/}}

{{- define "newrelic.common.resolve" -}}
  {{- $ctx := .ctx -}}
  {{- $keys := splitList "." .key -}}
  {{- $root := $ctx.Values | default $ctx -}}

  {{- $val := $root -}}
  {{- range $keys -}}
    {{- if $val -}}
      {{- $val = index $val . -}}
    {{- end -}}
  {{- end -}}

  {{- if $val -}}
    {{- $val -}}
  {{- else if $root.global -}}
    {{- include "newrelic.common.resolve" (dict "ctx" $root.global "key" .key) -}}
  {{- end -}}
{{- end -}}


{{- define "newrelic.common.resolve_or" -}}
  {{- include "newrelic.common.resolve" (dict "ctx" .ctx "key" .key) | default .default -}}
{{- end -}}
