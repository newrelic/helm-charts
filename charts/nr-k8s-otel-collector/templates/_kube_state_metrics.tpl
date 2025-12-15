{{- /*
  KUBE-STATE-METRICS PROMETHEUS SCRAPE JOB

  This file contains the complete kube-state-metrics collection flow:
  1. Prometheus scrape job definition (KSM endpoint)
  2. Related processors (KSM-specific metric transformations and filters)
  3. Pipeline routing instructions

  Organization:
1. RECEIVER - kube-state-metrics scrape job config
2. PROCESSORS - all KSM-specific transforms and filters
3. ROUTING - how KSM metrics flow through pipelines

  Usage:
In statefulset.yaml prometheus scrape_configs:
  {{- include "nrKubernetesOtel.receivers.kubeStateMetrics.statefulset.job" . | nindent 12 }}

In statefulset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.kubeStateMetrics.processors" . | nindent 6 }}

In statefulset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.kubeStateMetrics.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITION ========== */ -}}

{{- /* kubeStateMetrics.statefulset.job: Kubernetes object state metrics from kube-state-metrics */ -}}
{{- define "nrKubernetesOtel.receivers.kubeStateMetrics.statefulset.job" -}}
- job_name: kube-state-metrics
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - action: keep
      regex: {{ include "nrKubernetesOtel.receivers.prometheus.ksmSelector.labelValue" . }}
      source_labels:
        - __meta_kubernetes_pod_label_{{ include "nrKubernetesOtel.receivers.prometheus.ksmSelector.labelKey" . }}
{{- if include "newrelic.common.openShift" . }}
    - action: keep
      source_labels:
        - __address__
      regex: .*:8080$
{{- end }}
    - action: replace
      target_label: job_label
      replacement: kube-state-metrics
{{- end }}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* kubeStateMetrics.processors: All KSM-specific transforms and filters */ -}}
{{- define "nrKubernetesOtel.receivers.kubeStateMetrics.processors" -}}
# KSM pod container status phase unification
# Converts individual status metrics into a single phase metric
metricstransform/kube_pod_container_status_phase:
  transforms:
    - include: 'kube_pod_container_status_waiting'
      match_type: strict
      action: update
      new_name: 'kube_pod_container_status_phase'
      operations:
        - action: add_label
          new_label: container_phase
          new_value: waiting
    - include: 'kube_pod_container_status_running'
      match_type: strict
      action: update
      new_name: 'kube_pod_container_status_phase'
      operations:
        - action: add_label
          new_label: container_phase
          new_value: running
    - include: 'kube_pod_container_status_terminated'
      match_type: strict
      action: update
      new_name: 'kube_pod_container_status_phase'
      operations:
        - action: add_label
          new_label: container_phase
          new_value: terminated

# KSM cluster info low data mode tagging
metricstransform/k8s_cluster_info_ldm:
  transforms:
    - include: k8s.cluster.info
      action: update
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'

# KSM pod container status timestamp conversion
transform/convert_timestamp:
  metric_statements:
    - context: datapoint
      conditions:
        - IsMatch(metric.name, "kube_pod_container_status_last_terminated_timestamp")
      statements:
        - set(datapoint.attributes["kube_pod_container_status_last_terminated_timestamp_formatted"], FormatTime(Unix(Int(datapoint.value_double)), "%Y-%m-%dT%H:%M:%SZ"))

# KSM metrics low data mode tagging
# Tags all KSM object metrics as low.data.mode=true for conditional filtering
metricstransform/ksm:
  transforms:
    - include: kube_cronjob_(created|spec_suspend|status_(active|last_schedule_time))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_daemonset_(created|status_(current_number_scheduled|desired_number_scheduled|updated_number_scheduled)|status_number_(available|misscheduled|ready|unavailable))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_deployment_(created|metadata_generation|spec_(replicas|strategy_rollingupdate_max_surge)|status_(condition|observed_generation|replicas)|status_replicas_(available|ready|unavailable|updated)|labels|annotations)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_horizontalpodautoscaler_(spec_(max_replicas|min_replicas)|status_(condition|current_replicas|desired_replicas))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_job_(owner|complete|created|failed|spec_(active_deadline_seconds|completions|parallelism)|status_(active|completion_time|failed|start_time|succeeded))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_node_status_(allocatable|capacity|condition)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: ^kube_namespace_(labels|annotations|status_phase|created)$$
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_persistentvolume_(capacity_bytes|created|info|status_phase)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_persistentvolumeclaim_(created|info|resource_requests_storage_bytes|status_phase|access_mode)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_pod_container_(info|resource_(limits|requests)|status_(phase|ready|restarts_total|waiting_reason|last_terminated_timestamp|last_terminated_exitcode|last_terminated_reason))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: ^kube_pod_(owner|created|info|status_(phase|ready|scheduled)|start_time|deletion_timestamp|labels|annotations)$$
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: ^kube_service_(annotations|created|info|labels|spec_type|status_load_balancer_ingress)$$
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_statefulset_(created|persistentvolumeclaim_retention_policy|replicas|status_(current_revision|replicas)|status_replicas_(available|current|ready|updated))
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
    - include: kube_(replicaset_owner)
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
{{- if (index .Values "kube-state-metrics").enableResourceQuotaSamples }}
    - include: ^kube_resourcequota(_created)?$$
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
{{- end -}}

# KSM zero-value filtering for condition and status metrics
filter/exclude_zero_value_kube_node_status_condition:
  metrics:
    datapoint:
      - metric.name == "kube_node_status_condition" and value_double == 0.0

filter/exclude_zero_value_kube_persistentvolumeclaim_status_phase:
  metrics:
    datapoint:
      - metric.name == "kube_persistentvolumeclaim_status_phase" and value_double == 0.0

filter/nr_exclude_zero_value_kube_pod_container_deployment_statuses:
  metrics:
    datapoint:
      - metric.name == "kube_pod_status_phase" and value_double < 0.5
      - metric.name == "kube_pod_status_ready" and value_double < 0.5
      - metric.name == "kube_pod_status_scheduled" and value_double < 0.5
      - metric.name == "kube_pod_container_status_ready" and value_double < 0.5
      - metric.name == "kube_pod_container_status_phase" and value_double < 0.5
      - metric.name == "kube_pod_container_status_restarts_total" and value_double < 0.5
      - metric.name == "kube_deployment_status_condition" and value_double < 0.5
      - metric.name == "kube_pod_container_status_waiting_reason" and value_double < 0.5

filter/nr_exclude_zero_value_kube_jobs:
  metrics:
    datapoint:
      - metric.name == "kube_job_complete" and value_double < 0.5
      - metric.name == "kube_job_spec_parallelism" and value_double < 0.5
      - metric.name == "kube_job_status_failed" and value_double < 0.5
      - metric.name == "kube_job_status_active" and value_double < 0.5
      - metric.name == "kube_job_status_succeeded" and value_double < 0.5

# KSM datapoint volume name mapping (statefulset-specific)
# Maps volumename attribute to k8s.volume.name for KSM metrics
transform/ksm_datapoints:
  metric_statements:
    - set(resource.attributes["k8s.volume.name"], datapoint.attributes["volumename"])
    - delete_key(datapoint.attributes, "volumename")

# KSM attributes extraction for cluster-wide collection (statefulset-specific)
# Extracts K8s resource metadata for KSM metrics without node filtering
k8sattributes/ksm:
  auth_type: "serviceAccount"
  passthrough: false
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

