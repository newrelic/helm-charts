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
metrics + resource_attributes for cdb/pdb (self-hosted). Verbatim from New Relic's
otel-oracledb docs "Database configuration" section -- identical between cdb and pdb.
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
  oracle.db.pdb:
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
