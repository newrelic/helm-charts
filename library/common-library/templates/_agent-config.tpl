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

{{- with include "common.license._licenseKey" . }}
{{- /* We will mostly override this using a environment variable but we can have it here just in case */}}
license: {{ . }}
{{- end }}

{{- with include "common.proxy" . }}
proxy: {{ . | quote }}
{{- end }}

{{- with include "common.fedramp.enabled" . }}
fedramp: {{ . }}
{{- end }}

{{- with include "common.customAttributes" . }}
custom_attributes:
  {{- . | nindent 2 }}
{{- end }}
{{- end -}}
