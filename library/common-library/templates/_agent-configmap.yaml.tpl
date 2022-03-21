{{/*
Renders the agent's configuration file inside a configMap ready to be used

Should be called with something like this:
{{- agentConfigContext := dict
        "global"  .Values.global.pathToAgentConfig
        "local"   .Values.pathToAgentConfig
        "name"    (printf "%s-NameOfConfigMap" (include "common.naming.fullname" .))
        "context" .
 }}
{{- include "common.agentConfig._toYaml" $agentConfigContext }}
*/}}
{{- define "common.agentConfig.configMap" }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    {{- include "common.labels" .context | nindent 4 }}
  name: {{ .name }}
  namespace: {{ .context.Release.Namespace }}
data:
  {{- include "common.agentConfig._toYaml" . | nindent 2 }}
{{- end }}
