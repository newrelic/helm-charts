{{- /*
A helper to return the tolerations to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.tolerations" -}}
{{- if .Values.deployment.tolerations -}}
    {{- toYaml .Values.deployment.tolerations -}}
{{- else if include "newrelic.common.tolerations" . -}}
    {{- include "newrelic.common.tolerations" . -}}
{{- end -}}
{{- end -}}