{{/*
Expand the name of the chart.
Uses the Chart name by default if nameOverride is not set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "common.naming.name" -}}
{{- .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.naming.fullname" -}}

{{- $name := "" }}

{{- if .Values.fullnameOverride }}
    {{- $name = .Values.fullnameOverride  }}

{{- else }}
    {{- $name = (include "common.naming.name" .) }}

    {{- if contains (lower $name) (lower .Release.Name) }}
        {{- $name = $name }}
    {{- else }} 
        {{- $name = printf "%s-%s" .Release.Name $name }}
    {{- end }}

    {{- if not (hasPrefix "nri-" $name) }}
        {{- /* In case the name is not prefixed with "nri-", add it */}}
        {{- $name = printf "nri-%s" $name }}
    {{- end }}

{{- end }}

{{- $name | trunc 63 | trimSuffix "-" }}

{{- end }}



{{/*
Create chart name and version as used by the chart label.
This function should not be used for naming objects. Use "common.naming.{name,fullname}" instead.
*/}}
{{- define "common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
