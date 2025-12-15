{{- /*
  KUBERNETES EVENTS RECEIVER

  This file contains the complete k8s_events collection flow:
  1. Receiver definition (k8s events collection)
  2. Related processors (event-specific transforms and resource enrichment)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - k8s_events receiver config
2. PROCESSORS - all event-specific transforms and enrichment
3. ROUTING - how events flow through pipelines

  Usage:
In statefulset.yaml receivers section:
  k8s_events: {}

In statefulset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.k8sEvents.processors" . | nindent 6 }}

In statefulset.yaml pipelines section (logs/ingress):
  receivers: [..., k8s_events]
  processors: [..., resource/events, transform/events]
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* k8sEvents: Kubernetes event collection from cluster */ -}}
{{/* Receiver definition is empty config - included inline in statefulset.yaml as: k8s_events: {} */ -}}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* k8sEvents.processors: All event-specific transforms and enrichment */ -}}
{{- define "nrKubernetesOtel.receivers.k8sEvents.processors" -}}
# Kubernetes events resource enrichment
# Tags k8s_events logs with New Relic event metadata
resource/events:
  attributes:
    - key: "newrelic.event.type"
      action: upsert
      value: "OtlpInfrastructureEvent"
    - key: "category"
      action: upsert
      value: "kubernetes"
    - key: k8s.cluster.name
      action: upsert
      value: {{ include "newrelic.common.cluster" . }}
    - key: "newrelic.chart.version"
      action: upsert
      value: {{ .Chart.Version }}

# Kubernetes events log enrichment
# Adds node information to event logs for better context
transform/events:
  log_statements:
    - context: log
      statements:
        - set(log.attributes["event.source.host"], resource.attributes["k8s.node.name"])
{{- end }}

