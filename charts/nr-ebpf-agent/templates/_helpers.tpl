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
Return the licenseKey
*/}}
{{- define "nr-ebpf-agent.licenseKey" -}}
{{- if .Values.global }}
  {{- if .Values.global.licenseKey }}
    {{- .Values.global.licenseKey -}}
  {{ else if .Values.global.insightsKey }}
    {{- .Values.global.insightsKey -}}
  {{ else }}
    {{- .Values.licenseKey | default "" -}}
  {{ end }}
{{- else -}}
    {{- .Values.licenseKey | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretName
*/}}
{{- define "nr-ebpf-agent.customSecretName" -}}
{{- if .Values.global }}
    {{- .Values.global.customSecretName | default "" -}}
{{- else -}}
    {{- "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretLicenseKey
*/}}
{{- define "nr-ebpf-agent.customSecretKey" -}}
{{- if .Values.global }}
    {{- .Values.customSecretLicenseKey | default "" -}}
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
