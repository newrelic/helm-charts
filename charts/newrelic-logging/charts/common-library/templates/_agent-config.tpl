{{/*
This helper should return the defaults that all agents should have
*/}}
{{- define "newrelic.common.agentConfig.defaults" -}}
{{- if include "newrelic.common.verboseLog" . }}
log:
  level: trace
{{- end }}

{{- if (include "newrelic.common.nrStaging" . ) }}
staging: true
{{- end }}

{{- with include "newrelic.common.proxy" . }}
proxy: {{ . | quote }}
{{- end }}

{{- with include "newrelic.common.fedramp.enabled" . }}
fedramp: {{ . }}
{{- end }}

{{- with fromYaml ( include "newrelic.common.customAttributes" . ) }}
custom_attributes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
