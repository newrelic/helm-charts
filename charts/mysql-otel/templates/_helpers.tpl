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

{{- define "mysql-otel.validate.configProfile" -}}
{{- if not (has .value (list "basic" "advanced")) -}}
{{- fail (printf "%s must be one of: basic, advanced" .key) -}}
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

{{- define "mysql-otel.multi.envVarSuffix" -}}
{{- regexReplaceAll "[^A-Za-z0-9]" (upper .) "_" -}}
{{- end -}}

{{/*
Validates .Values.mysqlMulti when mysqlMulti.enabled is true: topology, non-empty databases list, each entry's
required fields (name/server/existingSecret, plus mysqlAdmin.existingSecret when setupJob.enabled), unique names,
unique env-var suffixes, and no accidental mixing with the single-instance mysql.server.
*/}}
{{- define "mysql-otel.validate.mysqlMulti" -}}
{{- include "mysql-otel.validate.configProfile" (dict "key" "mysqlMulti.configProfile" "value" .Values.mysqlMulti.configProfile) -}}
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
username/password/database, allow_native_passwords/collection_interval/initial_delay, explain_mode,
statement_events, query_sample_collection, top_query_collection, events, resource_attributes, metrics, falling back to alphabetical
order for any other field (e.g. from additionalReceiverConfig). Caller emits the `      <receiverKey>:` line
itself and invokes this with `{{- include ... }}` immediately after it (leading `{{-` required, trims the
preceding newline).

Args (single dict): .receiver -- the merged receiver config dict.
*/}}
{{- define "mysql-otel.renderReceiver" -}}
{{- $receiver := .receiver -}}
{{- $orderedKeys := list "endpoint" "transport" "username" "password" "database" "allow_native_passwords" "collection_interval" "initial_delay" "explain_mode" "statement_events" "query_sample_collection" "top_query_collection" "events" "resource_attributes" "metrics" -}}
{{- $emitted := list -}}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{- if eq $key "statement_events" }}
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
          db.server.query_plan:
            enabled: {{ index (index $events "db.server.query_plan") "enabled" }}
{{- else if eq $key "resource_attributes" }}
{{- $ra := index $receiver $key }}
        resource_attributes:
          db.system.version:
            enabled: {{ index (index $ra "db.system.version") "enabled" }}
{{- else if eq $key "metrics" }}
{{- $metrics := index $receiver $key }}
{{- $metricsOrder := list "mysql.query.count" "mysql.query.slow.count" "mysql.commands" "mysql.innodb.data_file.io" }}
        metrics:
{{- range $mk := $metricsOrder }}
          {{ $mk }}:
            enabled: {{ index (index $metrics $mk) "enabled" }}
{{- end }}
{{- range $mk := (keys $metrics | sortAlpha) }}
{{- if not (has $mk $metricsOrder) }}
          {{ $mk }}:
            enabled: {{ index (index $metrics $mk) "enabled" }}
{{- end }}
{{- end }}
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
explain_mode/statement_events/query_sample_collection/top_query_collection/events/metrics, since those are
inherited via the merge key rather than repeated per entry.

Args (single dict): .receiver -- the entry's override-only dict (endpoint/username/password/database)
*/}}
{{/*
Advanced profile metrics: New Relic's full MySQL metric catalog (71 metrics), from
https://docs.newrelic.com/docs/opentelemetry/db360/mysql/config-reference/ -- keep in sync with it.
Identical for self-hosted and rds. Merged over multi.receiverDefaults, so it replaces (never removes)
the basic metrics.
*/}}
{{- define "mysql-otel.receiver.advancedMetrics" -}}
metrics:
  # ---- Default-enabled metrics (kept explicit for visibility) ----
  mysql.buffer_pool.data_pages:
    enabled: true
  mysql.buffer_pool.limit:
    enabled: true
  mysql.buffer_pool.operations:
    enabled: true
  mysql.buffer_pool.page_flushes:
    enabled: true
  mysql.buffer_pool.pages:
    enabled: true
  mysql.buffer_pool.usage:
    enabled: true
  mysql.double_writes:
    enabled: true
  mysql.handlers:
    enabled: true
  mysql.index.io.wait.count:
    enabled: true
  mysql.index.io.wait.time:
    enabled: true
  mysql.locks:
    enabled: true
  mysql.log_operations:
    enabled: true
  mysql.mysqlx_connections:
    enabled: true
  mysql.opened_resources:
    enabled: true
  mysql.operations:
    enabled: true
  mysql.page_operations:
    enabled: true
  mysql.prepared_statements:
    enabled: true
  mysql.row_locks:
    enabled: true
  mysql.row_operations:
    enabled: true
  mysql.sorts:
    enabled: true
  mysql.table.io.wait.count:
    enabled: true
  mysql.table.io.wait.time:
    enabled: true
  mysql.threads:
    enabled: true
  mysql.tmp_resources:
    enabled: true
  mysql.uptime:
    enabled: true
  # ---- Disabled-by-default metrics (explicitly turned on for full-feature) ----
  mysql.client.network.io:
    enabled: true
  mysql.commands:
    enabled: true
  mysql.connection.count:
    enabled: true
  mysql.connection.errors:
    enabled: true
  mysql.file.open:
    enabled: true
  mysql.innodb.data_file.io:
    enabled: true
  mysql.innodb.history_list.length:
    enabled: true
  mysql.innodb.operation.pending:
    enabled: true
  mysql.innodb.redo_log.checkpoint.age:
    enabled: true
  mysql.innodb.redo_log.lsn.checkpoint:
    enabled: true
  mysql.innodb.redo_log.lsn.current:
    enabled: true
  mysql.innodb.row_lock.wait.count:
    enabled: true
  mysql.innodb.row_lock.wait.duration.avg:
    enabled: true
  mysql.innodb.row_lock.wait.duration.max:
    enabled: true
  mysql.innodb.transaction.active.count:
    enabled: true
  mysql.innodb.transaction.active.duration.max:
    enabled: true
  mysql.joins:
    enabled: true
  mysql.max_used_connections:
    enabled: true
  mysql.myisam.key_cache.block.unused:
    enabled: true
  mysql.myisam.key_cache.block.used.max:
    enabled: true
  mysql.myisam.key_cache.disk.operation:
    enabled: true
  mysql.myisam.key_cache.request:
    enabled: true
  mysql.mysqlx_worker_threads:
    enabled: true
  mysql.page_size:
    enabled: true
  mysql.query.client.count:
    enabled: true
  mysql.query.count:
    enabled: true
  mysql.query.execution.time:
    enabled: true
  mysql.query.slow.count:
    enabled: true
  mysql.replica.sql_delay:
    enabled: true
  mysql.replica.temp_table.open:
    enabled: true
  mysql.replica.thread.running:
    enabled: true
  mysql.replica.time_behind_source:
    enabled: true
  mysql.server.healthy:
    enabled: true
  mysql.session.active.count:
    enabled: true
  mysql.statement_event.count:
    enabled: true
  mysql.statement_event.wait.time:
    enabled: true
  mysql.table.average_row_length:
    enabled: true
  mysql.table.lock_wait.read.count:
    enabled: true
  mysql.table.lock_wait.read.time:
    enabled: true
  mysql.table.lock_wait.write.count:
    enabled: true
  mysql.table.lock_wait.write.time:
    enabled: true
  mysql.table.open:
    enabled: true
  mysql.table.rows:
    enabled: true
  mysql.table.size:
    enabled: true
  mysql.table_open_cache:
    enabled: true
  mysql.thread.slow_launch:
    enabled: true
{{- end -}}

{{/*
Advanced profile: the app-facing OTLP receiver from the same doc. The doc's bare `grpc:`/`http:` bind to
localhost on current collectors, which is unreachable from other pods, so both endpoints are explicit
0.0.0.0 here. Rendered by the caller via `| nindent 6` under `receivers:`.
*/}}
{{- define "mysql-otel.advanced.otlpReceiver" -}}
otlp:
  protocols:
    grpc:
      endpoint: 0.0.0.0:4317
    http:
      endpoint: 0.0.0.0:4318
{{- end -}}

{{/*
Advanced profile: everything after `receivers:` in the doc's config -- the health_check extension, transform /
batch / resource_detection processors, the exporter with sending_queue, and the five pipelines (metrics/mysql
and logs/mysql for the database receivers, plus traces/metrics/logs for the OTLP receiver). The caller
renders it via `| nindent 4`.

Args (single dict): .otlpEndpoint -- the exporter endpoint; .receiverKeys -- list of nrmysql receiver keys.
*/}}
{{- define "mysql-otel.advanced.tail" -}}
extensions:
  health_check:
processors:
  transform:
    trace_statements:
      - context: span
        statements:
          - truncate_all(span.attributes, 4095)
          - truncate_all(resource.attributes, 4095)
  batch:
  resource_detection:
    detectors: ["system"]
    system:
      hostname_sources: ["os"]
      resource_attributes:
        host.id:
          enabled: true
  resource_detection/cloud:
    detectors: ["gcp", "ec2", "azure"]
    timeout: 2s
    override: true
  resource_detection/env:
    detectors: ["env"]
    timeout: 2s
    override: true
exporters:
  otlp/newrelic:
    endpoint: {{ .otlpEndpoint | quote }}
    headers:
      api-key: "${env:NEW_RELIC_LICENSE_KEY}"
    compression: gzip
    sending_queue:
      enabled: true
      sizer: bytes
      queue_size: 100_000_000
      num_consumers: 10
      batch:
        sizer: bytes
        max_size: 1_000_000
        min_size: 0
        flush_timeout: 5s
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s
service:
  telemetry:
    metrics:
      level: none
  extensions: [health_check]
  pipelines:
    metrics/mysql:
      receivers: [{{ join ", " .receiverKeys }}]
      processors:
        - resource_detection
        - resource_detection/cloud
        - resource_detection/env
        - batch
      exporters: [otlp/newrelic]
    logs/mysql:
      receivers: [{{ join ", " .receiverKeys }}]
      processors:
        - resource_detection
        - resource_detection/cloud
        - resource_detection/env
        - batch
      exporters: [otlp/newrelic]
    traces:
      receivers: [otlp]
      processors: [transform, resource_detection, resource_detection/cloud, resource_detection/env, batch]
      exporters: [otlp/newrelic]
    metrics:
      receivers: [otlp]
      processors: [resource_detection, resource_detection/cloud, resource_detection/env, batch]
      exporters: [otlp/newrelic]
    logs:
      receivers: [otlp]
      processors: [resource_detection, resource_detection/cloud, resource_detection/env, batch]
      exporters: [otlp/newrelic]
{{- end -}}

{{/*
Fixed scrape-behavior defaults shared by both single-instance (configmap.yaml) and multi-instance
(configmap-multi.yaml) rendering -- not user-configurable via values.yaml in either mode (matches
oracle-otel/mssql-otel's pattern of hardcoded shared defaults rather than per-field values.yaml knobs).
additionalReceiverConfig remains the one escape hatch for overriding any of this.
*/}}
{{- define "mysql-otel.multi.receiverDefaults" -}}
transport: tcp
allow_native_passwords: true
collection_interval: 15s
initial_delay: 1s
explain_mode: procedure
statement_events:
  digest_text_limit: 4096
  time_limit: 24h
  limit: 500
query_sample_collection:
  max_rows_per_query: 100
  allowed_comment_keys:
    - nr_service_guid
top_query_collection:
  lookback_time: 60
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
  db.server.query_plan:
    enabled: true
resource_attributes:
  db.system.version:
    enabled: true
metrics:
  mysql.query.count:
    enabled: true
  mysql.query.slow.count:
    enabled: true
  mysql.commands:
    enabled: true
  mysql.innodb.data_file.io:
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
