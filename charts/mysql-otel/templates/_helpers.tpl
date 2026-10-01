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

{{/*
The otlp (gRPC) exporter takes a bare host:port target (conventionally port
4317). A scheme'd URL is tolerated (the gRPC client strips it and uses it to
enable TLS), but the bare form is the documented/recommended one.
*/}}
{{- define "mysql-otel.validate.otlpEndpoint" -}}
{{- if not .Values.otlpEndpoint -}}
{{- fail "otlpEndpoint is required" -}}
{{- end -}}
{{- end -}}

{{- define "mysql-otel.validate.setupJob" -}}
{{- if .Values.setupJob.enabled -}}
{{- if not .Values.setupJob.mysqlAdmin.existingSecret -}}
{{- fail "setupJob.mysqlAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mysql-otel.multi.envVarSuffix" -}}
{{- regexReplaceAll "[^A-Za-z0-9]" (upper .) "_" -}}
{{- end -}}

{{/*
Validates .Values.mysqlMulti when mysqlMulti.enabled is true: topology, non-empty databases list, each entry's
required fields (name/server/existingSecret, plus mysqlAdmin.existingSecret when setupJob.enabled), unique names,
unique env-var suffixes, and no accidental mixing with the single-instance mysql.server.
*/}}
{{- define "mysql-otel.validate.mysqlMulti" -}}
{{- if not (has .Values.mysqlMulti.topology (list "self-hosted" "rds")) -}}
{{- fail "mysqlMulti.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- if not .Values.mysqlMulti.databases -}}
{{- fail "mysqlMulti.databases must contain at least one entry when mysqlMulti.enabled is true" -}}
{{- end -}}
{{- if .Values.mysql.server -}}
{{- fail "mysqlMulti.enabled and mysql.server are mutually exclusive -- use one mode or the other in a single release" -}}
{{- end -}}
{{- $seenNames := dict -}}
{{- $seenSuffixes := dict -}}
{{- range $i, $db := .Values.mysqlMulti.databases -}}
{{- if not $db.name -}}
{{- fail (printf "mysqlMulti.databases[%d].name is required" $i) -}}
{{- end -}}
{{- if not $db.server -}}
{{- fail (printf "mysqlMulti.databases[%d].server is required" $i) -}}
{{- end -}}
{{- if not $db.existingSecret -}}
{{- fail (printf "mysqlMulti.databases[%d].existingSecret is required" $i) -}}
{{- end -}}
{{- if $.Values.setupJob.enabled -}}
{{- $admin := $db.mysqlAdmin | default dict -}}
{{- if not $admin.existingSecret -}}
{{- fail (printf "mysqlMulti.databases[%d].mysqlAdmin.existingSecret is required when setupJob.enabled is true" $i) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $seenNames $db.name -}}
{{- fail (printf "mysqlMulti.databases[%d].name %q duplicates an earlier entry's name" $i $db.name) -}}
{{- end -}}
{{- $seenNames = set $seenNames $db.name true -}}
{{- $suffix := include "mysql-otel.multi.envVarSuffix" $db.name -}}
{{- if hasKey $seenSuffixes $suffix -}}
{{- fail (printf "mysqlMulti.databases[%d].name %q collides with another entry's name after env-var sanitization (%q) -- choose more distinct names" $i $db.name $suffix) -}}
{{- end -}}
{{- $seenSuffixes = set $seenSuffixes $suffix true -}}
{{- end -}}
{{- end -}}

{{/*
Renders one receiver's field block in the same order as the single-instance configmap.yaml: endpoint/transport/
username/password/database, allow_native_passwords/collection_interval/initial_delay, tls, explain_mode,
statement_events, query_sample_collection, top_query_collection, events, falling back to alphabetical order for
any other field (e.g. from additionalReceiverConfig). Caller emits the `      <receiverKey>:` line itself and
invokes this with `{{- include ... }}` immediately after it (leading `{{-` required, trims the preceding newline).

Args (single dict): .receiver -- the merged receiver config dict.
*/}}
{{- define "mysql-otel.renderReceiver" -}}
{{- $receiver := .receiver -}}
{{- $orderedKeys := list "endpoint" "transport" "username" "password" "database" "allow_native_passwords" "collection_interval" "initial_delay" "tls" "explain_mode" "statement_events" "query_sample_collection" "top_query_collection" "events" -}}
{{- $emitted := list -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{- if eq $key "tls" }}
{{- $tls := index $receiver $key }}
        tls:
          insecure: {{ index $tls "insecure" }}
          insecure_skip_verify: {{ index $tls "insecure_skip_verify" }}
          {{- if hasKey $tls "ca_file" }}
          ca_file: {{ index $tls "ca_file" | quote }}
          {{- end }}
{{- else if eq $key "statement_events" }}
{{- $stmt := index $receiver $key }}
        statement_events:
          digest_text_limit: {{ index $stmt "digest_text_limit" }}
          time_limit: {{ index $stmt "time_limit" }}
          limit: {{ index $stmt "limit" }}
{{- else if eq $key "query_sample_collection" }}
{{- $qsc := index $receiver $key }}
        query_sample_collection:
          max_rows_per_query: {{ index $qsc "max_rows_per_query" }}
          allowed_comment_keys: [{{ index $qsc "allowed_comment_keys" | join ", " }}]
{{- else if eq $key "top_query_collection" }}
{{- $tqc := index $receiver $key }}
        top_query_collection:
          lookback_time: {{ index $tqc "lookback_time" }}
          max_query_sample_count: {{ index $tqc "max_query_sample_count" }}
          top_query_count: {{ index $tqc "top_query_count" }}
          collection_interval: {{ index $tqc "collection_interval" }}
          query_plan_cache_size: {{ index $tqc "query_plan_cache_size" }}
          query_plan_cache_ttl: {{ index $tqc "query_plan_cache_ttl" }}
          allowed_comment_keys: [{{ index $tqc "allowed_comment_keys" | join ", " }}]
{{- else if eq $key "events" }}
{{- $events := index $receiver $key }}
        events:
          db.server.query_sample:
            enabled: {{ index (index $events "db.server.query_sample") "enabled" }}
          db.server.top_query:
            enabled: {{ index (index $events "db.server.top_query") "enabled" }}
{{- else if has $key (list "endpoint" "username" "password" "database") }}
        {{ $key }}: {{ (index $receiver $key) | quote }}
{{- else }}
        {{ $key }}: {{ index $receiver $key }}
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
scrape-behavior block via a `<<: *nrmysql-common` merge key (see configmap-multi.yaml): endpoint/username/
password/database. Deliberately does not touch transport/allow_native_passwords/collection_interval/initial_delay/
tls/explain_mode/statement_events/query_sample_collection/top_query_collection/events, since those are inherited
via the merge key rather than repeated per entry.

Args (single dict): .receiver -- the entry's override-only dict (endpoint/username/password/database)
*/}}
{{/*
Fixed scrape-behavior defaults shared by both single-instance (configmap.yaml) and multi-instance
(configmap-multi.yaml) rendering -- not user-configurable via values.yaml in either mode (matches
oracle-otel/mssql-otel's pattern of hardcoded shared defaults rather than per-field values.yaml knobs).
additionalReceiverConfig remains the one escape hatch for overriding any of this.
*/}}
{{- define "mysql-otel.multi.receiverDefaults" -}}
transport: tcp
allow_native_passwords: true
collection_interval: 10s
initial_delay: 1s
explain_mode: inline
tls:
  insecure: false
  insecure_skip_verify: false
statement_events:
  digest_text_limit: 4096
  time_limit: 24h
  limit: 500
query_sample_collection:
  max_rows_per_query: 100
  allowed_comment_keys:
    - nr_service_guid
top_query_collection:
  lookback_time: 120
  max_query_sample_count: 5000
  top_query_count: 200
  collection_interval: 60s
  query_plan_cache_size: 1000
  query_plan_cache_ttl: 1h
  allowed_comment_keys:
    - nr_service_guid
events:
  db.server.query_sample:
    enabled: true
  db.server.top_query:
    enabled: true
{{- end -}}

{{- define "mysql-otel.renderReceiverOverride" -}}
{{- $receiver := .receiver -}}
{{- $orderedKeys := list "endpoint" "username" "password" "database" -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
        {{ $key }}: {{ (index $receiver $key) | quote }}
{{- end }}
{{- end }}
{{- end -}}
