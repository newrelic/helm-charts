{{- define "agent-control.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Release.Name "suffix" "deployment") }}
{{- end -}}
