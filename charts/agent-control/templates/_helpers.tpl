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
*/ -}}
{{- define "agent-control.agent-control-deployment.config" -}}
  {{- $config := .Values.agentControlDeployment.chartValues | deepCopy -}}

  {{- if not .Values.agentControlCd.enabled -}}
{{- $_ := set $config "cdRemoteUpdate" false -}}
  {{- else -}}
{{- $existingConfig := (default (dict) $config.config) -}}
{{- $newValues := merge $existingConfig (dict "cdReleaseName" .Values.agentControlCd.releaseName) -}}
{{- $_ := set $config "config" $newValues -}}
  {{- end -}}

  {{- $config | toYaml | b64enc -}}
{{- end -}}
