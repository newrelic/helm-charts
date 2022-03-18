{{- /* Defines the container securityContext context */ -}}
{{- define "common.securityContext.container" -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.containerSecurityContext -}}
    {{- toYaml .Values.containerSecurityContext -}}
{{- else if $global.containerSecurityContext -}}
    {{- toYaml $global.containerSecurityContext -}}
{{- else -}}
    {{- include "common.securityContext.containerDefaults" . -}}
{{- end -}}
{{- end -}}


{{- /* Allows to change defaults for container security context either staic of dinamically */ -}}
{{- define "common.securityContext.containerDefaults" -}}
{{- end -}}


{{- /* Defines the pod securityContext context */ -}}
{{- define "common.securityContext.pod" -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.podSecurityContext -}}
    {{- toYaml .Values.podSecurityContext -}}
{{- else if $global.podSecurityContext -}}
    {{- toYaml $global.podSecurityContext -}}
{{- else -}}
    {{- include "common.securityContext.podDefaults" . -}}
{{- end -}}
{{- end -}}


{{- /* Allows to change defaults for pod security context either staic of dinamically */ -}}
{{- define "common.securityContext.podDefaults" -}}
{{- end -}}
