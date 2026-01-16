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
{{- printf "dns:///%s.%s.svc.%s:%v" (include "otel-collector.service.name" .) .Release.Namespace .Values.kubernetesClusterDomain .Values.otelCollector.receiverPort }}
{{- end }}

{{/*
Validates that user-provided tags don't contain "agent-" prefix for chart version >= 0.4.0
Also validates agent version compatibility for chart version >= 1.0.0
*/}}
{{- define "nr-ebpf-agent.imageTag" -}}
{{- $imageTag := "" -}}
{{- if .Values.ebpfAgent.image.tag -}}
  {{- if semverCompare ">=0.4.0" .Chart.Version -}}
    {{- if hasPrefix "agent-" .Values.ebpfAgent.image.tag -}}
      {{- fail (printf "Error: For chart version %s (>=0.4.0), the ebpfAgent.image.tag should not contain 'agent-' prefix. Please use image tags that do not contain the prefix." .Chart.Version) -}}
    {{- end -}}
    {{- $imageTag = .Values.ebpfAgent.image.tag -}}
  {{- else -}}
    {{- $imageTag = .Values.ebpfAgent.image.tag -}}
  {{- end -}}
{{- else -}}
  {{- if semverCompare ">=0.4.0" .Chart.Version -}}
    {{- $imageTag = .Chart.AppVersion -}}
  {{- else -}}
    {{- $imageTag = printf "agent-%s" .Chart.AppVersion -}}
  {{- end -}}
{{- end -}}
{{- if and (semverCompare ">=1.0.0" .Chart.Version) (not .Values.skipVersionValidation) -}}
  {{- include "nr-ebpf-agent.validateVersion" (dict "tag" $imageTag "chartVersion" .Chart.Version "appVersion" .Chart.AppVersion) -}}
{{- end -}}
{{- $imageTag -}}
{{- end -}}

{{/*
Validate agent version compatibility at template rendering time
For chart version >= 1.0.0, ensure agent version >= 1.0.0
Extracts version from image tag and compares using semver
*/}}
{{- define "nr-ebpf-agent.validateVersion" -}}
{{- $tag := .tag -}}
{{- $chartVersion := .chartVersion -}}
{{- $appVersion := .appVersion -}}
{{- $minVersion := "1.0.0" -}}
{{- $agentVersion := "" -}}

{{- /* Try to extract semantic version from tag */ -}}
{{- if regexMatch "^v?[0-9]+\\.[0-9]+\\.[0-9]+" $tag -}}
  {{- /* Extract X.Y.Z from patterns like "0.5.0", "v0.5.0", "0.5.0-beta", etc */ -}}
  {{- $agentVersion = regexFind "^v?([0-9]+\\.[0-9]+\\.[0-9]+)" $tag | trimPrefix "v" -}}
{{- else if eq $tag $appVersion -}}
  {{- /* If tag equals appVersion, use appVersion directly */ -}}
  {{- $agentVersion = $appVersion -}}
{{- else -}}
  {{- /* Cannot parse version from custom tag - fail with helpful message */ -}}
  {{- fail (printf "\nError: Chart version %s requires agent version >= %s.\n\nCannot determine agent version from image tag '%s'.\n\nRESOLUTION:\n  1. Use a semantic version tag (e.g., '1.0.0', '0.7.0')\n  2. Remove the image tag to use Chart.AppVersion (%s)\n\nFor more information:\n  https://github.com/newrelic/helm-charts/tree/master/charts/nr-ebpf-agent\n" $chartVersion $minVersion $tag $appVersion) -}}
{{- end -}}

{{- /* Validate extracted version is >= minimum required version */ -}}
{{- if not (semverCompare (printf ">=%s" $minVersion) $agentVersion) -}}
  {{- fail (printf "\n================================================================================\nERROR: INCOMPATIBLE AGENT VERSION\n================================================================================\n\nChart Version:    %s\nAgent Version:    %s (from tag: %s)\nRequired Version: >= %s\n\nChart version %s removed OpenTelemetry collector support and requires\nagent version >= %s.\n\nRESOLUTION:\n  1. Update ebpfAgent.image.tag to version >= %s\n     OR\n  2. Remove custom image tag to use Chart.AppVersion (%s)\n\nFor more information:\n  https://github.com/newrelic/helm-charts/tree/master/charts/nr-ebpf-agent\n\n================================================================================\n" $chartVersion $agentVersion $tag $minVersion $chartVersion $minVersion $minVersion $appVersion) -}}
{{- end -}}
{{- end -}}

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
Validate that receiverPort is not less than 1024 (privileged port range).
*/}}
{{- define "validate.receiverPort" -}}
{{- $port := .Values.otelCollector.receiverPort | int -}}
{{- if lt $port 1025 -}}
{{- fail (printf "Error: receiverPort must be > 1024 (got %d). Ports below 1024 are privileged ports and should not be used." $port) -}}
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
Generate environment variables for protocols configuration including enabled/disabled state and sampling latency.
*/}}
{{- define "generateClientScriptEnvVars" -}}
{{- if .Values.protocols }}
{{- range $protocol, $config := .Values.protocols }}
  {{- if ne $protocol "global" }}
  {{- if (hasKey $config "enabled") }}
- name: PROTOCOLS_{{ upper $protocol }}_ENABLED
  value: "{{ $config.enabled }}"
  {{- end }}
  {{- if (hasKey $config "spans") }}
    {{- if (hasKey $config.spans "enabled") }}
- name: PROTOCOLS_{{ upper $protocol }}_SPANS_ENABLED
  value: "{{ $config.spans.enabled }}"
    {{- end }}
    {{- if and (eq $config.spans.enabled true) (hasKey $config.spans "samplingLatency") }}
      {{- include "validate.samplingLatency" (dict "protocol" $protocol "latency" $config.spans.samplingLatency) }}
- name: PROTOCOLS_{{ upper $protocol }}_SPANS_SAMPLING_LATENCY
  value: "{{ $config.spans.samplingLatency | regexMatch "p1|p10|p50|p90|p99" | ternary $config.spans.samplingLatency "" }}"
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}