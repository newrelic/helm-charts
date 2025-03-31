{{- /*
A helper to return the pod security context to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.securityContext.pod" -}}
{{- if .Values.deployment.podSecurityContext -}}
    {{- toYaml .Values.deployment.podSecurityContext -}}
{{- else if include "newrelic.common.securityContext.pod" . -}}
    {{- include "newrelic.common.securityContext.pod" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the container security context to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.securityContext.container" -}}
{{- if .Values.deployment.containerSecurityContext -}}
    {{- toYaml .Values.deployment.containerSecurityContext -}}
{{- else if include "newrelic.common.securityContext.container" . -}}
    {{- include "newrelic.common.securityContext.container" . -}}
{{- end -}}
{{- end -}}