{{/* vim: set filetype=mustache: */}}
{{- define "oracle-otel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "oracle-otel.fullname" -}}
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

{{- define "oracle-otel.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "oracle-otel.labels" -}}
app.kubernetes.io/name: {{ include "oracle-otel.name" . }}
helm.sh/chart: {{ include "oracle-otel.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "oracle-otel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oracle-otel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "oracle-otel.validate.oracle" -}}
{{- if or (not .Values.oracle.endpoint) (not .Values.oracle.service) -}}
{{- fail "oracle.endpoint and oracle.service are required" -}}
{{- end -}}
{{- if not (or .Values.oracle.existingSecret (and .Values.oracle.username .Values.oracle.password)) -}}
{{- fail "You must set oracle.existingSecret, or both oracle.username and oracle.password" -}}
{{- end -}}
{{- end -}}

{{- define "oracle-otel.credentials.secretName" -}}
{{- .Values.oracle.existingSecret | default (printf "%s-oracle" (include "oracle-otel.fullname" .)) -}}
{{- end -}}

{{- define "oracle-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not (has .Values.oracle.topology (list "cdb" "pdb" "rds")) -}}
{{- fail "oracle.topology must be one of: cdb, pdb, rds when setupJob.enabled is true" -}}
{{- end -}}
{{- if not .Values.setupJob.oracleAdmin.existingSecret -}}
{{- fail "setupJob.oracleAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}
