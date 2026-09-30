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

{{- define "postgresql-otel.multi.envVarSuffix" -}}
{{- regexReplaceAll "[^A-Za-z0-9]" (upper .) "_" -}}
{{- end -}}

{{/*
Validates .Values.postgresqlMulti when postgresqlMulti.enabled is true: topology, non-empty instances list, each
entry's required fields (name/server/existingSecret/databases, plus postgresAdmin.existingSecret when
setupJob.enabled), setupJob image when setupJob.enabled, unique names, unique env-var suffixes, and no accidental
mixing with the single-instance postgresql.server.
*/}}
{{- define "postgresql-otel.validate.postgresqlMulti" -}}
{{- if not (has .Values.postgresqlMulti.topology (list "self-hosted" "rds")) -}}
{{- fail "postgresqlMulti.topology must be one of: self-hosted, rds" -}}
{{- end -}}
{{- if not .Values.postgresqlMulti.instances -}}
{{- fail "postgresqlMulti.instances must contain at least one entry when postgresqlMulti.enabled is true" -}}
{{- end -}}
{{- if .Values.postgresql.server -}}
{{- fail "postgresqlMulti.enabled and postgresql.server are mutually exclusive -- use one mode or the other in a single release" -}}
{{- end -}}
{{- if .Values.setupJob.enabled -}}
{{- if not (and .Values.setupJob.image.repository .Values.setupJob.image.tag) -}}
{{- fail "setupJob.image.repository and setupJob.image.tag are required when setupJob.enabled is true -- this chart ships no default psql-client image, see README" -}}
{{- end -}}
{{- end -}}
{{- $seenNames := dict -}}
{{- $seenSuffixes := dict -}}
{{- range $i, $inst := .Values.postgresqlMulti.instances -}}
{{- if not $inst.name -}}
{{- fail (printf "postgresqlMulti.instances[%d].name is required" $i) -}}
{{- end -}}
{{- if not $inst.server -}}
{{- fail (printf "postgresqlMulti.instances[%d].server is required" $i) -}}
{{- end -}}
{{- if not $inst.existingSecret -}}
{{- fail (printf "postgresqlMulti.instances[%d].existingSecret is required" $i) -}}
{{- end -}}
{{- if not $inst.databases -}}
{{- fail (printf "postgresqlMulti.instances[%d].databases must be a non-empty list -- PostgreSQL has no monitor-all-databases mode" $i) -}}
{{- end -}}
{{- if $.Values.setupJob.enabled -}}
{{- $admin := $inst.postgresAdmin | default dict -}}
{{- if not $admin.existingSecret -}}
{{- fail (printf "postgresqlMulti.instances[%d].postgresAdmin.existingSecret is required when setupJob.enabled is true" $i) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $seenNames $inst.name -}}
{{- fail (printf "postgresqlMulti.instances[%d].name %q duplicates an earlier entry's name" $i $inst.name) -}}
{{- end -}}
{{- $seenNames = set $seenNames $inst.name true -}}
{{- $suffix := include "postgresql-otel.multi.envVarSuffix" $inst.name -}}
{{- if hasKey $seenSuffixes $suffix -}}
{{- fail (printf "postgresqlMulti.instances[%d].name %q collides with another entry's name after env-var sanitization (%q) -- choose more distinct names" $i $inst.name $suffix) -}}
{{- end -}}
{{- $seenSuffixes = set $seenSuffixes $suffix true -}}
{{- end -}}
{{- end -}}

{{/*
Fixed scrape-behavior defaults shared by both single-instance (configmap.yaml) and multi-instance
(configmap-multi.yaml) rendering -- not user-configurable via values.yaml in either mode (matches
oracle-otel/mssql-otel's pattern of hardcoded shared defaults rather than per-field values.yaml knobs).
additionalReceiverConfig remains the one escape hatch for overriding any of this. exclude_databases (RDS-only)
is layered on separately by each caller, since it depends on topology.
*/}}
{{- define "postgresql-otel.multi.receiverDefaults" -}}
transport: tcp
collection_interval: 15s
events:
  db.server.top_query:
    enabled: true
  db.server.query_sample:
    enabled: true
top_query_collection:
  max_rows_per_query: 1000
  top_n_query: 200
  collection_interval: 60s
  allowed_comment_keys:
    - nr_service_guid
query_sample_collection:
  max_rows_per_query: 1000
  allowed_comment_keys:
    - nr_service_guid
metrics:
  postgresql.database.locks:
    enabled: true
  postgresql.deadlocks:
    enabled: true
  postgresql.function.calls:
    enabled: true
  postgresql.query.conflicts:
    enabled: true
  postgresql.sequential_scans:
    enabled: true
  postgresql.temp.io:
    enabled: true
  postgresql.temp_files:
    enabled: true
{{- end -}}

{{/*
Renders one receiver's field block in the same order as the single-instance configmap.yaml: endpoint/transport/
username/password/databases/exclude_databases, collection_interval, events, top_query_collection,
query_sample_collection, metrics, falling back to alphabetical order for any other field (e.g. from
additionalReceiverConfig). Caller emits the `      <receiverKey>:` line itself and invokes this with
`{{- include ... }}` immediately after it (leading `{{-` required, trims the preceding newline).

Args (single dict): .receiver -- the merged receiver config dict.
*/}}
{{- define "postgresql-otel.renderReceiver" -}}
{{- $receiver := .receiver -}}
{{- $metricsOrder := list "postgresql.database.locks" "postgresql.deadlocks" "postgresql.function.calls" "postgresql.query.conflicts" "postgresql.sequential_scans" "postgresql.temp.io" "postgresql.temp_files" -}}
{{- $orderedKeys := list "endpoint" "transport" "username" "password" "databases" "exclude_databases" "collection_interval" "events" "top_query_collection" "query_sample_collection" "metrics" -}}
{{- $emitted := list -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{- if has $key (list "databases" "exclude_databases") }}
        {{ $key }}:
        {{- range (index $receiver $key) }}
          - {{ . }}
        {{- end }}
{{- else if eq $key "events" }}
{{- $events := index $receiver $key }}
        events:
          db.server.top_query:
            enabled: {{ index (index $events "db.server.top_query") "enabled" }}
          db.server.query_sample:
            enabled: {{ index (index $events "db.server.query_sample") "enabled" }}
{{- else if eq $key "top_query_collection" }}
{{- $tqc := index $receiver $key -}}
{{- $tqcOrder := list "max_rows_per_query" "top_n_query" "collection_interval" "allowed_comment_keys" -}}
{{- $tqcEmitted := list }}
        top_query_collection:
{{- range $tk := $tqcOrder }}
{{- if hasKey $tqc $tk }}
{{- if eq $tk "allowed_comment_keys" }}
          allowed_comment_keys: [{{ index $tqc $tk | join ", " }}]
{{- else }}
          {{ $tk }}: {{ index $tqc $tk }}
{{- end }}
{{- $tqcEmitted = append $tqcEmitted $tk -}}
{{- end }}
{{- end }}
{{- range $tk := (keys $tqc | sortAlpha) }}
{{- if not (has $tk $tqcEmitted) }}
          {{ $tk }}: {{ index $tqc $tk }}
{{- end }}
{{- end }}
{{- else if eq $key "query_sample_collection" }}
{{- $qsc := index $receiver $key }}
        query_sample_collection:
          max_rows_per_query: {{ index $qsc "max_rows_per_query" }}
          allowed_comment_keys: [{{ index $qsc "allowed_comment_keys" | join ", " }}]
{{- else if eq $key "metrics" }}
{{- $metrics := index $receiver $key }}
        metrics:
          {{- range $mk := $metricsOrder }}
          {{ $mk }}:
            enabled: {{ index (index $metrics $mk) "enabled" }}
          {{- end }}
{{- else if has $key (list "endpoint" "username" "password") }}
        {{ $key }}: {{ (index $receiver $key) | quote }}
{{- else }}
        {{ $key }}: {{ index $receiver $key }}
{{- end }}
{{- $emitted = append $emitted $key }}
{{- end }}
{{- end }}
{{- range $key := (keys $receiver | sortAlpha) }}
{{- if not (has $key $emitted) }}
{{- $v := index $receiver $key }}
{{- if kindIs "map" $v }}
        {{ $key }}:
{{ toYaml $v | indent 10 }}
{{- else }}
        {{ $key }}: {{ toYaml $v }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders just the fields that vary between multi-instance database entries when 2+ entries share one receiver's
scrape-behavior block via a `<<: *nrpostgresql-common` merge key (see configmap-multi.yaml): endpoint/username/
password/databases. Deliberately does not touch transport/exclude_databases/collection_interval/events/
top_query_collection/query_sample_collection/metrics, since those are inherited via the merge key rather than
repeated per entry.

Args (single dict): .receiver -- the entry's override-only dict (endpoint/username/password/databases)
*/}}
{{- define "postgresql-otel.renderReceiverOverride" -}}
{{- $receiver := .receiver -}}
{{- if hasKey $receiver "endpoint" }}
        endpoint: {{ index $receiver "endpoint" | quote }}
{{- end }}
{{- if hasKey $receiver "username" }}
        username: {{ index $receiver "username" | quote }}
{{- end }}
{{- if hasKey $receiver "password" }}
        password: {{ index $receiver "password" | quote }}
{{- end }}
{{- if hasKey $receiver "databases" }}
        databases:
        {{- range (index $receiver "databases") }}
          - {{ . }}
        {{- end }}
{{- end }}
{{- end -}}
