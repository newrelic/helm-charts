{{/*
Expand the name of the chart.
*/}}
{{- define "nr-ebpf-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nr-ebpf-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nr-ebpf-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nr-ebpf-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nr-ebpf-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the cluster name
*/}}
{{- define "nr-ebpf-agent.clusterName" -}}
{{- if .Values.global }}
   {{- .Values.global.cluster | default "" -}}
{{- else -}}
    {{- "" -}}
{{- end -}}
{{- end -}}




{{/*
Create otel collector receiver endpoint
*/}}
{{- define "nr-otel-collector-receiver.endpoint" -}}
{{- printf "dns:///%s.%s.svc.%s:4317" (include "otel-collector.service.name" .) .Release.Namespace .Values.kubernetesClusterDomain }}
{{- end }}

{{/*
Validate the user inputted quantile when sampling by latency.
*/}}
{{- define "validate.samplingLatency" -}}
{{- $validOptions := list "" "p1" "p10" "p50" "p90" "p99" -}}
{{- $protocol := .protocol -}}
{{- $latency := .latency -}}
{{- if not (has $latency $validOptions) -}}
{{- fail (printf "Invalid samplingLatency '%s' for protocol '%s'. Valid options are: %v" $latency $protocol $validOptions) -}}
{{- end -}}
{{- end -}}

{{/*
Validate the user inputted value when sampling by error rate.
*/}}
{{- define "validate.samplingErrorRate" -}}
{{- $protocol := .protocol -}}
{{- $errorRateString := .errorRate -}}
{{- $errorRate := .errorRate | int -}}
{{- if or (lt $errorRate 1) (gt $errorRate 100) -}}
{{- fail (printf "Invalid samplingErrorRate '%s' for protocol '%s'. Valid range is between 1 and 100" $errorRateString $protocol) -}}
{{- end -}}
{{- end -}}

{{/*
Pass environment variables to the agent container if tracing a specific protocol is to be disabled.
*/}}
{{- define "generateTracingEnvVars" -}}
{{- range $protocol, $config := .Values.protocols }}
  {{- $protocolEnabled := false }}
  {{- if (hasKey $config "enabled") }}
    {{- $protocolEnabled = eq $config.enabled true }}
  {{- end }}
  {{- if eq $protocolEnabled false }}
- name: PROTOCOLS_{{ upper $protocol }}_ENABLED
  value: "false"
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Generate environment variables for disabling protocols and setting sampling latency.
*/}}
{{- define "generateClientScriptEnvVars" -}}
{{- if .Values.protocols }}
{{- range $protocol, $config := .Values.protocols }}
  {{- if (hasKey $config "enabled") }}
    {{- if eq $config.enabled false }}
- name: PROTOCOLS_{{ upper $protocol }}_ENABLED
  value: "false"
- name: PROTOCOLS_{{ upper $protocol }}_SPANS_ENABLED
  value: "false"
    {{- else if eq $config.enabled true }}
      {{- if (hasKey $config "spans") }}
        {{- if (eq $config.spans.enabled false) }}
- name: PROTOCOLS_{{ upper $protocol }}_SPANS_ENABLED
  value: "false"
        {{- end }}  
      {{- if (eq $config.spans.enabled true) }}
      {{- include "validate.samplingLatency" (dict "protocol" $protocol "latency" $config.spans.samplingLatency) }}
- name: PROTOCOLS_{{ upper $protocol }}_SPANS_SAMPLING_LATENCY
  value: "{{ $config.spans.samplingLatency | regexMatch "p1|p10|p50|p90|p99" | ternary $config.spans.samplingLatency "" }}"
      {{- end }}
    {{- end }}
  {{- end }} 
{{- end }}
{{- end }}
{{- end }}
{{- end }}