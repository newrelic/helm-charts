{{- /*
A helper to return the affinity to apply to the deployment.
*/ -}}
{{- define "nrKubernetesOtel.deployment.affinity" -}}
{{- if .Values.statefulset.affinity -}}
{{- toYaml .Values.statefulset.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
{{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the affinity to apply to the daemonset.
*/ -}}
{{- define "nrKubernetesOtel.daemonset.affinity" -}}
{{- if .Values.daemonset.affinity -}}
{{- toYaml .Values.daemonset.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
{{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}
