{{- define "agent-control.release.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Release.Name "suffix" "deployment") }}
{{- end -}}

{{- define "agent-control.secret.name" -}}
  {{ include "agent-control.release.name" . }}
{{- end -}}
