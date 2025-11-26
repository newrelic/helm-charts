{{- define "agent-control-deployment.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Values.agentControlDeployment.releaseName "suffix" "local") }}
{{- end -}}

{{- define "agent-control-cd.secret.name" -}}
  {{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" .Values.agentControlCd.releaseName "suffix" "local") }}
{{- end -}}

{{- /*
Generates the configuration for agent-control-deployment (to be stored in the corresponding secret) applying required
overrides:
  -  `cdRemoteUpdate` is set to false if `.Values.agentControlCd.enabled` is false.
  -  `cdReleaseName` is set to `.Values.agentControlCd.releaseName` if `.Values.agentControlCd.enabled` is true.
*/ -}}
{{- define "agent-control.agent-control-deployment.config" -}}
  {{- $config := .Values.agentControlDeployment.chartValues | deepCopy -}}

  {{- if .Values.agentControlCd.enabled -}}
    {{- $config = mustMergeOverwrite $config (dict "config" (dict "cdReleaseName" .Values.agentControlCd.releaseName)) -}}
  {{- else -}}
    {{- $config = mustMergeOverwrite $config (dict "config" (dict "cdRemoteUpdate" false "cdReleaseName" "")) -}}
  {{- end -}}

  {{- $authSecret := (default dict .Values.config).authSecret | default dict -}}
  {{- $sName := $authSecret.secretName | default "agent-control-auth" -}}
  {{- $sKey  := $authSecret.secretKeyName | default "private_key" -}}

  {{- $secretObj := dict "secret_name" $sName "secret_key_name" $sKey -}}

  {{- $config = mustMergeOverwrite $config (dict "config" (dict "auth_secret" $secretObj)) -}}

  {{- $config | toYaml | b64enc -}}
{{- end -}}