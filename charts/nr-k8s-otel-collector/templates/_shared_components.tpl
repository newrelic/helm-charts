{{- /*
  SHARED SPECIFICATIONS FOR OPENTELEMETRY COLLECTOR

  This file contains reusable helpers for configurations that are identical
  across deployment modes (daemonset, statefulset).

  Organization:
1. PROCESSORS - Processing pipeline components
2. EXPORTERS  - Data export configurations
3. CONNECTORS - Routing and pipeline connectors
4. PIPELINES  - Service pipeline definitions
*/ -}}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* memory_limiter: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.memoryLimiter" -}}
memory_limiter:
  check_interval: 1s
  limit_percentage: 80
  spike_limit_percentage: 25
{{- end }}

{{- /* batch: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.batch" -}}
batch:
  send_batch_max_size: 1000
  timeout: 30s
  send_batch_size: 800
{{- end }}

{{- /* cumulativetodelta/standard: Standard cumulative to delta conversion (no exclusions) */ -}}
{{- /* Used in: daemonset metrics/nr, statefulset metrics/nr_controlplane and metrics/default */ -}}
{{- define "nrKubernetesOtel.common.processors.cumulativetodelta.standard" -}}
cumulativetodelta: {}
{{- end }}

{{- /* cumulativetodelta/ksm: KSM-specific with exclusion for restart counts */ -}}
{{- /* Excludes kube_pod_container_status_restarts_total from delta conversion */ -}}
{{- /* Used in: statefulset metrics/nr_ksm pipeline */ -}}
{{- define "nrKubernetesOtel.common.processors.cumulativetodelta.ksm" -}}
cumulativetodelta/ksm:
  exclude:
    metrics:
      - 'kube_pod_container_status_restarts_total'
    match_type: strict
{{- end }}

{{- /* cumulativetodelta (unnamed): Kept for backward compatibility with daemonset */ -}}
{{- define "nrKubernetesOtel.common.processors.cumulativetodelta" -}}
cumulativetodelta: {}
{{- end }}

{{- /* k8sattributes/ksm (per-node): Daemonset variant with node filtering */ -}}
{{- /* Filters metadata lookups to current node via KUBE_NODE_NAME environment variable */ -}}
{{- /* Used in: daemonset metrics/nr, metrics/nr_ksm-like, and logs/pipeline */ -}}
{{- define "nrKubernetesOtel.common.processors.k8sattributesPerNode" -}}
k8sattributes/ksm:
  # Metadata attached by this processor is reliant on the uid & pod name. This would be sufficient for most types
  # of metrics but there are cases of metrics where a uid would not be present and thus metadata would
  # not be attached. To address cases like these, metadata attributes must be annotated in a different manner
  # such as by preserving some of the attributes presented by KSM.
  auth_type: "serviceAccount"
  passthrough: false
  filter:
    node_from_env_var: KUBE_NODE_NAME
  extract:
    metadata:
      - k8s.deployment.name
      - k8s.daemonset.name
      - k8s.namespace.name
      - k8s.node.name
      - k8s.pod.start_time
      - k8s.replicaset.name
      - k8s.statefulset.name
      - k8s.cronjob.name
      - k8s.job.name
  pod_association:
    - sources:
        - from: resource_attribute
          name: k8s.pod.uid
    - sources:
        - from: resource_attribute
          name: k8s.pod.name
{{- end }}

{{- /* groupbyattrs: Shared across daemonset and statefulset (27 lines) */ -}}
{{- define "nrKubernetesOtel.common.processors.groupbyattrs" -}}
groupbyattrs:
  keys:
    - pod
    - uid
    - container
    - daemonset
    - replicaset
    - statefulset
    - deployment
    - cronjob
    - configmap
    - job
    - job_name
    - horizontalpodautoscaler
    - persistentvolume
    - persistentvolumeclaim
    - endpoint
    - mutatingwebhookconfiguration
    - validatingwebhookconfiguration
    - lease
    - storageclass
    - secret
    - service
    - resourcequota
    - node
    - namespace
{{- end }}

{{- /* metricstransform/ldm: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.metricstransformLdm" -}}
metricstransform/ldm:
  transforms:
    - include: .*
      match_type: regexp
      action: update
      operations:
        - action: add_label
          new_label: low.data.mode
          new_value: 'false'
{{- end }}

{{- /* metricstransform/k8s_cluster_info: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.metricstransformK8sClusterInfo" -}}
metricstransform/k8s_cluster_info:
  transforms:
    - include: kubernetes_build_info
      action: update
      new_name: k8s.cluster.info
{{- end }}

{{- /* resource/newrelic: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.resourceNewrelic" -}}
resource/newrelic:
  attributes:
    # We set the cluster name to what the customer specified in the helm chart
    - key: k8s.cluster.name
      action: upsert
      value: {{ include "newrelic.common.cluster" . }}
    - key: "newrelic.chart.version"
      action: upsert
      value: {{ .Chart.Version }}
    - key: newrelic.entity.type
      action: upsert
      value: "k8s"
{{- end }}

{{- /* resource/low_data_mode_inator: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.resourceLowDataModeinator" -}}
resource/low_data_mode_inator:
  attributes:
    - key: http.scheme
      action: delete
    - key: net.host.name
      action: delete
    - key: net.host.port
      action: delete
    - key: url.scheme
      action: delete
    - key: server.address
      action: delete
{{- end }}

{{- /* filter/exclude_metrics_low_data_mode: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.filterExcludeMetricsLdm" -}}
filter/exclude_metrics_low_data_mode:
  metrics:
    metric:
      - 'HasAttrOnDatapoint("low.data.mode", "false")'
{{- end }}

{{- /* resourcedetection/openshift: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.resourcedetectionOpenshift" -}}
resourcedetection/openshift:
  detectors: ["openshift"]
  override: true
{{- end }}

{{- /* transform/extract_runtime: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.transformExtractRuntime" -}}
transform/extract_runtime:
  metric_statements:
    - context: datapoint
      conditions:
        - IsMatch(attributes["container_id"], ".*://.*")
      statements:
        - set(attributes["runtime"], Split(attributes["container_id"], "://")[0])
        - set(attributes["container_id"], Split(attributes["container_id"], "://")[1])
{{- end }}

{{- /* transform/ksm: Shared across daemonset and statefulset (53 lines) */ -}}
{{- define "nrKubernetesOtel.common.processors.transformKsm" -}}
transform/ksm:
  metric_statements:
    - delete_key(resource.attributes, "k8s.node.name")
    - delete_key(resource.attributes, "k8s.namespace.name")
    - delete_key(resource.attributes, "k8s.pod.uid")
    - delete_key(resource.attributes, "k8s.pod.name")
    - delete_key(resource.attributes, "k8s.container.name")
    - delete_key(resource.attributes, "k8s.replicaset.name")
    - delete_key(resource.attributes, "k8s.deployment.name")
    - delete_key(resource.attributes, "k8s.statefulset.name")
    - delete_key(resource.attributes, "k8s.daemonset.name")
    - delete_key(resource.attributes, "k8s.job.name")
    - delete_key(resource.attributes, "k8s.cronjob.name")
    - delete_key(resource.attributes, "k8s.replicationcontroller.name")
    - delete_key(resource.attributes, "k8s.hpa.name")
    - delete_key(resource.attributes, "k8s.resourcequota.name")
    - delete_key(resource.attributes, "k8s.volume.name")
    - set(resource.attributes["k8s.pod.uid"], resource.attributes["uid"])
    - set(resource.attributes["k8s.node.name"], resource.attributes["node"])
    - set(resource.attributes["k8s.namespace.name"], resource.attributes["namespace"])
    - set(resource.attributes["k8s.pod.name"], resource.attributes["pod"])
    - set(resource.attributes["k8s.container.name"], resource.attributes["container"])
    - set(resource.attributes["k8s.replicaset.name"], resource.attributes["replicaset"])
    - set(resource.attributes["k8s.deployment.name"], resource.attributes["deployment"])
    - set(resource.attributes["k8s.statefulset.name"], resource.attributes["statefulset"])
    - set(resource.attributes["k8s.daemonset.name"], resource.attributes["daemonset"])
    - set(resource.attributes["k8s.job.name"], resource.attributes["job_name"])
    - set(resource.attributes["k8s.cronjob.name"], resource.attributes["cronjob"])
    - set(resource.attributes["k8s.replicationcontroller.name"], resource.attributes["replicationcontroller"])
    - set(resource.attributes["k8s.hpa.name"], resource.attributes["horizontalpodautoscaler"])
    - set(resource.attributes["k8s.resourcequota.name"], resource.attributes["resourcequota"])
    - set(resource.attributes["k8s.volume.name"], resource.attributes["persistentvolume"])
    - set(resource.attributes["k8s.pvc.name"], resource.attributes["persistentvolumeclaim"])
    - delete_key(resource.attributes, "uid")
    - delete_key(resource.attributes, "node")
    - delete_key(resource.attributes, "namespace")
    - delete_key(resource.attributes, "pod")
    - delete_key(resource.attributes, "container")
    - delete_key(resource.attributes, "replicaset")
    - delete_key(resource.attributes, "deployment")
    - delete_key(resource.attributes, "statefulset")
    - delete_key(resource.attributes, "daemonset")
    - delete_key(resource.attributes, "job_name")
    - delete_key(resource.attributes, "cronjob")
    - delete_key(resource.attributes, "replicationcontroller")
    - delete_key(resource.attributes, "horizontalpodautoscaler")
    - delete_key(resource.attributes, "resourcequota")
    - delete_key(resource.attributes, "persistentvolume")
    - delete_key(resource.attributes, "persistentvolumeclaim")
{{- end }}

{{- /* transform/low_data_mode_inator: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.transformLowDataModeinator" -}}
transform/low_data_mode_inator:
  metric_statements:
    - context: metric
      statements:
        - set(metric.description, "")
        - set(metric.unit, "")
    - context: datapoint
      statements:
        - delete_key(datapoint.attributes, "id")
        - delete_key(datapoint.attributes, "name")
        - delete_key(datapoint.attributes, "interface")
        - delete_key(datapoint.attributes, "cpu")
{{- end }}

{{- /* transform/truncate: Shared across daemonset and statefulset - truncate all signal type attributes */ -}}
{{- define "nrKubernetesOtel.common.processors.transformTruncate" -}}
transform/truncate:
  trace_statements:
    - context: span
      statements:
        - truncate_all(span.attributes, 4095)
        - truncate_all(resource.attributes, 4095)
  log_statements:
    - context: log
      statements:
        - truncate_all(log.attributes, 4095)
        - truncate_all(resource.attributes, 4095)
  metric_statements:
    - context: datapoint
      statements:
        - truncate_all(datapoint.attributes, 4095)
        - truncate_all(resource.attributes, 4095)
{{- end }}

{{- /* ========== EXPORTERS ========== */ -}}

{{- /* otlphttp/newrelic: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.exporters.otlphttpNewrelic" -}}
otlphttp/newrelic:
  endpoint: {{ include "nrKubernetesOtel.endpoint" . }}
  headers:
    api-key: ${env:NR_LICENSE_KEY}
{{- end }}

{{- /* ========== CONNECTORS ========== */ -}}

{{- /* routing/nr_logs_pipelines: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.connectors.routingLogsPipelines" -}}
routing/nr_logs_pipelines:
  default_pipelines: [logs/pipeline]
  table:
    - context: log
      condition: "true"
      pipelines: [logs/pipeline]
{{- end }}

{{- /* routing/logs_egress: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.connectors.routingLogsEgress" -}}
routing/logs_egress:
  default_pipelines: [logs/egress]
  table:
    - context: log
      condition: "true"
      pipelines: [logs/egress]
{{- end }}

{{- /* routing/metrics_egress: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.connectors.routingMetricsEgress" -}}
routing/metrics_egress:
  default_pipelines: [metrics/egress]
  table:
    - context: metric
      condition: "true"
      pipelines: [metrics/egress]
{{- end }}

{{- /* resourcedetection/cloudproviders: Shared across daemonset and statefulset */ -}}
{{- define "nrKubernetesOtel.common.processors.resourcedetectionCloudproviders" -}}
resourcedetection/cloudproviders:
  detectors: [gcp, eks, ec2, aks, azure]
  timeout: 2s
  override: false
{{- end }}

{{- /* ========== SERVICE TELEMETRY ========== */ -}}

{{- /* service.telemetry: Shared service telemetry configuration for all collector types */ -}}
{{- /* Configures verbose logging (debug level) and collector metrics (prometheus port 8888) */ -}}
{{- define "nrKubernetesOtel.common.service.telemetry" -}}
{{- if include "newrelic.common.verboseLog" . }}
telemetry:
  logs:
    level: "debug"
  {{- if (((.Values.receivers).collectorMetrics).enabled) }}
  metrics:
    readers:
      - pull:
          exporter:
            prometheus:
              host: '0.0.0.0'
              port: 8888
  {{- end -}}
{{- end -}}
{{- end }}
