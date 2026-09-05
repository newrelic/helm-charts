{{/* vim: set filetype=mustache: */}}
{{- define "mysql-otel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mysql-otel.fullname" -}}
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

{{- define "mysql-otel.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mysql-otel.labels" -}}
app.kubernetes.io/name: {{ include "mysql-otel.name" . }}
helm.sh/chart: {{ include "mysql-otel.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "mysql-otel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql-otel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "mysql-otel.validate.mysql" -}}
{{- if not .Values.mysql.server -}}
{{- fail "mysql.server is required" -}}
{{- end -}}
{{- if not (or .Values.mysql.existingSecret (and .Values.mysql.username .Values.mysql.password)) -}}
{{- fail "You must set mysql.existingSecret, or both mysql.username and mysql.password" -}}
{{- end -}}
{{- end -}}

{{- define "mysql-otel.credentials.secretName" -}}
{{- .Values.mysql.existingSecret | default (printf "%s-mysql" (include "mysql-otel.fullname" .)) -}}
{{- end -}}

{{- define "mysql-otel.validate.topology" -}}
{{- if not (has .Values.mysql.topology (list "self-hosted" "rds")) -}}
{{- fail "mysql.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- end -}}

{{- define "mysql-otel.validate.otlpEndpoint" -}}
{{- if not .Values.otlpEndpoint -}}
{{- fail "otlpEndpoint is required" -}}
{{- end -}}
{{- if or (hasPrefix "http://" .Values.otlpEndpoint) (hasPrefix "https://" .Values.otlpEndpoint) -}}
{{- fail (printf "otlpEndpoint must be a bare host:port with no scheme -- the otlp (gRPC) exporter rejects a URL, unlike mssql-otel's otlphttp. Got: %q. New Relic's US OTLP/gRPC endpoint is otlp.nr-data.net:4317" .Values.otlpEndpoint) -}}
{{- end -}}
{{- end -}}

{{- define "mysql-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not .Values.setupJob.mysqlAdmin.existingSecret -}}
{{- fail "setupJob.mysqlAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}
