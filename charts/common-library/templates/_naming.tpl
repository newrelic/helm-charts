{{/*
Allow the chart using this library to override naming function
*/}}
{{- define "common.naming.chartnameOverride" -}}
{{- .Chart.Name }}
{{- end }}



{{/*
Expand the name of the chart.
*/}}
{{- define "common.naming.name" -}}
{{- (include "common.naming.chartnameOverride" .) | default .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.naming.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}

{{- $name := default .Chart.Name .Values.nameOverride }}

{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name = printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- if not (hasPrefix "nri-" $name) }}
{{- /* In case the name is not prefixed with "nri-", add it */}}
{{- printf "%s-%s" "nri" $name }}
{{- end }}

{{- end }}
{{- end }}



{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}



{{/*
Create the name of the service account to use
*/}}
{{- define "common.naming.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.naming.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
