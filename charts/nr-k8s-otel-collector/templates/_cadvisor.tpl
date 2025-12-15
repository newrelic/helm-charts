{{- /*
  CADVISOR PROMETHEUS SCRAPE JOB

  This file contains the complete cadvisor metrics collection flow:
  1. Prometheus scrape job definition (cadvisor endpoint)
  2. Related processors (cadvisor-specific metric transformations)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - cadvisor scrape job config
2. PROCESSORS - all cadvisor-specific transforms and filters
3. ROUTING - how cadvisor metrics flow through pipelines

  Usage:
In daemonset.yaml prometheus scrape_configs:
  {{- include "nrKubernetesOtel.receivers.cadvisor.daemonset.job" . | nindent 12 }}

In daemonset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.cadvisor.processors" . | nindent 6 }}

In daemonset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.cadvisor.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* cadvisor.daemonset.job: Container-level metrics from kubelet cAdvisor endpoint */ -}}
{{- define "nrKubernetesOtel.receivers.cadvisor.daemonset.job" -}}
- job_name: cadvisor
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - replacement: kubernetes.default.svc.cluster.local:443
      target_label: __address__
    - regex: (.+)
      replacement: /api/v1/nodes/$${1}/proxy/metrics/cadvisor
      source_labels:
        - __meta_kubernetes_node_name
      target_label: __metrics_path__
    - action: replace
      target_label: job_label
      replacement: cadvisor
{{- if not (and .Values.targetAllocator.enabled (eq .Values.targetAllocator.strategy "per-node")) }}
    # Only filter by node when NOT using per-node Target Allocator
    - source_labels: [__meta_kubernetes_node_name]
      regex: ${KUBE_NODE_NAME}
      action: keep
{{- end }}
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: false
    server_name: kubernetes
{{- end }}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* cadvisor.processors: All cadvisor-specific transforms and filters */ -}}
{{- define "nrKubernetesOtel.receivers.cadvisor.processors" -}}
# Cadvisor container metrics low data mode tagging
metricstransform/cadvisor:
  transforms:
    - include: container_cpu_(cfs_(periods_total|throttled_periods_total)|usage_seconds_total)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: container_memory_working_set_bytes
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: container_memory_mapped_file
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: container_network_(working_set_bytes|receive_(bytes_total|errors_total)|transmit_(bytes_total|errors_total))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: container_spec_memory_limit_bytes
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
{{- end }}

