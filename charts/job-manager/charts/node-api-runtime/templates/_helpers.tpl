{{/*
Expand the name of the chart.
*/}}
{{- define "node-api-runtime.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "node-api-runtime.fullname" -}}
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
{{- define "node-api-runtime.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allows to override the appVersion to use.
*/}}
{{- define "node-api-runtime.appVersion" -}}
{{- default .Chart.AppVersion .Values.appVersionOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allows overriding of the synthetics-job-manager Service hostname
*/}}
{{- define "synthetics-job-manager.hostname" -}}
{{- default "synthetics-job-manager" .Values.global.hostnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "node-api-runtime.labels" -}}
helm.sh/chart: {{ include "node-api-runtime.chart" . }}
{{ include "node-api-runtime.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "node-api-runtime.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-api-runtime.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod annotations
*/}}
{{- define "node-api-runtime.podAnnotations" -}}
{{- if or .Values.appArmorProfileName .Values.annotations -}}
annotations:
{{- if .Values.appArmorProfileName }}
  container.apparmor.security.beta.kubernetes.io/{{ .Chart.Name }}: localhost/{{ .Values.appArmorProfileName }}
{{- end }}
{{- range $key, $val := .Values.annotations }}
  {{ $key }}: {{ $val | quote }}
{{- end }}
{{- end -}}
{{- end -}}
