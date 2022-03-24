{{/*
This helper should return the defaults that all agents should have
*/}}
{{- define "common.agentConfig.defaults" -}}
{{- if include "common.verboseLog" . }}
verbose: 1
{{- end }}
{{- if (include "common.nrStaging" . ) }}
staging: true
{{- end }}
{{- with include "common.proxy" . }}
proxy: {{ . | quote }}
{{- end }}
{{- with include "common.fedramp.enabled" . }}
fedramp: {{ . }}
{{- end }}
{{- end -}}
