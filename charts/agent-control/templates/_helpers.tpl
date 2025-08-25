{{- define "agent-control-deployment.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Release.Name "suffix" "deployment-local") }}
{{- end -}}

{{- define "agent-control-cd.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Release.Name "suffix" "cd-local") }}
{{- end -}}

{{- /*
Generates the configuration for agent-control-deployment (to be stored in the corresponding secret) applying required
overrides:
  -  `cdRemoteUpdate` is set to false if `.Values.agentControlCd.enabled` is false.
*/ -}}
{{- define "agent-control.agent-control-deployment.config" -}}
  {{- $config := .Values.agentControlDeployment.chartValues | deepCopy -}}

  {{- if not .Values.agentControlCd.enabled -}}
{{- $_ := set $config "cdRemoteUpdate" false -}}
  {{- end -}}

  {{- $config | toYaml | b64enc -}}
{{- end -}}
