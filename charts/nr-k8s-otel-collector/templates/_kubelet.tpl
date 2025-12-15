{{- /*
  KUBELET PROMETHEUS SCRAPE JOB

  This file contains the complete kubelet metrics collection flow:
  1. Prometheus scrape job definition (kubelet metrics endpoint)
  2. Related processors (kubelet-specific metric transformations)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - kubelet scrape job config
2. PROCESSORS - all kubelet-specific transforms and filters
3. ROUTING - how kubelet metrics flow through pipelines

  Usage:
In daemonset.yaml prometheus scrape_configs:
  {{- include "nrKubernetesOtel.receivers.kubelet.daemonset.job" . | nindent 12 }}

In daemonset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.kubelet.processors" . | nindent 6 }}

In daemonset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.kubelet.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* kubelet.daemonset.job: Node and pod metrics from kubelet endpoint */ -}}
{{- define "nrKubernetesOtel.receivers.kubelet.daemonset.job" -}}
- job_name: kubelet
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - replacement: kubernetes.default.svc.cluster.local:443
      target_label: __address__
    - regex: (.+)
      replacement: /api/v1/nodes/$${1}/proxy/metrics
      source_labels:
        - __meta_kubernetes_node_name
      target_label: __metrics_path__
    - action: replace
      target_label: job_label
      replacement: kubelet
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

{{- /* kubelet.processors: All kubelet-specific transforms and filters */ -}}
{{- define "nrKubernetesOtel.receivers.kubelet.processors" -}}
# Kubelet process and cluster metrics low data mode tagging
metricstransform/kubelet:
  transforms:
    - include: go_(goroutines|threads)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: process_resident_memory_bytes
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: k8s.cluster.info
      action: update
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
{{- end }}

