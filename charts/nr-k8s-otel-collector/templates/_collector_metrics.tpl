{{- /*
  COLLECTOR METRICS RECEIVER AND PROCESSOR

  This file contains the configuration for collecting metrics from the
  OpenTelemetry Collector itself (self-telemetry). This applies to both
  daemonset and statefulset collectors when enabled.

  Organization:
1. RECEIVER - self-telemetry prometheus job
2. PROCESSOR - low data mode tagging for collector metrics
*/ -}}

{{- /* ========== RECEIVER ========== */ -}}

{{- /* collectorMetrics.daemonset.receiver: Prometheus scrape job for daemonset collector self-telemetry */ -}}
{{- define "nrKubernetesOtel.receivers.collectorMetrics.daemonset.receiver" -}}
{{- if (((.Values.receivers).collectorMetrics).enabled) }}
- job_name: otel-collector
  scrape_interval: {{ ((.Values.receivers).collectorMetrics).scrapeInterval | default "1m" }}
  static_configs:
    - targets: ['0.0.0.0:8888']
  relabel_configs:
    - action: replace
      target_label: job_label
      replacement: otel-collector-daemonset
{{- end }}
{{- end }}

{{- /* collectorMetrics.statefulset.receiver: Prometheus scrape job for statefulset collector self-telemetry */ -}}
{{- define "nrKubernetesOtel.receivers.collectorMetrics.statefulset.receiver" -}}
{{- if (((.Values.receivers).collectorMetrics).enabled) }}
- job_name: otel-collector
  scrape_interval: {{ ((.Values.receivers).collectorMetrics).scrapeInterval | default "1m" }}
  static_configs:
    - targets: ['0.0.0.0:8888']
  relabel_configs:
    - action: replace
      target_label: job_label
      replacement: otel-collector-statefulset
{{- end }}
{{- end }}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* collectorMetrics.daemonset.processors: Tag daemonset collector metrics as low data mode */ -}}
{{- define "nrKubernetesOtel.receivers.collectorMetrics.daemonset.processors" -}}
# Collector self-telemetry low data mode tagging (daemonset)
# Tags metrics from the otel-collector-daemonset job as low.data.mode=true for conditional filtering
transform/collector:
  metric_statements:
    - set(datapoint.attributes["low.data.mode"], "true") where datapoint.attributes["job_label"] == "otel-collector-daemonset"
{{- end }}

{{- /* collectorMetrics.statefulset.processors: Tag statefulset collector metrics as low data mode */ -}}
{{- define "nrKubernetesOtel.receivers.collectorMetrics.statefulset.processors" -}}
# Collector self-telemetry low data mode tagging (statefulset)
# Tags metrics from the otel-collector-statefulset job as low.data.mode=true for conditional filtering
transform/collector:
  metric_statements:
    - set(datapoint.attributes["low.data.mode"], "true") where datapoint.attributes["job_label"] == "otel-collector-statefulset"
{{- end }}

