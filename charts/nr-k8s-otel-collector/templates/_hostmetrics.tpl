{{- /*
  HOSTMETRICS RECEIVER CONFIGURATION

  This file contains the complete hostmetrics collection flow:
  1. Receiver definition (hostmetrics scraper configuration)
  2. Related processors (transforms, aggregations, filters)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - hostmetrics scraper config
2. PROCESSORS - all hostmetrics-specific transforms, aggregations, and filters
3. ROUTING - how hostmetrics metrics flow through pipelines

  Usage:
In daemonset.yaml receivers section:
  {{- include "nrKubernetesOtel.receivers.hostmetrics.config" . | nindent 6 }}

In daemonset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.hostmetrics.processors" . | nindent 6 }}

In daemonset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.hostmetrics.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* hostmetrics: Node-level host metrics (CPU, memory, disk, network, filesystem) */ -}}
{{- define "nrKubernetesOtel.receivers.hostmetrics.config" -}}hostmetrics:
  # TODO (chris): this is a linux specific configuration
  {{- if not (include "newrelic.common.gkeAutopilot" .) }}
  root_path: /hostfs
  {{- end }}
  collection_interval: {{ .Values.receivers.hostmetrics.scrapeInterval }}
  scrapers:
    cpu:
      metrics:
        system.cpu.time:
          enabled: false
        system.cpu.utilization:
          enabled: true
        system.cpu.logical.count:
          enabled: true
    load: {}
    memory:
      metrics:
        system.memory.utilization:
          enabled: true
    paging:
      metrics:
        system.paging.utilization:
          enabled: false
        system.paging.faults:
          enabled: false
    filesystem:
      metrics:
        system.filesystem.utilization:
          enabled: true
    disk:
      metrics:
        system.disk.merged:
          enabled: false
        system.disk.pending_operations:
          enabled: false
        system.disk.weighted_io_time:
          enabled: false
    network:
      metrics:
        system.network.connections:
          enabled: false
# Uncomment to enable process metrics, which can be noisy but valuable.
# processes:
# process:
#   metrics:
# process.cpu.utilization:
#   enabled: true
# process.cpu.time:
#   enabled: false
#   mute_process_name_error: true
#   mute_process_exe_error: true
#   mute_process_io_error: true
#   mute_process_user_error: true
{{- end }}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* hostmetrics.processors: All hostmetrics-specific transforms, aggregations, and filters */ -}}
{{- define "nrKubernetesOtel.receivers.hostmetrics.processors" -}}
# Hostmetrics CPU aggregation and metric transformations
metricstransform/hostmetrics_cpu:
  transforms:
    - include: system.cpu.utilization
      action: update
      operations:
        - action: aggregate_labels
          label_set: [ state ]
          aggregation_type: mean
    - include: system.paging.operations
      action: update
      operations:
        - action: aggregate_labels
          label_set: [ direction ]
          aggregation_type: sum

# Hostmetrics low data mode tagging (for conditional filtering)
metricstransform/hostmetrics:
  transforms:
    - include: process\.(cpu\.utilization|disk\.io|memory\.(usage|virtual))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: system\.cpu\.(utilization|load_average\.(15m|1m|5m))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: system\.disk\.(io_time|operation_time|operations)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: system\.(filesystem|memory)\.(usage|utilization)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: system\.network\.(errors|io|packets)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'

# Metric filtering: reduce noise from system metrics
filter/exclude_cpu_utilization:
  metrics:
    datapoint:
      - 'metric.name == "system.cpu.utilization" and attributes["state"] == "interrupt"'
      - 'metric.name == "system.cpu.utilization" and attributes["state"] == "nice"'
      - 'metric.name == "system.cpu.utilization" and attributes["state"] == "softirq"'

filter/exclude_memory_utilization:
  metrics:
    datapoint:
      - 'metric.name == "system.memory.utilization" and attributes["state"] == "slab_unreclaimable"'
      - 'metric.name == "system.memory.utilization" and attributes["state"] == "inactive"'
      - 'metric.name == "system.memory.utilization" and attributes["state"] == "cached"'
      - 'metric.name == "system.memory.utilization" and attributes["state"] == "buffered"'
      - 'metric.name == "system.memory.utilization" and attributes["state"] == "slab_reclaimable"'

filter/exclude_memory_usage:
  metrics:
    datapoint:
      - 'metric.name == "system.memory.usage" and attributes["state"] == "slab_unreclaimable"'
      - 'metric.name == "system.memory.usage" and attributes["state"] == "inactive"'

filter/exclude_filesystem_utilization:
  metrics:
    datapoint:
      - 'metric.name == "system.filesystem.utilization" and attributes["type"] == "squashfs"'

filter/exclude_filesystem_usage:
  metrics:
    datapoint:
      - 'metric.name == "system.filesystem.usage" and attributes["type"] == "squashfs"'
      - 'metric.name == "system.filesystem.usage" and attributes["state"] == "reserved"'

filter/exclude_filesystem_inodes_usage:
  metrics:
    datapoint:
      - 'metric.name == "system.filesystem.inodes.usage" and attributes["type"] == "squashfs"'
      - 'metric.name == "system.filesystem.inodes.usage" and attributes["state"] == "reserved"'

filter/exclude_system_disk:
  metrics:
    datapoint:
      - 'metric.name == "system.disk.operations" and IsMatch(attributes["device"], "^loop.*") == true'
      - 'metric.name == "system.disk.merged" and IsMatch(attributes["device"], "^loop.*") == true'
      - 'metric.name == "system.disk.io" and IsMatch(attributes["device"], "^loop.*") == true'
      - 'metric.name == "system.disk.io_time" and IsMatch(attributes["device"], "^loop.*") == true'
      - 'metric.name == "system.disk.operation_time" and IsMatch(attributes["device"], "^loop.*") == true'

filter/exclude_system_paging:
  metrics:
    datapoint:
      - 'metric.name == "system.paging.usage" and attributes["state"] == "cached"'
      - 'metric.name == "system.paging.operations" and attributes["type"] == "cached"'

filter/exclude_network:
  metrics:
    datapoint:
      - 'IsMatch(metric.name, "^system.network.*") == true and attributes["device"] == "lo"'

# Container-level metric filtering (from kubeletstats receiver, processed together with hostmetrics)
filter/nr_exclude_container_zero_values:
  metrics:
    datapoint:
      - metric.name == "container_network_receive_errors_total" and value_double < 0.5
      - metric.name == "container_network_transmit_errors_total" and value_double < 0.5
      - metric.name == "container_network_transmit_bytes_total" and value_double < 0.5
      - metric.name == "container_network_receive_bytes_total" and value_double < 0.5

# Attribute filtering for paging metrics (remove unnecessary dimension)
attributes/exclude_system_paging:
  include:
    match_type: strict
    metric_names:
      - system.paging.operations
  actions:
    - key: type
      action: delete

# Environment and system resource detection
resourcedetection/env:
  detectors: ["env", "system"]
  override: false
  system:
    hostname_sources: ["os"]
    resource_attributes:
      host.name:
        enabled: false
{{- end }}
