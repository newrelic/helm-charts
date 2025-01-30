{{- /*
A helper to return the affinity to apply to the ebpf daemonset.
*/ -}}
{{- define "nrEbpfAgent.ebpfAgent.affinity" -}}
{{- if .Values.ebpfAgent.affinity -}}
    {{- toYaml .Values.ebpfAgent.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
    {{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the affinity to apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.affinity" -}}
{{- if .Values.otelCollector.affinity -}}
    {{- toYaml .Values.otelCollector.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
    {{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}