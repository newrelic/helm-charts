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

{{- /*
A helper to return the nodeSelector to apply to the daemonset.
*/ -}}
{{- define "nrKubernetesOtel.daemonset.nodeSelector" -}}
{{- if .Values.daemonset.nodeSelector -}}
    {{- toYaml .Values.daemonset.nodeSelector -}}
{{- else if include "newrelic.common.nodeSelector" . -}}
    {{- include "newrelic.common.nodeSelector" . -}}
{{- end -}}
{{- end -}}