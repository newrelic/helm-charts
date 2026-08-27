{{/* vim: set filetype=mustache: */}}
{{- define "mssql-otel.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mssql-otel.fullname" -}}
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

{{- define "mssql-otel.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mssql-otel.labels" -}}
app.kubernetes.io/name: {{ include "mssql-otel.name" . }}
helm.sh/chart: {{ include "mssql-otel.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "mssql-otel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mssql-otel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "mssql-otel.validate.mssql" -}}
{{- if not .Values.mssql.server -}}
{{- fail "mssql.server is required" -}}
{{- end -}}
{{- if not (or .Values.mssql.existingSecret (and .Values.mssql.username .Values.mssql.password)) -}}
{{- fail "You must set mssql.existingSecret, or both mssql.username and mssql.password" -}}
{{- end -}}
{{- end -}}

{{- define "mssql-otel.credentials.secretName" -}}
{{- .Values.mssql.existingSecret | default (printf "%s-mssql" (include "mssql-otel.fullname" .)) -}}
{{- end -}}

{{- define "mssql-otel.validate.topology" -}}
{{- if not (has .Values.mssql.topology (list "self-hosted" "rds")) -}}
{{- fail "mssql.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- end -}}

{{- define "mssql-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not .Values.setupJob.sqlAdmin.existingSecret -}}
{{- fail "setupJob.sqlAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
metrics + events + collection tuning for the nrsqlserver receiver's "Standard configuration".
Verbatim from New Relic's otel-mssql docs. Needs ct install verification against the real
collector schema before this is trusted -- see the design spec's schema-drift lesson from
oracle-otel's resource_attributes/oracle.db.pdb failure.
*/}}
{{- define "mssql-otel.receiver.defaults" -}}
metrics:
  sqlserver.database.count:
    enabled: true
  sqlserver.database.io:
    enabled: true
  sqlserver.database.latency:
    enabled: true
  sqlserver.database.operations:
    enabled: true
  sqlserver.database.tempdb.space:
    enabled: true
  sqlserver.database.tempdb.version_store.size:
    enabled: true
  sqlserver.deadlock.rate:
    enabled: true
  sqlserver.os.wait.duration:
    enabled: true
  sqlserver.processes.blocked:
    enabled: true
  sqlserver.memory.grants.pending.count:
    enabled: true
  sqlserver.database.file.size:
    enabled: true
  sqlserver.memory.area:
    enabled: true
events:
  db.server.query_sample:
    enabled: true
  db.server.top_query:
    enabled: true
top_query_collection:
  lookback_time: 60s
  max_query_sample_count: 1000
  top_query_count: 250
  collection_interval: 60s
collect_full_query_text: true
allowed_comment_keys:
  - nr_service_guid
query_sample_collection:
  max_rows_per_query: 100
{{- end -}}
