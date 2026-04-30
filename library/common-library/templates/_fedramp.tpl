{{- /* Defines the fedRAMP flag */ -}}
{{- define "newrelic.common.fedramp.enabled" -}}
  {{- include "newrelic.common.resolve" (dict "ctx" . "key" "fedramp.enabled") -}}
{{- end -}}


{{- /* Return FedRAMP value directly ready to be templated */ -}}
{{- define "newrelic.common.fedramp.enabled.value" -}}
  {{- include "newrelic.common.fedramp.enabled" . | default "false" -}}
{{- end -}}
