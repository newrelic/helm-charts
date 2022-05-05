{{/*
This will render the annotations that should be used in all the deployments and daemonsets.
*/}}
{{- define "newrelic.common.annotations.deployment" -}}
{{- $global := index .Values "global" | default dict -}}

{{- $globalDeploymentAnnotations := $global.deploymentAnnotations | default dict -}}
{{- $localDeploymentAnnotations := .Values.deploymentAnnotations | default dict -}}

{{- $annotations := mustMergeOverwrite $globalDeploymentAnnotations $localDeploymentAnnotations -}}

{{- toYaml $annotations -}}
{{- end -}}



{{/*
This will render the annotations that should be used in all the pods.
*/}}
{{- define "newrelic.common.annotations.pod" -}}
{{- $global := index .Values "global" | default dict -}}

{{- $globalPodAnnotations := $global.podAnnotations | default dict }}
{{- $localPodAnnotations := .Values.podAnnotations | default dict }}

{{- $podAnnotations := mustMergeOverwrite $globalPodAnnotations $localPodAnnotations -}}

{{- toYaml $podAnnotations -}}
{{- end }}
