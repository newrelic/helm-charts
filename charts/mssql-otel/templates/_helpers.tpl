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

{{/*
This chart's exporter is named `otlp` to match New Relic's doc example
verbatim, but that doc example pairs `otlp:` (the real OTel Collector gRPC
exporter type) with an HTTP-style endpoint (port 4318, no scheme) -- a
combination confirmed live to fail at runtime with "unsupported protocol
scheme" when a scheme is present, and otherwise mismatched with what a
genuine gRPC otlp exporter expects (bare host:port, conventionally port
4317, like oracle-otel's). This chart still requires a full scheme'd URL
here (kept from when the exporter was named `otlphttp`, which genuinely
needed one) -- this is a deliberate doc-fidelity choice, not a fix, and
telemetry export in this configuration is unconfirmed/likely broken. See README.md.
*/}}
{{- define "mssql-otel.validate.otlpEndpoint" -}}
{{- if not (or (hasPrefix "http://" .Values.otlpEndpoint) (hasPrefix "https://" .Values.otlpEndpoint)) -}}
{{- fail (printf "otlpEndpoint must include a scheme (http:// or https://). Got: %q. New Relic's US OTLP/HTTP endpoint is https://otlp.nr-data.net:4318" .Values.otlpEndpoint) -}}
{{- end -}}
{{- end -}}

{{- define "mssql-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not .Values.setupJob.sqlAdmin.existingSecret -}}
{{- fail "setupJob.sqlAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mssql-otel.multi.envVarSuffix" -}}
{{- regexReplaceAll "[^A-Za-z0-9]" (upper .) "_" -}}
{{- end -}}

{{/*
Validates .Values.mssqlMulti when mssqlMulti.enabled is true: topology, non-empty databases list, each entry's
required fields (name/server/existingSecret, plus sqlAdmin.existingSecret when setupJob.enabled), unique names,
unique env-var suffixes, and no accidental mixing with the single-instance mssql.server.
*/}}
{{- define "mssql-otel.validate.mssqlMulti" -}}
{{- if not (has .Values.mssqlMulti.topology (list "self-hosted" "rds")) -}}
{{- fail "mssqlMulti.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- if not .Values.mssqlMulti.databases -}}
{{- fail "mssqlMulti.databases must contain at least one entry when mssqlMulti.enabled is true" -}}
{{- end -}}
{{- if .Values.mssql.server -}}
{{- fail "mssqlMulti.enabled and mssql.server are mutually exclusive -- use one mode or the other in a single release" -}}
{{- end -}}
{{- $seenNames := dict -}}
{{- $seenSuffixes := dict -}}
{{- range $i, $db := .Values.mssqlMulti.databases -}}
{{- if not $db.name -}}
{{- fail (printf "mssqlMulti.databases[%d].name is required" $i) -}}
{{- end -}}
{{- if not $db.server -}}
{{- fail (printf "mssqlMulti.databases[%d].server is required" $i) -}}
{{- end -}}
{{- if not $db.existingSecret -}}
{{- fail (printf "mssqlMulti.databases[%d].existingSecret is required" $i) -}}
{{- end -}}
{{- if $.Values.setupJob.enabled -}}
{{- $admin := $db.sqlAdmin | default dict -}}
{{- if not $admin.existingSecret -}}
{{- fail (printf "mssqlMulti.databases[%d].sqlAdmin.existingSecret is required when setupJob.enabled is true" $i) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $seenNames $db.name -}}
{{- fail (printf "mssqlMulti.databases[%d].name %q duplicates an earlier entry's name" $i $db.name) -}}
{{- end -}}
{{- $seenNames = set $seenNames $db.name true -}}
{{- $suffix := include "mssql-otel.multi.envVarSuffix" $db.name -}}
{{- if hasKey $seenSuffixes $suffix -}}
{{- fail (printf "mssqlMulti.databases[%d].name %q collides with another entry's name after env-var sanitization (%q) -- choose more distinct names" $i $db.name $suffix) -}}
{{- end -}}
{{- $seenSuffixes = set $seenSuffixes $suffix true -}}
{{- end -}}
{{- end -}}

{{/*
Fixed scrape-behavior defaults for every mssqlMulti entry -- same values as the single-instance mssql: block's
own defaults, but not user-configurable in multi-instance mode (matches oracle-otel/mysql-otel/postgresql-otel's
pattern of hardcoded shared defaults rather than per-field values.yaml knobs). additionalReceiverConfig remains
the one escape hatch for overriding any of this.
*/}}
{{- define "mssql-otel.multi.receiverDefaults" -}}
collection_interval: 15s
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

{{/*
Renders one receiver's field block in the same order as the single-instance configmap.yaml: collection_interval/
username/password/server/port, metrics, events, top_query_collection, collect_full_query_text,
allowed_comment_keys, query_sample_collection, falling back to alphabetical order for any other field. Deliberately
uses the same unquoted toYaml rendering as the single-instance chart for scalar fields (including username/
password/server) rather than forcing `| quote`, to match this chart's own existing style exactly. Caller emits
the `      <receiverKey>:` line itself and invokes this with `{{- include ... }}` immediately after it.

Args (single dict): .receiver -- the merged receiver config dict.
*/}}
{{- define "mssql-otel.renderReceiver" -}}
{{- $receiver := .receiver -}}
{{- $orderedKeys := list "collection_interval" "username" "password" "server" "port" "metrics" "events" "top_query_collection" "collect_full_query_text" "allowed_comment_keys" "query_sample_collection" -}}
{{- $metricsOrder := list "sqlserver.database.count" "sqlserver.database.io" "sqlserver.database.latency" "sqlserver.database.operations" "sqlserver.database.tempdb.space" "sqlserver.database.tempdb.version_store.size" "sqlserver.deadlock.rate" "sqlserver.os.wait.duration" "sqlserver.processes.blocked" "sqlserver.memory.grants.pending.count" "sqlserver.database.file.size" "sqlserver.memory.area" -}}
{{- $topQueryOrder := list "lookback_time" "max_query_sample_count" "top_query_count" "collection_interval" -}}
{{- $emitted := list -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{- if eq $key "metrics" }}
        metrics:
{{- $mval := index $receiver $key }}
{{- $memitted := list }}
{{- range $mkey := $metricsOrder }}
{{- if hasKey $mval $mkey }}
{{ toYaml (dict $mkey (index $mval $mkey)) | indent 10 }}
{{- $memitted = append $memitted $mkey }}
{{- end }}
{{- end }}
{{- range $mkey := (keys $mval | sortAlpha) }}
{{- if not (has $mkey $memitted) }}
{{ toYaml (dict $mkey (index $mval $mkey)) | indent 10 }}
{{- end }}
{{- end }}
{{- else if eq $key "top_query_collection" }}
        top_query_collection:
{{- $tval := index $receiver $key }}
{{- $temitted := list }}
{{- range $tkey := $topQueryOrder }}
{{- if hasKey $tval $tkey }}
{{ toYaml (dict $tkey (index $tval $tkey)) | indent 10 }}
{{- $temitted = append $temitted $tkey }}
{{- end }}
{{- end }}
{{- range $tkey := (keys $tval | sortAlpha) }}
{{- if not (has $tkey $temitted) }}
{{ toYaml (dict $tkey (index $tval $tkey)) | indent 10 }}
{{- end }}
{{- end }}
{{- else if eq $key "allowed_comment_keys" }}
        allowed_comment_keys:
{{- range $item := (index $receiver $key) }}
          - {{ $item }}
{{- end }}
{{- else }}
{{ toYaml (dict $key (index $receiver $key)) | indent 8 }}
{{- end }}
{{- $emitted = append $emitted $key }}
{{- end }}
{{- end }}
{{- range $key := (keys $receiver | sortAlpha) }}
{{- if not (has $key $emitted) }}
{{ toYaml (dict $key (index $receiver $key)) | indent 8 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders just the fields that vary between multi-instance database entries when 2+ entries share one receiver's
scrape-behavior block via a `<<: *nrsqlserver-common` merge key (see configmap-multi.yaml): username/password/
server/port. Deliberately does not touch collection_interval/metrics/events/top_query_collection/
collect_full_query_text/allowed_comment_keys/query_sample_collection, since those are inherited via the merge key
rather than repeated per entry. Same unquoted toYaml rendering as renderReceiver, for consistency.

Args (single dict): .receiver -- the entry's override-only dict (username/password/server/port)
*/}}
{{- define "mssql-otel.renderReceiverOverride" -}}
{{- $receiver := .receiver -}}
{{- $orderedKeys := list "username" "password" "server" "port" -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{ toYaml (dict $key (index $receiver $key)) | indent 8 }}
{{- end }}
{{- end }}
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
