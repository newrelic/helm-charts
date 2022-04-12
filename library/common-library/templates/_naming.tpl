{{/*
Expand the name of the chart.
Uses the Chart name by default if nameOverride is not set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.name" -}}
{{- .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Create a default fully qualified app name.
By default the full name will be "<release_name>-<chart_chart>". This could change if fullnameOverride or
nameOverride are set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.fullname" -}}
{{- $name := "" }}

{{- if .Values.fullnameOverride }}
    {{- $name = .Values.fullnameOverride  }}
{{- else }}
    {{- $name = printf "%s-%s" .Release.Name (include "common.naming.name" .)}}
{{- end }}

{{- $name | trunc 63 | trimSuffix "-" }}

{{- end }}



{{/*
Create chart name and version as used by the chart label.
This function should not be used for naming objects. Use "common.naming.{name,fullname}" instead.
*/}}
{{- define "newrelic.common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
