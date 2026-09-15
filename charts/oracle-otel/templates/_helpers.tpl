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

{{/*
Renders one metric entry (`.key`: `.value`, where `.value` is the metric's
dict, e.g. {enabled: true, attributes: [...]}) in New Relic's doc order --
`enabled:` before `attributes:`, with the attributes list indented under
its key -- instead of toYaml's alphabetical "attributes before enabled,
dash at the same column as the key" default. Falls back to sorted order
for any other field a metric might carry (e.g. via additionalReceiverConfig).
Caller pipes the result through `indent N`.

`.value` must be a map -- an `additionalReceiverConfig.metrics.<name>`
override that replaces a metric with a scalar (e.g. `metrics: {oracledb.cpu_time: false}`
instead of `metrics: {oracledb.cpu_time: {enabled: false}}`) fails clearly here
instead of crashing inside `hasKey` with a raw Go type-mismatch error.
*/}}
{{- define "oracle-otel.renderMetric" -}}
{{- $mkey := .key -}}
{{- $mval := .value -}}
{{- if not (kindIs "map" $mval) -}}
{{- fail (printf "additionalReceiverConfig.metrics.%s must be a map, e.g. {enabled: true} -- got %#v" $mkey $mval) -}}
{{- end -}}
{{ $mkey }}:
{{- if hasKey $mval "enabled" }}
  enabled: {{ index $mval "enabled" }}
{{- end }}
{{- if hasKey $mval "attributes" }}
  attributes:
{{- range $attr := (index $mval "attributes") }}
    - {{ $attr }}
{{- end }}
{{- end }}
{{- range $k := (keys $mval | sortAlpha) }}
{{- if not (or (eq $k "enabled") (eq $k "attributes")) }}
  {{ $k }}: {{ toYaml (index $mval $k) }}
{{- end }}
{{- end }}
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
{{- if not (has .Values.oracle.topology (list "cdb" "pdb" "rds" "adb")) -}}
{{- fail "oracle.topology must be one of: cdb, pdb, rds, adb when setupJob.enabled is true" -}}
{{- end -}}
{{- if not .Values.setupJob.oracleAdmin.existingSecret -}}
{{- fail "setupJob.oracleAdmin.existingSecret is required when setupJob.enabled is true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "oracle-otel.validate.topology" -}}
{{- if not (has .Values.oracle.topology (list "cdb" "pdb" "rds" "adb")) -}}
{{- fail "oracle.topology must be one of: cdb, pdb, rds, adb -- required to select the correct nroracledb metrics/events defaults" -}}
{{- end -}}
{{- end -}}

{{/*
Fields shared by every topology: events, top_query_collection, query_sample_collection,
session_wait_event_collection. Verbatim from New Relic's otel-oracledb docs -- identical
across cdb/pdb/rds/adb.
*/}}
{{- define "oracle-otel.receiver.collectionDefaults" -}}
events:
  db.server.query_sample:
    enabled: true
  db.server.top_query:
    enabled: true
  db.server.session.wait_sample:
    enabled: true
top_query_collection:
  max_query_sample_count: 1000
  top_query_count: 200
  collection_interval: 60s
  allowed_comment_keys:
    - nr_service_guid
query_sample_collection:
  max_rows_per_query: 100
  allowed_comment_keys:
    - nr_service_guid
session_wait_event_collection:
  max_rows_per_query: 100
{{- end -}}

{{/*
metrics + resource_attributes for cdb/pdb (self-hosted), verbatim from New
Relic's otel-oracledb docs "Database configuration" section, are supported
from nrdot-collector 2.4.0 (confirmed against nroracledbreceiver v0.158.3's
generated_resource.go) -- except resource_attributes still omits
oracle.db.pdb: it's not a valid resource_attributes key at this version
either (only valid as a per-metric attribute, used throughout the metrics
below), so it stays omitted.
*/}}
{{- define "oracle-otel.receiver.cdbPdbDefaults" -}}
metrics:
  oracledb.cpu_time:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.database.cpu.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.host.cpu.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.executions:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.execution.utilization:
    enabled: true
    attributes: [oracledb.parse.type, oracle.db.pdb]
  oracledb.parse_calls:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parse.rate:
    enabled: true
    attributes: [oracledb.parse.result, oracle.db.pdb]
  oracledb.parse.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.hard_parses:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.logical_reads:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_reads:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_reads_direct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_writes:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_writes_direct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_read_io_requests:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_write_io_requests:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_io.cache_writes:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_io.requests:
    enabled: true
    attributes: [disk.io.direction, disk.io.block_size, oracle.db.pdb]
  oracledb.physical_io.transferred:
    enabled: true
    attributes: [disk.io.direction, disk.io.type, oracle.db.pdb]
  oracledb.sqlnet.io.transferred:
    enabled: true
    attributes: [network.io.direction, destination.type, oracle.db.pdb]
  oracledb.consistent_gets:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.db_block_gets:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.buffer_cache.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.library_cache.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.data_dictionary.hit_ratio:
    enabled: true
  oracledb.shared_pool.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.pga_memory:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.sga.limit:
    enabled: true
  oracledb.sga.usage:
    enabled: true
    attributes: [oracledb.sga.component.name]
  oracledb.database.wait.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.dml_locks.limit:
    enabled: true
  oracledb.dml_locks.usage:
    enabled: true
  oracledb.enqueue_locks.limit:
    enabled: true
  oracledb.enqueue_locks.usage:
    enabled: true
  oracledb.enqueue_resources.limit:
    enabled: true
  oracledb.enqueue_resources.usage:
    enabled: true
  oracledb.enqueue_deadlocks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.exchange_deadlocks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.processes.limit:
    enabled: true
  oracledb.processes.usage:
    enabled: true
  oracledb.sessions.limit:
    enabled: true
  oracledb.sessions.usage:
    enabled: true
    attributes: [session_type, session_status, oracle.db.pdb]
  oracledb.logons:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.transactions.limit:
    enabled: true
  oracledb.transactions.usage:
    enabled: true
  oracledb.user_commits:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.user_rollbacks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.tablespace_size.limit:
    enabled: true
    attributes: [tablespace_name, oracle.db.pdb]
  oracledb.tablespace_size.usage:
    enabled: true
    attributes: [tablespace_name, oracle.db.pdb]
  oracledb.storage.usage:
    enabled: true
  oracledb.storage.utilization:
    enabled: true
  oracledb.recycle_bin.limit:
    enabled: true
  oracledb.queries_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.ddl_statements_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.dml_statements_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_not_downgraded:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_1_to_25_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_25_to_50_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_50_to_75_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_75_to_99_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_to_serial:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.redo_allocation.utilization:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.sort.ratio:
    enabled: true
    attributes: [oracledb.sort.type, oracle.db.pdb]
  oracledb.sql_service.response.duration:
    enabled: true
    attributes: [oracle.db.pdb]
resource_attributes:
  host.name:
    enabled: true
  oracle.db.hosting_type:
    enabled: true
  oracle.db.open_mode:
    enabled: true
  oracle.db.role:
    enabled: true
  oracle.db.version:
    enabled: true
  oracledb.instance.name:
    enabled: true
  service.instance.id:
    enabled: true
{{- end -}}

{{/*
metrics for rds. Verbatim from New Relic's otel-oracledb docs RDS "Database configuration"
section -- fewer metrics than cdb/pdb (RDS restricts access to some V$/DBA_ views), and no
resource_attributes block at all.
*/}}
{{- define "oracle-otel.receiver.rdsDefaults" -}}
metrics:
  oracledb.cpu_time:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.executions:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parse_calls:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.hard_parses:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.logical_reads:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_reads:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_reads_direct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_writes:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_writes_direct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_read_io_requests:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_write_io_requests:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_io.cache_writes:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.physical_io.requests:
    enabled: true
    attributes: [disk.io.direction, disk.io.block_size, oracle.db.pdb]
  oracledb.physical_io.transferred:
    enabled: true
    attributes: [disk.io.direction, disk.io.type, oracle.db.pdb]
  oracledb.sqlnet.io.transferred:
    enabled: true
    attributes: [network.io.direction, destination.type, oracle.db.pdb]
  oracledb.consistent_gets:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.db_block_gets:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.data_dictionary.hit_ratio:
    enabled: true
  oracledb.pga_memory:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.sga.limit:
    enabled: true
  oracledb.sga.usage:
    enabled: true
    attributes: [oracledb.sga.component.name]
  oracledb.enqueue_deadlocks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.exchange_deadlocks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.sessions.usage:
    enabled: true
    attributes: [session_type, session_status, oracle.db.pdb]
  oracledb.logons:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.user_commits:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.user_rollbacks:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.tablespace_size.limit:
    enabled: true
    attributes: [tablespace_name, oracle.db.pdb]
  oracledb.tablespace_size.usage:
    enabled: true
    attributes: [tablespace_name, oracle.db.pdb]
  oracledb.storage.usage:
    enabled: true
  oracledb.storage.utilization:
    enabled: true
  oracledb.recycle_bin.limit:
    enabled: true
  oracledb.queries_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.ddl_statements_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.dml_statements_parallelized:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_not_downgraded:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_1_to_25_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_25_to_50_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_50_to_75_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_75_to_99_pct:
    enabled: true
    attributes: [oracle.db.pdb]
  oracledb.parallel_operations_downgraded_to_serial:
    enabled: true
    attributes: [oracle.db.pdb]
{{- end -}}

{{/*
metrics for adb (Autonomous Database). Verbatim from New Relic's otel-oracledb docs ADB
"Database configuration" section -- fewer metrics than cdb/pdb/rds, no oracle.db.pdb
attribute anywhere (ADB isn't multitenant from the client's perspective), and no
resource_attributes block.
*/}}
{{- define "oracle-otel.receiver.adbDefaults" -}}
metrics:
  oracledb.cpu_time:
    enabled: true
  oracledb.executions:
    enabled: true
  oracledb.parse_calls:
    enabled: true
  oracledb.hard_parses:
    enabled: true
  oracledb.logical_reads:
    enabled: true
  oracledb.physical_reads:
    enabled: true
  oracledb.physical_reads_direct:
    enabled: true
  oracledb.physical_writes:
    enabled: true
  oracledb.physical_writes_direct:
    enabled: true
  oracledb.physical_read_io_requests:
    enabled: true
  oracledb.physical_write_io_requests:
    enabled: true
  oracledb.physical_io.cache_writes:
    enabled: true
  oracledb.physical_io.requests:
    enabled: true
    attributes: [disk.io.direction, disk.io.block_size]
  oracledb.physical_io.transferred:
    enabled: true
    attributes: [disk.io.direction, disk.io.type]
  oracledb.sqlnet.io.transferred:
    enabled: true
    attributes: [network.io.direction, destination.type]
  oracledb.consistent_gets:
    enabled: true
  oracledb.db_block_gets:
    enabled: true
  oracledb.data_dictionary.hit_ratio:
    enabled: true
  oracledb.pga_memory:
    enabled: true
  oracledb.enqueue_deadlocks:
    enabled: true
  oracledb.exchange_deadlocks:
    enabled: true
  oracledb.sessions.usage:
    enabled: true
    attributes: [session_type, session_status]
  oracledb.logons:
    enabled: true
  oracledb.user_commits:
    enabled: true
  oracledb.user_rollbacks:
    enabled: true
  oracledb.tablespace_size.limit:
    enabled: true
    attributes: [tablespace_name]
  oracledb.tablespace_size.usage:
    enabled: true
    attributes: [tablespace_name]
  oracledb.storage.usage:
    enabled: true
  oracledb.storage.utilization:
    enabled: true
  oracledb.recycle_bin.limit:
    enabled: true
  oracledb.queries_parallelized:
    enabled: true
  oracledb.ddl_statements_parallelized:
    enabled: true
  oracledb.dml_statements_parallelized:
    enabled: true
  oracledb.parallel_operations_not_downgraded:
    enabled: true
  oracledb.parallel_operations_downgraded_1_to_25_pct:
    enabled: true
  oracledb.parallel_operations_downgraded_25_to_50_pct:
    enabled: true
  oracledb.parallel_operations_downgraded_50_to_75_pct:
    enabled: true
  oracledb.parallel_operations_downgraded_75_to_99_pct:
    enabled: true
  oracledb.parallel_operations_downgraded_to_serial:
    enabled: true
{{- end -}}

{{/*
Renders one receiver's field block in New Relic's documented order (endpoint/username/password/service/datasource,
collection_interval, events, top_query_collection, query_sample_collection, session_wait_event_collection, metrics,
resource_attributes), falling back to alphabetical order for any other field (e.g. from additionalReceiverConfig).
Caller must emit the `      <receiverKey>:` line itself and invoke this with `{{- include ... }}` (note the leading
`{{-`) immediately after it, since this renders only the field block that follows, at a fixed 8-space (fields) /
10-space (nested content) indent -- i.e. it assumes it's invoked directly under a `receivers:` block whose entries
are indented 6 spaces.

Args (single dict):
  .receiver -- the merged receiver config dict (endpoint/service/username/password/datasource/collection_interval/events/...)
  .isRds    -- bool, selects the RDS metrics order
  .isAdb    -- bool, selects the ADB metrics order
*/}}
{{- define "oracle-otel.renderReceiver" -}}
{{- $receiver := .receiver -}}
{{- $isRds := .isRds -}}
{{- $isAdb := .isAdb -}}
{{- $orderedKeys := list "endpoint" "username" "password" "service" "datasource" "collection_interval" "events" "top_query_collection" "query_sample_collection" "session_wait_event_collection" "metrics" "resource_attributes" }}
{{- $eventsOrder := list "db.server.query_sample" "db.server.top_query" "db.server.session.wait_sample" }}
{{- $topQueryOrder := list "max_query_sample_count" "top_query_count" "collection_interval" }}
{{- $querySampleOrder := list "max_rows_per_query" }}
{{- $rdsMetricsOrder := list "oracledb.cpu_time" "oracledb.executions" "oracledb.parse_calls" "oracledb.hard_parses" "oracledb.logical_reads" "oracledb.physical_reads" "oracledb.physical_reads_direct" "oracledb.physical_writes" "oracledb.physical_writes_direct" "oracledb.physical_read_io_requests" "oracledb.physical_write_io_requests" "oracledb.physical_io.cache_writes" "oracledb.physical_io.requests" "oracledb.physical_io.transferred" "oracledb.sqlnet.io.transferred" "oracledb.consistent_gets" "oracledb.db_block_gets" "oracledb.data_dictionary.hit_ratio" "oracledb.pga_memory" "oracledb.sga.limit" "oracledb.sga.usage" "oracledb.enqueue_deadlocks" "oracledb.exchange_deadlocks" "oracledb.sessions.usage" "oracledb.logons" "oracledb.user_commits" "oracledb.user_rollbacks" "oracledb.tablespace_size.limit" "oracledb.tablespace_size.usage" "oracledb.storage.usage" "oracledb.storage.utilization" "oracledb.recycle_bin.limit" "oracledb.queries_parallelized" "oracledb.ddl_statements_parallelized" "oracledb.dml_statements_parallelized" "oracledb.parallel_operations_not_downgraded" "oracledb.parallel_operations_downgraded_1_to_25_pct" "oracledb.parallel_operations_downgraded_25_to_50_pct" "oracledb.parallel_operations_downgraded_50_to_75_pct" "oracledb.parallel_operations_downgraded_75_to_99_pct" "oracledb.parallel_operations_downgraded_to_serial" }}
{{- $cdbPdbMetricsOrder := list "oracledb.cpu_time" "oracledb.database.cpu.utilization" "oracledb.host.cpu.utilization" "oracledb.executions" "oracledb.execution.utilization" "oracledb.parse_calls" "oracledb.parse.rate" "oracledb.parse.utilization" "oracledb.hard_parses" "oracledb.logical_reads" "oracledb.physical_reads" "oracledb.physical_reads_direct" "oracledb.physical_writes" "oracledb.physical_writes_direct" "oracledb.physical_read_io_requests" "oracledb.physical_write_io_requests" "oracledb.physical_io.cache_writes" "oracledb.physical_io.requests" "oracledb.physical_io.transferred" "oracledb.sqlnet.io.transferred" "oracledb.consistent_gets" "oracledb.db_block_gets" "oracledb.buffer_cache.utilization" "oracledb.library_cache.utilization" "oracledb.data_dictionary.hit_ratio" "oracledb.shared_pool.utilization" "oracledb.pga_memory" "oracledb.sga.limit" "oracledb.sga.usage" "oracledb.database.wait.utilization" "oracledb.dml_locks.limit" "oracledb.dml_locks.usage" "oracledb.enqueue_locks.limit" "oracledb.enqueue_locks.usage" "oracledb.enqueue_resources.limit" "oracledb.enqueue_resources.usage" "oracledb.enqueue_deadlocks" "oracledb.exchange_deadlocks" "oracledb.processes.limit" "oracledb.processes.usage" "oracledb.sessions.limit" "oracledb.sessions.usage" "oracledb.logons" "oracledb.transactions.limit" "oracledb.transactions.usage" "oracledb.user_commits" "oracledb.user_rollbacks" "oracledb.tablespace_size.limit" "oracledb.tablespace_size.usage" "oracledb.storage.usage" "oracledb.storage.utilization" "oracledb.recycle_bin.limit" "oracledb.queries_parallelized" "oracledb.ddl_statements_parallelized" "oracledb.dml_statements_parallelized" "oracledb.parallel_operations_not_downgraded" "oracledb.parallel_operations_downgraded_1_to_25_pct" "oracledb.parallel_operations_downgraded_25_to_50_pct" "oracledb.parallel_operations_downgraded_50_to_75_pct" "oracledb.parallel_operations_downgraded_75_to_99_pct" "oracledb.parallel_operations_downgraded_to_serial" "oracledb.redo_allocation.utilization" "oracledb.sort.ratio" "oracledb.sql_service.response.duration" }}
{{- $adbMetricsOrder := list "oracledb.cpu_time" "oracledb.executions" "oracledb.parse_calls" "oracledb.hard_parses" "oracledb.logical_reads" "oracledb.physical_reads" "oracledb.physical_reads_direct" "oracledb.physical_writes" "oracledb.physical_writes_direct" "oracledb.physical_read_io_requests" "oracledb.physical_write_io_requests" "oracledb.physical_io.cache_writes" "oracledb.physical_io.requests" "oracledb.physical_io.transferred" "oracledb.sqlnet.io.transferred" "oracledb.consistent_gets" "oracledb.db_block_gets" "oracledb.data_dictionary.hit_ratio" "oracledb.pga_memory" "oracledb.enqueue_deadlocks" "oracledb.exchange_deadlocks" "oracledb.sessions.usage" "oracledb.logons" "oracledb.user_commits" "oracledb.user_rollbacks" "oracledb.tablespace_size.limit" "oracledb.tablespace_size.usage" "oracledb.storage.usage" "oracledb.storage.utilization" "oracledb.recycle_bin.limit" "oracledb.queries_parallelized" "oracledb.ddl_statements_parallelized" "oracledb.dml_statements_parallelized" "oracledb.parallel_operations_not_downgraded" "oracledb.parallel_operations_downgraded_1_to_25_pct" "oracledb.parallel_operations_downgraded_25_to_50_pct" "oracledb.parallel_operations_downgraded_50_to_75_pct" "oracledb.parallel_operations_downgraded_75_to_99_pct" "oracledb.parallel_operations_downgraded_to_serial" }}
{{- $metricsOrder := $cdbPdbMetricsOrder }}
{{- if $isRds }}
{{- $metricsOrder = $rdsMetricsOrder }}
{{- else if $isAdb }}
{{- $metricsOrder = $adbMetricsOrder }}
{{- end }}
{{- $emitted := list }}
{{- range $key := $orderedKeys }}
{{- if hasKey $receiver $key }}
{{- if eq $key "events" }}
        events:
{{- $eval := index $receiver $key }}
{{- $eemitted := list }}
{{- range $ekey := $eventsOrder }}
{{- if hasKey $eval $ekey }}
{{ toYaml (dict $ekey (index $eval $ekey)) | indent 10 }}
{{- $eemitted = append $eemitted $ekey }}
{{- end }}
{{- end }}
{{- range $ekey := (keys $eval | sortAlpha) }}
{{- if not (has $ekey $eemitted) }}
{{ toYaml (dict $ekey (index $eval $ekey)) | indent 10 }}
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
{{- if hasKey $tval "allowed_comment_keys" }}
          allowed_comment_keys:
{{- range $item := (index $tval "allowed_comment_keys") }}
            - {{ $item }}
{{- end }}
{{- $temitted = append $temitted "allowed_comment_keys" }}
{{- end }}
{{- range $tkey := (keys $tval | sortAlpha) }}
{{- if not (has $tkey $temitted) }}
{{ toYaml (dict $tkey (index $tval $tkey)) | indent 10 }}
{{- end }}
{{- end }}
{{- else if eq $key "query_sample_collection" }}
        query_sample_collection:
{{- $qval := index $receiver $key }}
{{- $qemitted := list }}
{{- range $qkey := $querySampleOrder }}
{{- if hasKey $qval $qkey }}
{{ toYaml (dict $qkey (index $qval $qkey)) | indent 10 }}
{{- $qemitted = append $qemitted $qkey }}
{{- end }}
{{- end }}
{{- if hasKey $qval "allowed_comment_keys" }}
          allowed_comment_keys:
{{- range $item := (index $qval "allowed_comment_keys") }}
            - {{ $item }}
{{- end }}
{{- $qemitted = append $qemitted "allowed_comment_keys" }}
{{- end }}
{{- range $qkey := (keys $qval | sortAlpha) }}
{{- if not (has $qkey $qemitted) }}
{{ toYaml (dict $qkey (index $qval $qkey)) | indent 10 }}
{{- end }}
{{- end }}
{{- else if eq $key "metrics" }}
        metrics:
{{- $mval := index $receiver $key }}
{{- $memitted := list }}
{{- range $mkey := $metricsOrder }}
{{- if hasKey $mval $mkey }}
{{ include "oracle-otel.renderMetric" (dict "key" $mkey "value" (index $mval $mkey)) | indent 10 }}
{{- $memitted = append $memitted $mkey }}
{{- end }}
{{- end }}
{{- range $mkey := (keys $mval | sortAlpha) }}
{{- if not (has $mkey $memitted) }}
{{ include "oracle-otel.renderMetric" (dict "key" $mkey "value" (index $mval $mkey)) | indent 10 }}
{{- end }}
{{- end }}
{{- else if has $key (list "endpoint" "username" "password" "service" "datasource") }}
        {{ $key }}: {{ (index $receiver $key) | quote }}
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

{{- define "oracle-otel.multi.envVarSuffix" -}}
{{- regexReplaceAll "[^A-Za-z0-9]" (upper .) "_" -}}
{{- end -}}

{{/*
Validates .Values.oracleMulti when oracleMulti.enabled is true: topology, non-empty databases list, each entry's
required fields (name/endpoint/service/existingSecret, plus oracleAdmin.existingSecret when setupJob.enabled),
unique names, and no accidental mixing with the single-instance oracle.endpoint.
*/}}
{{- define "oracle-otel.validate.oracleMulti" -}}
{{- if not (has .Values.oracleMulti.topology (list "cdb" "pdb" "rds" "adb")) -}}
{{- fail "oracleMulti.topology must be one of: cdb, pdb, rds, adb -- required to select the correct nroracledb metrics/events defaults" -}}
{{- end -}}
{{- if not .Values.oracleMulti.databases -}}
{{- fail "oracleMulti.databases must contain at least one entry when oracleMulti.enabled is true" -}}
{{- end -}}
{{- if .Values.oracle.endpoint -}}
{{- fail "oracleMulti.enabled and oracle.endpoint are mutually exclusive -- use one mode or the other in a single release" -}}
{{- end -}}
{{- $seenNames := dict -}}
{{- $seenSuffixes := dict -}}
{{- range $i, $db := .Values.oracleMulti.databases -}}
{{- if not $db.name -}}
{{- fail (printf "oracleMulti.databases[%d].name is required" $i) -}}
{{- end -}}
{{- if not $db.endpoint -}}
{{- fail (printf "oracleMulti.databases[%d].endpoint is required" $i) -}}
{{- end -}}
{{- if not $db.service -}}
{{- fail (printf "oracleMulti.databases[%d].service is required" $i) -}}
{{- end -}}
{{- if not $db.existingSecret -}}
{{- fail (printf "oracleMulti.databases[%d].existingSecret is required" $i) -}}
{{- end -}}
{{- if $.Values.setupJob.enabled -}}
{{- $admin := $db.oracleAdmin | default dict -}}
{{- if not $admin.existingSecret -}}
{{- fail (printf "oracleMulti.databases[%d].oracleAdmin.existingSecret is required when setupJob.enabled is true" $i) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $seenNames $db.name -}}
{{- fail (printf "oracleMulti.databases[%d].name %q duplicates an earlier entry's name" $i $db.name) -}}
{{- end -}}
{{- $seenNames = set $seenNames $db.name true -}}
{{- $suffix := include "oracle-otel.multi.envVarSuffix" $db.name -}}
{{- if hasKey $seenSuffixes $suffix -}}
{{- fail (printf "oracleMulti.databases[%d].name %q collides with another entry's name after env-var sanitization (%q) -- choose more distinct names" $i $db.name $suffix) -}}
{{- end -}}
{{- $seenSuffixes = set $seenSuffixes $suffix true -}}
{{- end -}}
{{- end -}}
