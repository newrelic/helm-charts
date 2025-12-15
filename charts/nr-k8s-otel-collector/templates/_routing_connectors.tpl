{{- /*
  ROUTING CONNECTORS AND PIPELINE DISTRIBUTION

  This file contains routing connector definitions that distribute metrics through
  pipelines based on receiver type (daemonset) or job labels (statefulset).

  Organization:
1. DAEMONSET ROUTING - Routes by instrumentation_scope.name (receiver type)
2. STATEFULSET ROUTING - Routes by instrumentation_scope.attributes["job_label"]
*/ -}}

{{- /* ========== DAEMONSET ROUTING ========== */ -}}

{{- /* nrmetricspipelines.daemonset: Connector for daemonset metrics distribution */ -}}
{{- /* Routes metrics to appropriate pipelines based on receiver instrumentation scope */ -}}
{{- define "nrKubernetesOtel.common.connectors.nrmetricspipelines.daemonset" -}}
routing/nr_metrics_pipelines:
  default_pipelines: [metrics/default]
  error_mode: propagate
  table:
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/networkscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/loadscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/diskscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/memoryscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/cpuscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/filesystemscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver/internal/scraper/pagingscraper"
      pipelines: [metrics/nr]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/prometheusreceiver"
      pipelines: [metrics/nr_prometheus_cadv_kubelet]
    - context: metric
      condition: instrumentation_scope.name == "github.com/open-telemetry/opentelemetry-collector-contrib/receiver/kubeletstatsreceiver"
      pipelines: [metrics/nr]
{{- end }}

{{- /* ========== STATEFULSET ROUTING ========== */ -}}

{{- /* nrmetricspipelines.statefulset: Connector for statefulset metrics distribution */ -}}
{{- /* Routes metrics to appropriate pipelines based on job_label attribute (set by prometheus relabel_configs) */ -}}
{{- define "nrKubernetesOtel.common.connectors.nrmetricspipelines.statefulset" -}}
routing/nr_metrics_pipelines:
  default_pipelines: [metrics/default]
  error_mode: propagate
  table:
    - context: metric
      condition: instrumentation_scope.attributes["job_label"] == "kube-state-metrics"
      pipelines: [metrics/nr_ksm]
    - context: metric
      condition: instrumentation_scope.attributes["job_label"] == "apiserver"
      pipelines: [metrics/nr_controlplane]
    - context: metric
      condition: instrumentation_scope.attributes["job_label"] == "controller-manager"
      pipelines: [metrics/nr_controlplane]
    - context: metric
      condition: instrumentation_scope.attributes["job_label"] == "scheduler"
      pipelines: [metrics/nr_controlplane]
{{- end }}
