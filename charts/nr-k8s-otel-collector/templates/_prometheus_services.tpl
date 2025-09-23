{{- /*
A helper to return the scrape config for prometheus services
*/}}
{{- define "nrKubernetesOtel.receivers.prometheusServices.scrapeConfigs" -}}
- job_name: default-pod
  honor_timestamps: true
  track_timestamps_staleness: false
  scrape_interval: 30s
  scrape_timeout: 10s
  scrape_protocols:
    - OpenMetricsText1.0.0
    - OpenMetricsText0.0.1
    - PrometheusText1.0.0
    - PrometheusText0.0.4
  fallback_scrape_protocol: PrometheusText0.0.4
  convert_classic_histograms_to_nhcb: false
  metrics_path: /metrics
  scheme: http
  enable_compression: true
  metric_name_validation_scheme: utf8
  metric_name_escaping_scheme: allow-utf-8
  follow_redirects: true
  enable_http2: true
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      separator: ;
      regex: "true"
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_pod_phase]
      separator: ;
      regex: Pending|Succeeded|Failed|Completed
      replacement: $1
      action: drop
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
      separator: ;
      regex: (https?)
      target_label: __scheme__
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      separator: ;
      regex: (.+)
      target_label: __metrics_path__
      replacement: $1
      action: replace
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      separator: ;
      regex: (.+?)(?::\d+)?;(\d+)
      target_label: __address__
      replacement: $1:$2
      action: replace
    - separator: ;
      regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
      replacement: __param_$1
      action: labelmap
    - separator: ;
      regex: __meta_kubernetes_pod_label_(.+)
      replacement: $1
      action: labelmap
    - source_labels: [__meta_kubernetes_namespace]
      separator: ;
      target_label: namespace
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_node_name]
      separator: ;
      target_label: node
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_name]
      separator: ;
      target_label: pod
      replacement: $1
      action: replace
    {{- if ((((.Values.receivers).prometheusServices).integrationsFilter).enabled) }}
    - source_labels:
        {{- include "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.sourceLabels.pod" . | nindent 8 }}
      separator: ;
      regex: {{ include "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.appValuesRegex" . }}
      replacement: $1
      action: keep
    {{- end }}
  kubernetes_sd_configs:
    - role: pod
      kubeconfig_file: ""
      follow_redirects: true
      enable_http2: true
- job_name: default-endpoints
  honor_timestamps: true
  track_timestamps_staleness: false
  scrape_interval: 30s
  scrape_timeout: 10s
  scrape_protocols:
    - OpenMetricsText1.0.0
    - OpenMetricsText0.0.1
    - PrometheusText1.0.0
    - PrometheusText0.0.4
  fallback_scrape_protocol: PrometheusText0.0.4
  convert_classic_histograms_to_nhcb: false
  metrics_path: /metrics
  scheme: http
  enable_compression: true
  metric_name_validation_scheme: utf8
  metric_name_escaping_scheme: allow-utf-8
  follow_redirects: true
  enable_http2: true
  relabel_configs:
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
      separator: ;
      regex: "true"
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_pod_phase]
      separator: ;
      regex: Succeeded|Failed|Completed
      replacement: $1
      action: drop
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
      separator: ;
      regex: (https?)
      target_label: __scheme__
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
      separator: ;
      regex: (.+)
      target_label: __metrics_path__
      replacement: $1
      action: replace
    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
      separator: ;
      regex: (.+?)(?::\d+)?;(\d+)
      target_label: __address__
      replacement: $1:$2
      action: replace
    - separator: ;
      regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
      replacement: __param_$1
      action: labelmap
    - separator: ;
      regex: __meta_kubernetes_service_label_(.+)
      replacement: $1
      action: labelmap
    - source_labels: [__meta_kubernetes_namespace]
      separator: ;
      target_label: namespace
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_name]
      separator: ;
      target_label: service
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_endpoint_node_name, __meta_kubernetes_pod_node_name]
      separator: ;
      regex: .*;(.+)|(.+);
      target_label: node
      replacement: $1$2
      action: replace
    - source_labels: [__meta_kubernetes_pod_name]
      separator: ;
      target_label: pod
      replacement: $1
      action: replace
    {{- if ((((.Values.receivers).prometheusServices).integrationsFilter).enabled )}}
    - source_labels:
        {{- include "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.sourceLabels.service" . | nindent 8 }}
      separator: ;
      regex: {{ include "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.appValuesRegex" . }}
      replacement: $1
      action: keep
    {{- end }}
  kubernetes_sd_configs:
    - role: endpoints
      kubeconfig_file: ""
      follow_redirects: true
      enable_http2: true
- job_name: newrelic-pod
  honor_timestamps: true
  track_timestamps_staleness: false
  scrape_interval: 30s
  scrape_timeout: 10s
  scrape_protocols:
    - OpenMetricsText1.0.0
    - OpenMetricsText0.0.1
    - PrometheusText1.0.0
    - PrometheusText0.0.4
  fallback_scrape_protocol: PrometheusText0.0.4
  convert_classic_histograms_to_nhcb: false
  metrics_path: /metrics
  scheme: http
  enable_compression: true
  metric_name_validation_scheme: utf8
  metric_name_escaping_scheme: allow-utf-8
  follow_redirects: true
  enable_http2: true
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_newrelic_io_scrape]
      separator: ;
      regex: "true"
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_pod_phase]
      separator: ;
      regex: Pending|Succeeded|Failed|Completed
      replacement: $1
      action: drop
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
      separator: ;
      regex: (https?)
      target_label: __scheme__
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      separator: ;
      regex: (.+)
      target_label: __metrics_path__
      replacement: $1
      action: replace
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      separator: ;
      regex: (.+?)(?::\d+)?;(\d+)
      target_label: __address__
      replacement: $1:$2
      action: replace
    - separator: ;
      regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
      replacement: __param_$1
      action: labelmap
    - separator: ;
      regex: __meta_kubernetes_pod_label_(.+)
      replacement: $1
      action: labelmap
    - source_labels: [__meta_kubernetes_namespace]
      separator: ;
      target_label: namespace
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_node_name]
      separator: ;
      target_label: node
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_name]
      separator: ;
      target_label: pod
      replacement: $1
      action: replace
  kubernetes_sd_configs:
    - role: pod
      kubeconfig_file: ""
      follow_redirects: true
      enable_http2: true
- job_name: newrelic-endpoints
  honor_timestamps: true
  track_timestamps_staleness: false
  scrape_interval: 30s
  scrape_timeout: 10s
  scrape_protocols:
    - OpenMetricsText1.0.0
    - OpenMetricsText0.0.1
    - PrometheusText1.0.0
    - PrometheusText0.0.4
  fallback_scrape_protocol: PrometheusText0.0.4
  convert_classic_histograms_to_nhcb: false
  metrics_path: /metrics
  scheme: http
  enable_compression: true
  metric_name_validation_scheme: utf8
  metric_name_escaping_scheme: allow-utf-8
  follow_redirects: true
  enable_http2: true
  relabel_configs:
    - source_labels: [__meta_kubernetes_service_annotation_newrelic_io_scrape]
      separator: ;
      regex: "true"
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_pod_phase]
      separator: ;
      regex: Succeeded|Failed|Completed
      replacement: $1
      action: drop
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
      separator: ;
      regex: (https?)
      target_label: __scheme__
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
      separator: ;
      regex: (.+)
      target_label: __metrics_path__
      replacement: $1
      action: replace
    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
      separator: ;
      regex: (.+?)(?::\d+)?;(\d+)
      target_label: __address__
      replacement: $1:$2
      action: replace
    - separator: ;
      regex: __meta_kubernetes_service_annotation_prometheus_io_param_(.+)
      replacement: __param_$1
      action: labelmap
    - separator: ;
      regex: __meta_kubernetes_service_label_(.+)
      replacement: $1
      action: labelmap
    - source_labels: [__meta_kubernetes_namespace]
      separator: ;
      target_label: namespace
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_name]
      separator: ;
      target_label: service
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_endpoint_node_name, __meta_kubernetes_pod_node_name]
      separator: ;
      regex: .*;(.+)|(.+);
      target_label: node
      replacement: $1$2
      action: replace
    - source_labels: [__meta_kubernetes_pod_name]
      separator: ;
      target_label: pod
      replacement: $1
      action: replace
  kubernetes_sd_configs:
    - role: endpoints
      kubeconfig_file: ""
      follow_redirects: true
      enable_http2: true
{{ ((.Values.receivers).prometheusServices).extraScrapeConfigs | toYaml }}
{{- end }}


{{- /*
A helper to return the integrations filter regex
*/}}
{{- define "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.appValuesRegex" -}}
".*(?i)({{ join "|" ((((.Values.receivers).prometheusServices).integrationsFilter).appValues) }}).*"
{{- end }}

{{- /*
A helper to return the source labels for the integrations filter in a pod
*/}}
{{- define "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.sourceLabels.pod" }}
{{- $podLabels := list }}
{{- range $label := ((((.Values.receivers).prometheusServices).integrationsFilter).sourceLabels) }}
    {{- $cleanLabel := mustRegexReplaceAll "[^a-zA-Z0-9_]" $label "_" }}
    {{- $podLabels = append $podLabels (printf "__meta_kubernetes_pod_label_%s" $cleanLabel) }}
{{- end -}}
{{ $podLabels | toYaml }}
{{- end }}

{{- /*
A helper to return the source labels for the integrations filter in a service
*/}}
{{- define "nrKubernetesOtel.receivers.prometheusServices.integrationsFilter.sourceLabels.service" }}
{{- $podLabels := list }}
{{- range $label := ((((.Values.receivers).prometheusServices).integrationsFilter).sourceLabels) }}
    {{- $cleanLabel := mustRegexReplaceAll "[^a-zA-Z0-9_]" $label "_" }}
    {{- $podLabels = append $podLabels (printf "__meta_kubernetes_service_label_%s" $cleanLabel) }}
{{- end -}}
{{ $podLabels | toYaml }}
{{- end }}
