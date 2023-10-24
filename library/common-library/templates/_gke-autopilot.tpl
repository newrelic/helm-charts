{{/*
Returns gkeAutopilot
*/}}
{{- define "newrelic.common.gkeAutopilot" -}}
{{- coalesce .Values.global.gkeAutopilot .Values.gkeAutopilot }}
{{- end -}}
