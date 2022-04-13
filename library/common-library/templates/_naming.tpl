{{/*
This is an function to be called directly with a string just to truncate strings to
63 chars because some Kubernetes name fields are limited to that.
*/}}
{{- define "newrelic.common.naming.trucateToDNS" -}}
{{- . | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Expand the name of the chart.
Uses the Chart name by default if nameOverride is not set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.name" -}}
{{- $name := .Values.nameOverride | default .Chart.Name -}}
{{- include "newrelic.common.naming.trucateToDNS" $name -}}
{{- end }}



{{/*
Create a default fully qualified app name.
By default the full name will be "<release_name>-<chart_chart>". This could change if fullnameOverride or
nameOverride are set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.fullname" -}}
{{- $name := include "newrelic.common.naming.name" . -}}

{{- if .Values.fullnameOverride -}}
    {{- $name = .Values.fullnameOverride  -}}
{{- else if not (contains $name .Release.Name) -}}
    {{- $name = printf "%s-%s" .Release.Name $name -}}
{{- end -}}

{{- include "newrelic.common.naming.trucateToDNS" $name -}}

{{- end -}}



{{/*
Create chart name and version as used by the chart label.
This function should not be used for naming objects. Use "common.naming.{name,fullname}" instead.
*/}}
{{- define "newrelic.common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}
