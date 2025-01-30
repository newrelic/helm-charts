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
A helper to return the tolerations to apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.tolerations" -}}
{{- if .Values.otelCollector.tolerations -}}
    {{- toYaml .Values.otelCollector.tolerations -}}
{{- else if include "newrelic.common.tolerations" . -}}
    {{- include "newrelic.common.tolerations" . -}}
{{- end -}}
{{- end -}}