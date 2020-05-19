{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "newrelic-logging.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic-logging.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if ne $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/* Generate basic labels */}}
{{- define "newrelic-logging.labels" }}
app: {{ template "newrelic-logging.name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{.Release.Service }}
release: {{.Release.Name }}
app.kubernetes.io/name: {{ template "newrelic-logging.name" . }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "newrelic-logging.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "newrelic-logging.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "newrelic-logging.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/*
Create the name of the fluent bit config
*/}}
{{- define "newrelic-logging.fluentBitConfig" -}}
{{ template "newrelic-logging.fullname" . }}-fluent-bit-config
{{- end -}}

{{/*
Return the licenseKey
*/}}
{{- define "newrelic-logging.licenseKey" -}}
{{- if .Values.global}}
  {{- if .Values.global.licenseKey }}
      {{- .Values.global.licenseKey -}}
  {{- else -}}
      {{- .Values.licenseKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.licenseKey | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the clusterName
*/}}
{{- define "newrelic-logging.clusterName" -}}
{{- if .Values.global}}
  {{- if .Values.global.clusterName }}
      {{- .Values.global.clusterName -}}
  {{- else -}}
      {{- .Values.clusterName | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.clusterName | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretName
*/}}
{{- define "newrelic-logging.customSecretName" -}}
{{- if .Values.global }}
  {{- if .Values.global.customSecretName }}
      {{- .Values.global.customSecretName -}}
  {{- else -}}
      {{- .Values.customSecretName | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.customSecretName | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretKey
*/}}
{{- define "newrelic-logging.customSecretKey" -}}
{{- if .Values.global }}
  {{- if .Values.global.customSecretKey }}
      {{- .Values.global.customSecretKey -}}
  {{- else -}}
      {{- .Values.customSecretKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.customSecretKey | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Returns if the template should render, it checks if the required values are set.
*/}}
{{- define "newrelic-logging.areValuesValid" -}}
{{- $licenseKey := include "newrelic-logging.licenseKey" . -}}
{{- $customSecretName := include "newrelic-logging.customSecretName" . -}}
{{- $customSecretKey := include "newrelic-logging.customSecretKey" . -}}
{{- and (or $licenseKey (and $customSecretName $customSecretKey))}}
{{- end -}}
