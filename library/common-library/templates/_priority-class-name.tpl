{{- /* Defines the pod priorityClassName */ -}}
{{- define "common.priorityClassName" -}}
{{- if .Values.priorityClassName -}}
{{- .Values.priorityClassName -}}
{{- else if .Values.global -}}
{{- if .Values.global.priorityClassName -}}
{{- .Values.global.priorityClassName -}}
{{- end -}}
{{- end -}}
{{- end -}}
