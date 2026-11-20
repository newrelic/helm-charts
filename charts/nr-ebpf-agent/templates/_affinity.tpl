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
