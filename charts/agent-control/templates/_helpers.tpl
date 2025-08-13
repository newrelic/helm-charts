{{- define "agent-control.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Release.Name "suffix" "deployment") }}
{{- end -}}


{{/*
Generates the configuration for agent-control-deployment.yaml, applying the override logic for cdRemoteUpdate before encoding.
*/}}
{{- define "agent-control.agent-control-deployment.config" -}}
  {{- $config := (index .Values "agent-control-deployment") | deepCopy -}}

  {{- if not (index .Values "agent-control-cd").flux2.enabled -}}
    {{- $_ := set $config "cdRemoteUpdate" false -}}
  {{- end -}}

  {{- $config | toYaml | b64enc -}}
{{- end -}}
