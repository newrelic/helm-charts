{{- /*
A helper to return the affinity to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.affinity" -}}
{{- if .Values.deployment.affinity -}}
    {{- toYaml .Values.deployment.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
    {{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}
