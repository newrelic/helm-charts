{{- /*
A helper to return the pod security context  apply to the ebpf daemonset.
*/ -}}
{{- define "nrEbpfAgent.ebpfAgent.securityContext.pod" -}}
{{- if .Values.ebpfAgent.podSecurityContext -}}
    {{- toYaml .Values.ebpfAgent.podSecurityContext -}}
{{- else if include "newrelic.common.securityContext.pod" . -}}
    {{- include "newrelic.common.securityContext.pod" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the pod security context  apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.securityContext.pod" -}}
{{- if .Values.otelCollector.podSecurityContext -}}
    {{- toYaml .Values.otelCollector.podSecurityContext -}}
{{- else if include "newrelic.common.securityContext.pod" . -}}
    {{- include "newrelic.common.securityContext.pod" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the container security context  apply to the ebpf daemonset.
*/ -}}
{{- define "nrEbpfAgent.ebpfAgent.securityContext.container" -}}
{{- if .Values.ebpfAgent.containerSecurityContext -}}
    {{- toYaml .Values.ebpfAgent.containerSecurityContext -}}
{{- else if include "newrelic.common.securityContext.container" . -}}
    {{- include "newrelic.common.securityContext.container" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the container security context  apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.securityContext.container" -}}
{{- if .Values.otelCollector.containerSecurityContext -}}
    {{- toYaml .Values.otelCollector.containerSecurityContext -}}
{{- else if include "newrelic.common.securityContext.container" . -}}
    {{- include "newrelic.common.securityContext.container" . -}}
{{- end -}}
{{- end -}}