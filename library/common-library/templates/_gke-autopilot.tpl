{{/*
Returns gkeAutopilot
*/}}
{{- define "newrelic.common.gkeAutopilot" -}}
{{- if (or .Values.global.gkeAutopilot .Values.gkeAutopilot) -}}
{{- default .Values.global.gkeAutopilot .Values.gkeAutopilot -}}
{{- end -}}
{{- end -}}
