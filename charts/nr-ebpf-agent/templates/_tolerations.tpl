{{- /*
A helper to return the tolerations to apply to the ebpf daemonset.
*/ -}}
{{- define "nrEbpfAgent.ebpfAgent.tolerations" -}}
{{- if .Values.ebpfAgent.tolerations -}}
    {{- toYaml .Values.ebpfAgent.tolerations -}}
{{- else if include "newrelic.common.tolerations" . -}}
    {{- include "newrelic.common.tolerations" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the tolerations for the nrdot CLUSTER collector (Deployment).
Unlike the per-node DaemonSet, this is a single pod that only needs one schedulable
node, so it deliberately does NOT fall through to the tolerate-all default. It emits
tolerations only when nrdotCollector.clusterCollector.tolerations is explicitly set.
*/ -}}
{{- define "nrEbpfAgent.clusterCollector.tolerations" -}}
{{- with .Values.nrdotCollector.clusterCollector.tolerations -}}
    {{- toYaml . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the tolerations to apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.tolerations" -}}
{{- if .Values.otelCollector.tolerations -}}
    {{- toYaml .Values.otelCollector.tolerations -}}
{{- else if include "newrelic.common.tolerations" . -}}
    {{- include "newrelic.common.tolerations" . -}}
{{- end -}}
{{- end -}}