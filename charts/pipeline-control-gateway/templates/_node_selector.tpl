{{- /*
A helper to return the nodeSelector to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.nodeSelector" -}}
{{- if .Values.deployment.nodeSelector -}}
    {{- toYaml .Values.deployment.nodeSelector -}}
{{- else if include "newrelic.common.nodeSelector" . -}}
    {{- include "newrelic.common.nodeSelector" . -}}
{{- end -}}
{{- end -}}