{{- /* Defines the fedRAMP flag */ -}}
{{- define "common.fedramp.enabled" -}}
{{- if .Values.fedramp -}}
{{- if .Values.fedramp.enabled -}}
{{- .Values.fedramp.enabled -}}
{{- end -}}
{{- else if .Values.global -}}
{{- if .Values.global.fedramp -}}
 {{- if .Values.global.fedramp.enabled -}}
{{- .Values.global.fedramp.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
