{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "apm-php-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apm-php-agent.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "apm-php-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "apm-php-agent.labels" -}}
app.kubernetes.io/name: {{ include "apm-php-agent.name" . }}
helm.sh/chart: {{ include "apm-php-agent.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "apm-php-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "apm-php-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apm-php-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apm-php-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the statsd metric tags
*/}}
{{- define "apm-php-agent.statsdMetricTags" -}}

{{- range $k, $v := .Values.metricTags -}}
{{- $joinTags := (printf "%v:%v " $k $v) -}}
{{- $joinTags -}}
{{- end -}}
{{- end -}}

{{/*
Return the insightsKey
*/}}
{{- define "apm-php-agent.insightsKey" -}}
{{- if .Values.global}}
  {{- if .Values.global.insightsKey }}
      {{- .Values.global.insightsKey -}}
  {{- else -}}
      {{- .Values.insightsKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.insightsKey | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the cluster
*/}}
{{- define "apm-php-agent.cluster" -}}
{{- if .Values.global -}}
  {{- if .Values.global.cluster -}}
      {{- .Values.global.cluster -}}
  {{- else -}}
      {{- .Values.cluster | default "" -}}
  {{- end -}}
{{- else -}}
  {{- .Values.cluster | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Returns nrStaging
*/}}
{{- define "newrelic.nrStaging" -}}
{{- if .Values.global }}
  {{- if .Values.global.nrStaging }}
    {{- .Values.global.nrStaging -}}
  {{- end -}}
{{- else if .Values.nrStaging }}
  {{- .Values.nrStaging -}}
{{- end -}}
{{- end -}}

{{/*
Returns if the template should render, it checks if the required value cluster is set.
*/}}
{{- define "apm-php-agent.areValuesValid" -}}
{{- $cluster := include "apm-php-agent.cluster" . -}}
{{- and $cluster}}
{{- end -}}
