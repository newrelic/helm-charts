{{/*
This will render custom attributes as a YAML ready to be templated or be used with `fromYaml`.
*/}}
{{- define "newrelic.common.customAttributes" -}}
{{- $customAttributes := dict -}}

{{- $global := index .Values "global" | default dict -}}
{{- if $global.customAttributes -}}
{{- $customAttributes = mergeOverwrite $customAttributes $global.customAttributes -}}
{{- end -}}

{{- if .Values.customAttributes -}}
{{- $customAttributes = mergeOverwrite $customAttributes .Values.customAttributes -}}
{{- end -}}

{{- toYaml $customAttributes -}}
{{- end -}}
