{{- /* Defines the container securityContext context */ -}}
{{- define "common.securityContext.container" -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.containerSecurityContext -}}
    {{- toYaml .Values.containerSecurityContext -}}
{{- else if $global.containerSecurityContext -}}
    {{- toYaml $global.containerSecurityContext -}}
{{- end -}}
{{- end -}}


{{- /* Defines the pod securityContext context */ -}}
{{- define "common.securityContext.pod" -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.podSecurityContext -}}
    {{- toYaml .Values.podSecurityContext -}}
{{- else if $global.podSecurityContext -}}
    {{- toYaml $global.podSecurityContext -}}
{{- end -}}
{{- end -}}
