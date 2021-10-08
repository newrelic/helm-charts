{{/*
Expand the name of the chart.
*/}}
{{- define "otel-k8s-prometheus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otel-k8s-prometheus.fullname" -}}
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
{{- define "otel-k8s-prometheus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "otel-k8s-prometheus.labels" -}}
helm.sh/chart: {{ include "otel-k8s-prometheus.chart" . }}
{{ include "otel-k8s-prometheus.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "otel-k8s-prometheus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "otel-k8s-prometheus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "otel-k8s-prometheus.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "otel-k8s-prometheus.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the cluster name
*/}}
{{- define "newrelic.clusterGlobal" -}}
{{- if .Values.cluster -}}
  {{- .Values.cluster -}}
{{- else if .Values.global -}}
  {{- if .Values.global.cluster -}}
    {{- .Values.global.cluster -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the cluster name
*/}}
{{- define "newrelic.cluster" -}}
{{ include "newrelic.clusterGlobal" . | default (include "otel-k8s-prometheus.fullname" . ) }}
{{- end -}}

{{/*
Return local licenseKey if set, global otherwise
*/}}
{{- define "newrelic.licenseKey" -}}
{{- if .Values.licenseKey -}}
  {{- .Values.licenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.licenseKey -}}
    {{- .Values.global.licenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseCustomSecretName" -}}
{{- if .Values.customSecretName -}}
  {{- .Values.customSecretName -}}
{{- else if and .Values.global -}}
  {{- if .Values.global.customSecretName -}}
    {{- .Values.global.customSecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseSecretName" -}}
{{ include "newrelic.licenseCustomSecretName" . | default (printf "%s-license" (include "otel-k8s-prometheus.fullname" . )) }}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseCustomSecretKey" -}}
{{- if .Values.customSecretLicenseKey -}}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseSecretKey" -}}
{{ include "newrelic.licenseCustomSecretKey" . | default "licenseKey" }}
{{- end -}}
