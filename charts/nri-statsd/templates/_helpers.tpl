{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nri-statsd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nri-statsd.fullname" -}}
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
{{- define "nri-statsd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "nri-statsd.labels" -}}
app.kubernetes.io/name: {{ include "nri-statsd.name" . }}
helm.sh/chart: {{ include "nri-statsd.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "nri-statsd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nri-statsd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nri-statsd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nri-statsd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the statsd metric tags
*/}}
{{- define "nri-statsd.statsdMetricTags" -}}

{{- range $k, $v := .Values.metricTags -}}
{{- $joinTags := (printf "%v:%v " $k $v) -}}
{{- $joinTags -}}
{{- end -}}
{{- end -}}

{{/*
Return the insightsKey
*/}}
{{- define "nri-statsd.insightsKey" -}}
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
{{- define "nri-statsd.cluster" -}}
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
Returns if the template should render, it checks if the required values
insightsKey and cluster are set.
*/}}
{{- define "nri-statsd.areValuesValid" -}}
{{- $cluster := include "nri-statsd.cluster" . -}}
{{- $insightsKey := include "nri-statsd.insightsKey" . -}}
{{- and (or $insightsKey) $cluster}}
{{- end -}}
