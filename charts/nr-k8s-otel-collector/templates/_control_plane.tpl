{{- /*
  KUBERNETES CONTROL PLANE PROMETHEUS SCRAPE JOBS

  This file contains the complete control plane metrics collection flow:
  1. Prometheus scrape job definitions (apiserver, controller-manager, scheduler)
  2. Related processors (control plane-specific metric transformations)
  3. Pipeline routing instructions

  Organization:
1. RECEIVERS - control plane scrape job configs (apiserver, controller-manager, scheduler)
2. PROCESSORS - all control plane-specific transforms
3. ROUTING - how control plane metrics flow through pipelines

  Usage:
In statefulset.yaml prometheus scrape_configs:
  {{- include "nrKubernetesOtel.receivers.controlPlane.statefulset.jobs" . | nindent 12 }}

In statefulset.yaml processors section:
  {{- include "nrKubernetesOtel.receivers.controlPlane.processors" . | nindent 6 }}

In statefulset.yaml connectors section:
  {{- include "nrKubernetesOtel.receivers.controlPlane.routing" . | nindent 6 }}
*/ -}}

{{- /* ========== RECEIVER DEFINITIONS ========== */ -}}

{{- /* controlPlane.statefulset.jobs: All control plane scrape jobs (apiserver, controller-manager, scheduler) */ -}}
{{- define "nrKubernetesOtel.receivers.controlPlane.statefulset.jobs" -}}
- job_name: apiserver
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  kubernetes_sd_configs:
    - role: endpoints
      namespaces:
        names:
          - default
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: {{if include "newrelic.common.openShift" . }}true{{ else }}false{{ end }}
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
    - action: keep
      source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
      regex: default;kubernetes;https
    - action: replace
      source_labels:
        - __meta_kubernetes_namespace
      target_label: namespace
    - action: replace
      source_labels:
        - __meta_kubernetes_service_name
      target_label: service
    - action: replace
      target_label: job_label
      replacement: apiserver

- job_name: controller-manager
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  metrics_path: /metrics
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
{{- if include "newrelic.common.openShift" . }}
          - openshift-kube-controller-manager
{{- else }}
          - kube-system
{{- end }}
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
{{- if include "newrelic.common.openShift" . }}
    insecure_skip_verify: true
{{- else }}
    insecure_skip_verify: false
{{- end }}
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
    - action: keep
      source_labels:
        - __meta_kubernetes_pod_name
        - __address__
      regex: .*controller-manager.*;.*:10257$
    - action: replace
      source_labels:
        - __meta_kubernetes_pod_name
      target_label: namespace
    - action: replace
      source_labels:
        - __meta_kubernetes_pod_name
      target_label: pod
    - action: replace
      source_labels:
        - __meta_kubernetes_service_name
      target_label: service
    - action: replace
      target_label: job_label
      replacement: controller-manager

- job_name: scheduler
  scrape_interval: {{ .Values.receivers.prometheus.scrapeInterval }}
  metrics_path: /metrics
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
{{- if include "newrelic.common.openShift" . }}
          - openshift-kube-scheduler
{{- else }}
          - kube-system
{{- end }}
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
{{- if include "newrelic.common.openShift" . }}
    insecure_skip_verify: true
{{- else }}
    insecure_skip_verify: false
{{- end }}
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
    - action: keep
      source_labels:
        - __meta_kubernetes_pod_name
        - __address__
      regex: .*scheduler.*;.*:10259$
    - action: replace
      source_labels:
        - __meta_kubernetes_namespace
      target_label: namespace
    - action: replace
      source_labels:
        - __meta_kubernetes_pod_name
      target_label: pod
    - action: replace
      source_labels:
        - __meta_kubernetes_service_name
      target_label: service
    - action: replace
      target_label: job_label
      replacement: scheduler
{{- end }}

{{- /* ========== PROCESSORS ========== */ -}}

{{- /* controlPlane.processors: All control plane-specific transforms and filters */ -}}
{{- define "nrKubernetesOtel.receivers.controlPlane.processors" -}}
# Control plane metrics low data mode tagging
# Tags process and cluster metrics from apiserver, controller-manager, scheduler
metricstransform/controlPlane:
  transforms:
    - include: apiserver_storage_objects
      action: update
      match_type: regexp
      operations:
        - action: update_label
          label: low.data.mode
          value_actions:
            - value: 'false'
              new_value: 'true'
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

# Attribute mapping for control plane metrics (statefulset-specific)
# Maps common attributes to standard K8s resource attributes
# Used exclusively in metrics/nr_controlplane pipeline
attributes/self:
  actions:
    - key: k8s.node.name
      action: upsert
      from_attribute: node
    - key: k8s.namespace.name
      action: upsert
      from_attribute: namespace
    - key: k8s.pod.name
      action: upsert
      from_attribute: pod
    - key: k8s.container.name
      action: upsert
      from_attribute: container
    - key: k8s.replicaset.name
      action: upsert
      from_attribute: replicaset
    - key: k8s.deployment.name
      action: upsert
      from_attribute: deployment
    - key: k8s.statefulset.name
      action: upsert
      from_attribute: statefulset
    - key: k8s.daemonset.name
      action: upsert
      from_attribute: daemonset
    - key: k8s.job.name
      action: upsert
      from_attribute: job_name
    - key: k8s.cronjob.name
      action: upsert
      from_attribute: cronjob
    - key: k8s.replicationcontroller.name
      action: upsert
      from_attribute: replicationcontroller
    - key: k8s.hpa.name
      action: upsert
      from_attribute: horizontalpodautoscaler
    - key: k8s.resourcequota.name
      action: upsert
      from_attribute: resourcequota
    - key: k8s.volume.name
      action: upsert
      from_attribute: volumename
    - key: k8s.pvc.name
      action: upsert
      from_attribute: persistentvolumeclaim
    # Clean up temporary attributes
    - key: node
      action: delete
    - key: namespace
      action: delete
    - key: pod
      action: delete
    - key: container
      action: delete
    - key: replicaset
      action: delete
    - key: deployment
      action: delete
    - key: statefulset
      action: delete
    - key: daemonset
      action: delete
    - key: job_name
      action: delete
    - key: cronjob
      action: delete
    - key: replicationcontroller
      action: delete
    - key: horizontalpodautoscaler
      action: delete
    - key: resourcequota
      action: delete
    - key: volumename
      action: delete
    - key: persistentvolume
      action: delete
    - key: persistentvolumeclaim
      action: delete
{{- end }}
