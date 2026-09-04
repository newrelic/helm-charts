{{/* vim: set filetype=mustache: */}}
{{- define "postgresql-otel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql-otel.fullname" -}}
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

{{- define "postgresql-otel.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql-otel.labels" -}}
app.kubernetes.io/name: {{ include "postgresql-otel.name" . }}
helm.sh/chart: {{ include "postgresql-otel.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "postgresql-otel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgresql-otel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "postgresql-otel.validate.postgresql" -}}
{{- if not .Values.postgresql.server -}}
{{- fail "postgresql.server is required" -}}
{{- end -}}
{{- if not (or .Values.postgresql.existingSecret (and .Values.postgresql.username .Values.postgresql.password)) -}}
{{- fail "You must set postgresql.existingSecret, or both postgresql.username and postgresql.password" -}}
{{- end -}}
{{- if not .Values.postgresql.databases -}}
{{- fail "postgresql.databases must be a non-empty list -- PostgreSQL has no monitor-all-databases mode, so at least one database name is required" -}}
{{- end -}}
{{- end -}}

{{- define "postgresql-otel.credentials.secretName" -}}
{{- .Values.postgresql.existingSecret | default (printf "%s-postgresql" (include "postgresql-otel.fullname" .)) -}}
{{- end -}}

{{- define "postgresql-otel.validate.topology" -}}
{{- if not (has .Values.postgresql.topology (list "self-hosted" "rds")) -}}
{{- fail "postgresql.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- end -}}

{{/*
The otlp (gRPC) exporter takes a bare host:port target and rejects a full URL --
the exact opposite of mssql-otel's otlphttp exporter, which requires a scheme.
Catch a copy-pasted scheme'd endpoint at render time rather than at runtime.
*/}}
{{- define "postgresql-otel.validate.otlpEndpoint" -}}
{{- if not .Values.otlpEndpoint -}}
{{- fail "otlpEndpoint is required" -}}
{{- end -}}
{{- if or (hasPrefix "http://" .Values.otlpEndpoint) (hasPrefix "https://" .Values.otlpEndpoint) -}}
{{- fail (printf "otlpEndpoint must be a bare host:port with no scheme -- the otlp (gRPC) exporter rejects a URL, unlike mssql-otel's otlphttp. Got: %q. New Relic's US OTLP/gRPC endpoint is otlp.nr-data.net:4317" .Values.otlpEndpoint) -}}
{{- end -}}
{{- end -}}

{{- define "postgresql-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not .Values.setupJob.postgresAdmin.existingSecret -}}
{{- fail "setupJob.postgresAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- if not (and .Values.setupJob.image.repository .Values.setupJob.image.tag) -}}
{{- fail "setupJob.image.repository and setupJob.image.tag are required when setupJob.enabled is true -- this chart ships no default psql-client image, see README" -}}
{{- end -}}
{{- end -}}
{{- end -}}
