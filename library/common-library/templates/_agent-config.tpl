{{/*
This helper should return the defaults that the agent should take for all the Helm chart
*/}}
{{- define "common.agentConfig.defaults" -}}
{{- if include "common.verboseLog" . }}
verbose: 1
{{- end }}
{{- if (include "common.nrStaging" .) }}
staging: true
{{- end }}
{{- with include "common.proxy" . }}
proxy: {{ . | quote }}
{{- end }}
{{- end -}}



{{/*
This helper allow to override the defaults that this common-library adds to all the agents.
*/}}
{{- define "common.agentConfig.defaults.override" -}}
{{/* **********************************************************************************
***************************************************************************************
THIS IS AN EXAMPLE OF HOW THE CONFIG DEFAULS SHOULD GO.
This should not touch main/master because it has things that could break all the charts
that use this library.
nri-kubernetes has been taken as an example with the variables that it has hascoded.
***************************************************************************************
********************************************************************************** */}}
features: "docker_enabled:false"

httpServerEnabled: true
httpServerPort: 8003

passthroughEnvironment: CLUSTER_NAME

{{- if .Values.enableProcessMetrics | kindIs "bool" }}
EnableProcessMetrics: {{ .Values.enableProcessMetrics | quote }}
{{- end }}
{{- end -}}



{{/*
This overrides everything that defaults and user have put in the configuration.

THIS ALSO OVERRIDES USER'S PREFERENCES. USE WITH CARE.
*/}}
{{- define "common.agentConfig.override" -}}
{{/* **********************************************************************************
***************************************************************************************
THIS IS AN EXAMPLE OF HOW THE CONFIG DEFAULS SHOULD GO.
This should not touch main/master because it has things that could break all the charts
that use this library.
nri-kubernetes has been taken as an example with the variables that it has hascoded.
***************************************************************************************
********************************************************************************** */}}
overrideHostRoot: ""
forwardOnly: true
isSecureForwardOnly: true
{{- end -}}



{{/*
This render the YAML needed for the agent to run.

This helper is for internal use.

Should be called with something like this:
{{- agentConfigContext := dict
        "global"  .Values.global.pathToAgentConfig
        "local"   .Values.pathToAgentConfig
        "context" .
 }}
{{- include "common.agentConfig._toYaml" $agentConfigContext }}
*/}}
{{- define "common.agentConfig._toYaml" -}}
{{- $agentConfig := fromYaml (include "common.agentConfig.defaults" .context ) -}}
{{- /* It merges from RIGHT to left */ -}}
{{- $agentConfig = mustMergeOverwrite (fromYaml (include "common.agentConfig.defaults.override" .context )) $agentConfig -}}
{{- $agentConfig = mustMergeOverwrite .global $agentConfig -}}
{{- $agentConfig = mustMergeOverwrite .local $agentConfig -}}
{{- $agentConfig = mustMergeOverwrite (fromYaml (include "common.agentConfig.override" .context )) $agentConfig -}}

{{- toYaml $agentConfig -}}
{{- end -}}
