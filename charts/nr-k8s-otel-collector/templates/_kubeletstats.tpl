{{- /*
  KUBELETSTATS RECEIVER CONFIGURATION

  This file contains the complete kubeletstats collection flow:
  1. Receiver definition (kubeletstats scraper configuration)
  2. Related processors (transforms, aggregations, filters)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - kubeletstats scraper config
2. PROCESSORS - all kubeletstats-specific transforms and filters
3. ROUTING - how kubeletstats metrics flow through pipelines

  Usage:
In daemonset.yaml receivers section:
  {{- include "nrKubernetesOtel.receivers.kubeletstats.config" . | nindent 6 }}

In daemonset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.kubeletstats.processors" . | nindent 6 }}

In daemonset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.kubeletstats.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* kubeletstats: Container-level CPU, memory, filesystem metrics from Kubelet API */ -}}
{{- define "nrKubernetesOtel.receivers.kubeletstats.config" -}}
kubeletstats:
  collection_interval: {{ .Values.receivers.kubeletstats.scrapeInterval }}
  {{- if not (include "newrelic.common.gkeAutopilot" .) }}
  endpoint: "${KUBE_NODE_NAME}:10250"
  auth_type: "serviceAccount"
  insecure_skip_verify: true
  {{- else }}
  endpoint: "${KUBE_NODE_NAME}:10255"
  auth_type: "none"
  {{- end }}
  metrics:
    k8s.container.cpu_limit_utilization:
      enabled: true
    k8s.pod.cpu_limit_utilization:
      enabled: true
    k8s.pod.cpu_request_utilization:
      enabled: true
    k8s.pod.memory_limit_utilization:
      enabled: true
    k8s.pod.memory_request_utilization:
      enabled: true
{{- end -}}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* kubeletstats.processors: All kubeletstats-specific transforms and filters */ -}}
{{- define "nrKubernetesOtel.receivers.kubeletstats.processors" -}}
# Kubeletstats low data mode tagging (for conditional filtering)
metricstransform/kubeletstats:
  transforms:
    - include: container\.(cpu\.usage|filesystem\.(available|capacity|usage)|memory\.usage)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: k8s\.node\.(cpu\.(time|usage)|filesystem\.(capacity|usage)|memory\.(available|working_set))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: k8s\.pod\.(filesystem\.(available|capacity|usage)|memory\.working_set|network\.io)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: k8s\.pod\.(cpu|memory)_(limit|request)_utilization
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: k8s\.pod\.(cpu|memory)_request_limit_ratio
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'

# Kubeletstats-derived metric calculations and tagging
# These metrics are GENERATED from kubeletstats receiver inputs
metricsgeneration/calculate_percentage:
  rules:
    # Ratio of Requested Resources to Limits
    # request_limit_ratio = Limit_Utilization / Request_Utilization
    # = (usage / limit) / (usage / request) = (usage / limit) * (request / usage) = request / limit
    - name: k8s.pod.memory_request_limit_ratio
      type: calculate
      metric1: k8s.pod.memory_limit_utilization
      metric2: k8s.pod.memory_request_utilization
      operation: divide
    - name: k8s.pod.cpu_request_limit_ratio
      type: calculate
      metric1: k8s.pod.cpu_limit_utilization
      metric2: k8s.pod.cpu_request_utilization
      operation: divide
    - name: node.cpu.usage.percentage
      type: scale
      metric1: k8s.node.cpu.usage
      scale_by: 1.0e9
      operation: divide
    - name: node.memory.usage.percentage
      type: scale
      metric1: k8s.node.memory.working_set
      scale_by: 1.0e9
      operation: divide

# Tag kubeletstats-generated metrics for low data mode filtering
transform/tag_generated_metrics_ldm:
  metric_statements:
    - context: datapoint
      conditions:
        - metric.name == "k8s.pod.cpu_request_limit_ratio"
        - metric.name == "k8s.pod.memory_request_limit_ratio"
        - metric.name == "node.cpu.usage.percentage"
        - metric.name == "node.memory.usage.percentage"
      statements:
        - set(attributes["low.data.mode"], "true")
{{- end -}}
