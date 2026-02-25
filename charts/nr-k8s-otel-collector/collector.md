# Bring Your Own OpenTelemetry Collector

This guide provides everything you need to configure your own OpenTelemetry Collector to send metrics, logs, and events to New Relic, instead of using the nr-k8s-otel-collector Helm chart.

## Overview

You can deploy the OpenTelemetry Collector in two primary patterns:

1. **DaemonSet** - Runs on every node, collects node-level and pod-level metrics
2. **Deployment** - Runs as a central collector, typically for cluster-wide metrics (KSM, API server, control plane)

In most production environments, you'll use both patterns together.

## Quick Start

### Prerequisites

- OpenTelemetry Collector
- Service Account with appropriate RBAC permissions to read pod/node metrics
- New Relic License Key for authentication

---

## DaemonSet Deployment Pattern

A DaemonSet collector runs on **every node** and collects node-local metrics.

### What Does It Collect?

- **Host-level metrics** - CPU, memory, disk, filesystem, network (via HostMetrics receiver)
- **Container metrics** - From the local kubelet (via KubeletStats and cAdvisor receivers)
- **Pod logs** - From local `/var/log/pods` filesystem (via Filelog receiver)

### Setup Requirements

1. **Mount host filesystem** - Add volume mount for `/hostfs` to read host metrics
2. **Set KUBE_NODE_NAME environment variable** - Use downward API to identify the node
3. **Node-local scraping** - Only scrape metrics from the node the DaemonSet pod is running on

### Node Metrics Calculation (CPU & Memory Percentages)

To calculate node CPU and memory usage **as a percentage of allocatable resources**, you need to query the Kubernetes API for node allocatable values. The recommended approach is to use an **init container** that fetches these values and injects them into the collector configuration.

#### Why This Matters

- **`node.cpu.usage.percentage`** = (node.cpu.usage / node CPU allocatable) × 100
- **`node.memory.usage.percentage`** = (node.memory.usage / node memory allocatable) × 100

Without the allocatable values, you can't calculate meaningful percentage metrics.

#### Init Container Approach (Recommended)

An init container handles the dynamic calculation by:

1. Retrieving node CPU and memory allocatable from the Kubernetes API
2. Injecting these values into the collector configuration via `yq`
3. Writing the final config to a shared volume for the main container

**See the complete working example in:**

- [init container get-cpu-allocatable](examples/k8s/rendered/daemonset.yaml#L30-L79)

The init container workflow:

1. Reads base collector config from ConfigMap
2. Queries node allocatable CPU (converts milliCPU to CPU if needed)
3. Queries node allocatable memory (converts to bytes)
4. Uses `yq` to inject these values into the `metricsgeneration/calculate_percentage` processor
5. Writes modified config to shared `emptyDir` volume
6. Main container starts with the finalized configuration

### Full DaemonSet Configuration

> **Before using this configuration**, replace the following placeholder values in the `resource/newrelic` processor:
>
> - `k8s.cluster.name` — Replace `my-cluster` with your actual cluster name
> - `newrelic.chart.version` — Replace `<CHART_VERSION>` with the latest [nr-k8s-otel-collector chart version](https://github.com/newrelic/helm-charts/blob/master/charts/nr-k8s-otel-collector/Chart.yaml#L20)

```yaml
receivers:
  # Host-level system metrics (Linux-specific)
  hostmetrics:
    root_path: /hostfs
    collection_interval: 1m
    scrapers:
      cpu:
        metrics:
          system.cpu.time:
            enabled: false
          system.cpu.utilization:
            enabled: true
          system.cpu.logical.count:
            enabled: true
      load: {}
      memory:
        metrics:
          system.memory.utilization:
            enabled: true
      paging:
        metrics:
          system.paging.utilization:
            enabled: false
          system.paging.faults:
            enabled: false
      filesystem:
        metrics:
          system.filesystem.utilization:
            enabled: true
      disk:
        metrics:
          system.disk.merged:
            enabled: false
          system.disk.pending_operations:
            enabled: false
          system.disk.weighted_io_time:
            enabled: false
      network:
        metrics:
          system.network.connections:
            enabled: false

  # Kubelet metrics from the local node
  kubeletstats:
    collection_interval: 1m
    endpoint: "${KUBE_NODE_NAME}:10250"
    auth_type: "serviceAccount"
    insecure_skip_verify: true
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

  # cAdvisor and Kubelet metrics via Kubernetes API proxy
  prometheus:
    config:
      scrape_configs:
        # cAdvisor metrics (container-level metrics from kubelet)
        - job_name: cadvisor
          scrape_interval: 1m
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
            # Only scrape this node
            - source_labels: [__meta_kubernetes_node_name]
              regex: ${KUBE_NODE_NAME}
              action: keep
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: false
            server_name: kubernetes

        # Kubelet metrics
        - job_name: kubelet
          scrape_interval: 1m
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
            # Only scrape this node
            - source_labels: [__meta_kubernetes_node_name]
              regex: ${KUBE_NODE_NAME}
              action: keep
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: false
            server_name: kubernetes

  # Pod logs from local node filesystem
  filelog:
    include:
      - /var/log/pods/*/*/*.log
    exclude:
      # Exclude logs from the collector itself
      - /var/log/pods/*/otel-collector-daemonset/*.log
      - /var/log/pods/*/otel-collector-deployment/*.log
      - /var/log/pods/*/containers/*-exec.log
      # GKE specific (uses containerd)
      - /var/log/pods/*/konnectivity-agent/*.log
      # Docker CRI
      - /var/log/container/otel-collector-daemonset/*.log
      - /var/log/container/otel-collector-deployment/*.log
      - /var/log/containers/*-exec.log
    include_file_path: true
    include_file_name: true
    operators:
      - id: container-parser
        type: container

processors:
  # Normalize attributes by K8s standard names
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

  # Map discovered attributes to standard K8s names
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
      - set(resource.attributes["k8s.volume.name"], resource.attributes["volumename"])
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
      - delete_key(resource.attributes, "volumename")
      - delete_key(resource.attributes, "persistentvolume")
      - delete_key(resource.attributes, "persistentvolumeclaim")

  # Extract container runtime from container ID
  transform/extract_runtime:
    metric_statements:
      - context: datapoint
        conditions:
          - IsMatch(attributes["container_id"], ".*://.*")
        statements:
          - set(attributes["runtime"], Split(attributes["container_id"], "://")[0])
          - set(attributes["container_id"], Split(attributes["container_id"], "://")[1])

  # Mark all metrics for low data mode (then selectively unmark)
  metricstransform/ldm:
    transforms:
      - include: .*
        match_type: regexp
        action: update
        operations:
          - action: add_label
            new_label: low.data.mode
            new_value: 'false'

  # Low data mode transforms for kubeletstats
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

  # Mark collector's own metrics for low data mode
  transform/collector:
    metric_statements:
      - set(datapoint.attributes["low.data.mode"], "true") where datapoint.attributes["job_label"] == "otel-collector-daemonset"

  # Rename kubernetes_build_info to k8s.cluster.info
  metricstransform/k8s_cluster_info:
    transforms:
      - include: kubernetes_build_info
        action: update
        new_name: k8s.cluster.info

  # Low data mode transforms for cAdvisor
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

  # Low data mode transforms for kubelet metrics
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

  # Low data mode transforms for hostmetrics
  metricstransform/hostmetrics:
    transforms:
      - include: process\.(cpu\.utilization|disk\.io|memory\.(usage|virtual))
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'
      - include: system\.cpu\.(utilization|load_average\.(15m|1m|5m))
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'
      - include: system\.disk\.(io_time|operation_time|operations)
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'
      - include: system\.(filesystem|memory)\.(usage|utilization)
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'
      - include: system\.network\.(errors|io|packets)
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'

  # Calculate additional metrics from kubelet stats
  metricsgeneration/calculate_percentage:
    rules:
      # Memory: request/limit ratio
      - name: k8s.pod.memory_request_limit_ratio
        type: calculate
        metric1: k8s.pod.memory_limit_utilization
        metric2: k8s.pod.memory_request_utilization
        operation: divide
      # CPU: request/limit ratio
      - name: k8s.pod.cpu_request_limit_ratio
        type: calculate
        metric1: k8s.pod.cpu_limit_utilization
        metric2: k8s.pod.cpu_request_utilization
        operation: divide
      # Node CPU usage as percentage
      - name: node.cpu.usage.percentage
        type: scale
        metric1: k8s.node.cpu.usage
        scale_by: <NODE_CPU_ALLOCATABLE_PLACEHOLDER>
        operation: divide
      # Node memory usage as percentage
      - name: node.memory.usage.percentage
        type: scale
        metric1: k8s.node.memory.working_set
        scale_by: <NODE_MEMORY_ALLOCATABLE_PLACEHOLDER>
        operation: divide

  # Mark generated metrics for low data mode
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

  # Filter out low data mode metrics
  filter/exclude_metrics_low_data_mode:
    metrics:
      metric:
        - 'HasAttrOnDatapoint("low.data.mode", "false")'

  # Truncate long attribute values in logs
  transform/truncate:
    log_statements:
      - context: log
        statements:
          - truncate_all(log.attributes, 4095)
          - truncate_all(resource.attributes, 4095)

  # Group CPU metrics by state
  metricstransform/hostmetrics_cpu:
    transforms:
      - include: system.cpu.utilization
        action: update
        operations:
          - action: aggregate_labels
            label_set: [state]
            aggregation_type: mean
      - include: system.paging.operations
        action: update
        operations:
          - action: aggregate_labels
            label_set: [direction]
            aggregation_type: sum

  # Filesystem filters: exclude squashfs and reserved space
  filter/exclude_filesystem_utilization:
    metrics:
      datapoint:
        - 'metric.name == "system.filesystem.utilization" and attributes["type"] == "squashfs"'
  filter/exclude_filesystem_usage:
    metrics:
      datapoint:
        - 'metric.name == "system.filesystem.usage" and attributes["type"] == "squashfs"'
        - 'metric.name == "system.filesystem.usage" and attributes["state"] == "reserved"'
  filter/exclude_filesystem_inodes_usage:
    metrics:
      datapoint:
        - 'metric.name == "system.filesystem.inodes.usage" and attributes["type"] == "squashfs"'
        - 'metric.name == "system.filesystem.inodes.usage" and attributes["state"] == "reserved"'

  # Disk filters: exclude loop devices
  filter/exclude_system_disk:
    metrics:
      datapoint:
        - 'metric.name == "system.disk.operations" and IsMatch(attributes["device"], "^loop.*") == true'
        - 'metric.name == "system.disk.merged" and IsMatch(attributes["device"], "^loop.*") == true'
        - 'metric.name == "system.disk.io" and IsMatch(attributes["device"], "^loop.*") == true'
        - 'metric.name == "system.disk.io_time" and IsMatch(attributes["device"], "^loop.*") == true'
        - 'metric.name == "system.disk.operation_time" and IsMatch(attributes["device"], "^loop.*") == true'

  # Paging filters: exclude cached pages
  filter/exclude_system_paging:
    metrics:
      datapoint:
        - 'metric.name == "system.paging.usage" and attributes["state"] == "cached"'
        - 'metric.name == "system.paging.operations" and attributes["type"] == "cached"'

  # Network filters: exclude loopback
  filter/exclude_network:
    metrics:
      datapoint:
        - 'IsMatch(metric.name, "^system.network.*") == true and attributes["device"] == "lo"'

  # Container network filters: exclude zero values (spurious metrics)
  filter/nr_exclude_container_zero_values:
    metrics:
      datapoint:
        - metric.name == "container_network_receive_errors_total" and value_double < 0.5
        - metric.name == "container_network_transmit_errors_total" and value_double < 0.5
        - metric.name == "container_network_transmit_bytes_total" and value_double < 0.5
        - metric.name == "container_network_receive_bytes_total" and value_double < 0.5

  # Remove type attribute from paging operations
  attributes/exclude_system_paging:
    include:
      match_type: strict
      metric_names:
        - system.paging.operations
    actions:
      - key: type
        action: delete

  # Detect environment and system attributes
  resourcedetection/env:
    detectors: ["env", "system"]
    override: false
    system:
      hostname_sources: ["os"]
      resource_attributes:
        host.name:
          enabled: false

  # Detect cloud provider attributes
  resourcedetection/cloudproviders:
    detectors: [gcp, eks, ec2, aks, azure, oraclecloud]
    timeout: 2s
    override: false
    eks:
      node_from_env_var: KUBE_NODE_NAME

  # Add New Relic specific attributes
  resource/newrelic:
    attributes:
      - key: k8s.cluster.name
        action: upsert
        value: my-cluster
      - key: "newrelic.chart.version"
        action: upsert
        value: "<CHART_VERSION>"
      - key: newrelic.entity.type
        action: upsert
        value: "k8s"

  # Clean up low data mode attributes
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

  # K8s metadata enrichment for local pods
  k8sattributes/ksm:
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

  # Cumulative to delta conversion
  cumulativetodelta: {}

  # Memory and batch processors
  memory_limiter:
    check_interval: 1s
    limit_percentage: 80
    spike_limit_percentage: 25

  batch:
    send_batch_max_size: 1000
    timeout: 30s
    send_batch_size: 800

exporters:
  otlphttp/newrelic:
    endpoint: "https://otlp.nr-data.net"
    headers:
      api-key: ${env:NR_LICENSE_KEY}

service:
  pipelines:
    # Host metrics pipeline
    metrics/hostmetrics:
      receivers:
        - hostmetrics
      processors:
        - memory_limiter
        - metricstransform/k8s_cluster_info
        - metricstransform/ldm
        - transform/tag_generated_metrics_ldm
        - metricstransform/hostmetrics
        - filter/exclude_metrics_low_data_mode
        - metricstransform/hostmetrics_cpu
        - transform/truncate
        - filter/exclude_filesystem_utilization
        - filter/exclude_filesystem_usage
        - filter/exclude_filesystem_inodes_usage
        - filter/exclude_system_disk
        - filter/exclude_system_paging
        - filter/exclude_network
        - attributes/exclude_system_paging
        - resourcedetection/env
        - resourcedetection/cloudproviders
        - resource/newrelic
        - transform/low_data_mode_inator
        - resource/low_data_mode_inator
        - k8sattributes/ksm
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Kubelet stats metrics pipeline
    metrics/kubeletstats:
      receivers:
        - kubeletstats
      processors:
        - memory_limiter
        - metricsgeneration/calculate_percentage
        - metricstransform/k8s_cluster_info
        - metricstransform/ldm
        - transform/tag_generated_metrics_ldm
        - metricstransform/kubeletstats
        - filter/exclude_metrics_low_data_mode
        - transform/truncate
        - resourcedetection/env
        - resourcedetection/cloudproviders
        - resource/newrelic
        - transform/low_data_mode_inator
        - resource/low_data_mode_inator
        - k8sattributes/ksm
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Prometheus metrics pipeline (cAdvisor + Kubelet)
    metrics/prometheus:
      receivers:
        - prometheus
      processors:
        - memory_limiter
        - metricstransform/k8s_cluster_info
        - metricstransform/ldm
        - metricstransform/cadvisor
        - metricstransform/kubelet
        - transform/collector
        - filter/exclude_metrics_low_data_mode
        - filter/nr_exclude_container_zero_values
        - transform/truncate
        - resourcedetection/env
        - resourcedetection/cloudproviders
        - resource/newrelic
        - transform/low_data_mode_inator
        - resource/low_data_mode_inator
        - groupbyattrs
        - transform/ksm
        - k8sattributes/ksm
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Pod logs pipeline
    logs:
      receivers:
        - filelog
      processors:
        - memory_limiter
        - transform/truncate
        - resource/newrelic
        - k8sattributes/ksm
        - batch
      exporters:
        - otlphttp/newrelic
```

### Deploying the DaemonSet

#### Step 1: Create DaemonSet ConfigMap

The collector reads its configuration from a ConfigMap. If you already have a collector ConfigMap, incorporate the relevant receivers, processors, exporters, and pipelines from the [Full DaemonSet Configuration](#full-daemonset-configuration) into your existing config.

If you're starting fresh, create a new ConfigMap:

```bash
cat > daemonset-configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-daemonset-config
  namespace: newrelic
data:
  daemonset-config.yaml: |
    # Paste the Full DaemonSet Configuration from above
    # (receivers, processors, exporters, service sections)
EOF

kubectl apply -f daemonset-configmap.yaml
```

#### Step 2: Deploy the DaemonSet

Ensure your DaemonSet manifest includes:

1. **Init container** — Fetches node CPU/memory allocatable values and injects them into the collector config (see the [Init Container Approach](#init-container-approach-recommended) section). Without this, `node.cpu.usage.percentage` and `node.memory.usage.percentage` metrics won't be calculated.

2. **Environment variables:**
   - `KUBE_NODE_NAME` via the downward API (`spec.nodeName`) — used by kubelet and Prometheus receivers to scrape only the local node
   - `NR_LICENSE_KEY` from a Kubernetes Secret — used by the OTLP exporter for authentication
   - `HOST_IP` via the downward API (`status.hostIP`)
   - `POD_NAME` via the downward API (`metadata.name`)
   - `POD_UID` via the downward API (`metadata.uid`)
   - `OTEL_RESOURCE_ATTRIBUTES` set to `service.instance.id=$(POD_NAME),k8s.pod.uid=$(POD_UID)` — identifies the collector instance

3. **Volume mounts:**
   - `/hostfs` (read-only) — host root filesystem, needed by the `hostmetrics` receiver
   - `/var/log/pods` (read-only) — pod log files, needed by the `filelog` receiver
   - A shared `emptyDir` volume between the init container and main container for the finalized config

4. **Config mount** — The main container should read the collector config from the shared volume written by the init container (not directly from the ConfigMap)

5. **ServiceAccount** — Must reference a ServiceAccount with the [RBAC permissions](#rbac-requirements) defined below

For a complete working example, see [examples/k8s/rendered/daemonset.yaml](examples/k8s/rendered/daemonset.yaml).

---

## Deployment Pattern

A Deployment collector runs as a **central service** and collects cluster-wide metrics that don't need to run on every node.

### What Does It Collect?

- **Kube-State-Metrics (KSM)** - State of Kubernetes objects (pods, deployments, etc.)
- **Control Plane metrics** - From API Server, Scheduler, Controller Manager
- **OTLP receivers** - For applications sending data directly to the collector
- **Kubernetes events** - Cluster-wide events

### Full Deployment Configuration

> **Before using this configuration**, replace the following placeholder values in the `resource/newrelic` and `resource/events` processors:
>
> - `k8s.cluster.name` — Replace `my-cluster` with your actual cluster name
> - `newrelic.chart.version` — Replace `<CHART_VERSION>` with the latest [nr-k8s-otel-collector chart version](https://github.com/newrelic/helm-charts/blob/master/charts/nr-k8s-otel-collector/Chart.yaml#L20)

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: ${env:MY_POD_IP}:4318
      grpc:
        endpoint: ${env:MY_POD_IP}:4317

  k8s_events: {}

  prometheus/ksm:
    config:
      scrape_configs:
        - job_name: kube-state-metrics
          scrape_interval: 1m
          kubernetes_sd_configs:
            - role: pod
          relabel_configs:
            - action: keep
              regex: kube-state-metrics
              source_labels:
                - __meta_kubernetes_pod_label_app_kubernetes_io_name
            - action: replace
              target_label: job_label
              replacement: kube-state-metrics

  prometheus/controlplane:
    config:
      scrape_configs:
        - job_name: apiserver
          scrape_interval: 1m
          kubernetes_sd_configs:
            - role: endpoints
              namespaces:
                names:
                  - default
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: false
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

        # if not running on openshift, this only works if controller-manager port 10257 is exposed in the pod
        - job_name: controller-manager
          scrape_interval: 1m
          metrics_path: /metrics
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - kube-system
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: false
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          relabel_configs:
            - action: keep
              source_labels:
                - __meta_kubernetes_pod_name
                - __address__
              regex: .*controller-manager.*;.*:10257$
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
              replacement: controller-manager

        # if not running on openshift, this only works if scheduler port 10259 is exposed in the pod
        - job_name: scheduler
          scrape_interval: 1m
          metrics_path: /metrics
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - kube-system
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: false
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

processors:
  # Extract container runtime from container ID
  # (e.g., docker://abc123 → runtime: docker, container_id: abc123)
  transform/extract_runtime:
    metric_statements:
      - context: datapoint
        conditions:
          - IsMatch(attributes["container_id"], ".*://.*")
        statements:
          - set(attributes["runtime"], Split(attributes["container_id"], "://")[0])
          - set(attributes["container_id"], Split(attributes["container_id"], "://")[1])

  # Normalize attributes by K8s standard names
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

  # KSM-specific transforms
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

  transform/ksm_datapoints:
    metric_statements:
      - set(resource.attributes["k8s.volume.name"], datapoint.attributes["volumename"])
      - delete_key(datapoint.attributes, "volumename")

  # Metric transform processors for specific metrics
  metricstransform/k8s_cluster_info:
    transforms:
      - include: kubernetes_build_info
        action: update
        new_name: k8s.cluster.info

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

  # Low data mode transforms
  metricstransform/ldm:
    transforms:
      - include: .*
        match_type: regexp
        action: update
        operations:
          - action: add_label
            new_label: low.data.mode
            new_value: 'false'

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

  transform/convert_timestamp:
    metric_statements:
      - context: datapoint
        conditions:
          - IsMatch(metric.name, "kube_pod_container_status_last_terminated_timestamp")
        statements:
          - set(datapoint.attributes["kube_pod_container_status_last_terminated_timestamp_formatted"], FormatTime(Unix(Int(datapoint.value_double)), "%Y-%m-%dT%H:%M:%SZ"))

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
      - include: kube_replicaset_(owner|created)
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'
      - include: ^kube_resourcequota(_created)?$
        action: update
        match_type: regexp
        operations:
          - action: update_label
            label: low.data.mode
            value_actions:
              - value: 'false'
                new_value: 'true'

  # Control plane metrics transforms
  metricstransform/apiserver:
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

  # Filter for low data mode
  filter/exclude_metrics_low_data_mode:
    metrics:
      metric:
        - 'HasAttrOnDatapoint("low.data.mode", "false")'

  # Resource attribute processors
  resource/newrelic:
    attributes:
      # Set the cluster name to what you configure in your deployment
      - key: k8s.cluster.name
        action: upsert
        value: my-cluster
      - key: "newrelic.chart.version"
        action: upsert
        value: "<CHART_VERSION>"
      - key: "newrelic.entity.type"
        action: upsert
        value: "k8s"

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
        value: my-cluster
      - key: "newrelic.chart.version"
        action: upsert
        value: "<CHART_VERSION>"

  transform/events:
    log_statements:
      - context: log
        statements:
          - set(log.attributes["event.source.host"], resource.attributes["k8s.node.name"])

  # Low data mode cleanup
  transform/low_data_mode_inator:
    metric_statements:
      - context: metric
        statements:
          - set(metric.description, "")
          - set(metric.unit, "")

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

  # Cumulative to delta conversion
  cumulativetodelta:
    exclude:
      metrics:
        - 'kube_pod_container_status_restarts_total'
      match_type: strict

  # K8s metadata enrichment for KSM
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

  # Attributes for control plane metrics
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
      - key: k8s.volume.name
        action: upsert
        from_attribute: persistentvolume
      - key: k8s.pvc.name
        action: upsert
        from_attribute: persistentvolumeclaim
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

  # Memory and batch processors
  memory_limiter:
    check_interval: 1s
    limit_percentage: 80
    spike_limit_percentage: 25

  batch:
    send_batch_max_size: 1000
    timeout: 30s
    send_batch_size: 800

exporters:
  otlphttp/newrelic:
    endpoint: "https://otlp.nr-data.net"
    headers:
      api-key: ${env:NR_LICENSE_KEY}

service:
  pipelines:
    # Direct pipeline for KSM metrics
    metrics/ksm:
      receivers:
        - prometheus/ksm
      processors:
        - memory_limiter
        - metricstransform/kube_pod_container_status_phase
        - transform/convert_timestamp
        - metricstransform/ldm
        - metricstransform/k8s_cluster_info_ldm
        - metricstransform/ksm
        - filter/exclude_metrics_low_data_mode
        - transform/low_data_mode_inator
        - resource/low_data_mode_inator
        - resource/newrelic
        - groupbyattrs
        - transform/ksm
        - transform/ksm_datapoints
        - k8sattributes/ksm
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Direct pipeline for control plane metrics
    metrics/controlplane:
      receivers:
        - prometheus/controlplane
      processors:
        - memory_limiter
        - metricstransform/k8s_cluster_info
        - metricstransform/ldm
        - metricstransform/k8s_cluster_info_ldm
        - metricstransform/apiserver
        - filter/exclude_metrics_low_data_mode
        - transform/low_data_mode_inator
        - resource/low_data_mode_inator
        - resource/newrelic
        - attributes/self
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Direct pipeline for OTLP metrics (default)
    metrics/default:
      receivers:
        - otlp
      processors:
        - memory_limiter
        - resource/newrelic
        - cumulativetodelta
        - transform/extract_runtime
        - batch
      exporters:
        - otlphttp/newrelic

    # Direct pipeline for K8s events
    logs/events:
      receivers:
        - k8s_events
      processors:
        - memory_limiter
        - transform/events
        - resource/events
        - resource/newrelic
        - batch
      exporters:
        - otlphttp/newrelic
```

### Deploying the Deployment

#### Step 1: Create Deployment ConfigMap

The collector reads its configuration from a ConfigMap. If you already have a collector ConfigMap, incorporate the relevant receivers, processors, exporters, and pipelines from the [Full Deployment Configuration](#full-deployment-configuration) into your existing config.

If you're starting fresh, create a new ConfigMap:

```bash
cat > deployment-configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-deployment-config
  namespace: newrelic
data:
  deployment-config.yaml: |
    # Paste the Full Deployment Configuration from above
    # (receivers, processors, exporters, service sections)
EOF

kubectl apply -f deployment-configmap.yaml
```

#### Step 2: Deploy the Deployment

Ensure your Deployment manifest includes:

1. **Environment variables:**
   - `MY_POD_IP` via the downward API (`status.podIP`) — used by the OTLP receiver endpoints
   - `NR_LICENSE_KEY` from a Kubernetes Secret — used by the OTLP exporter for authentication

2. **Config mount** — Mount the ConfigMap containing your collector configuration

3. **ServiceAccount** — Must reference a ServiceAccount with the [RBAC permissions](#rbac-requirements) defined below

For a complete working example, see [examples/k8s/rendered/deployment.yaml](examples/k8s/rendered/deployment.yaml).

---

## Platform-Specific Configuration

### OpenShift

If you're running on OpenShift, apply the following changes to the base configurations above.

#### 1. Resource Detection (DaemonSet)

Replace `resourcedetection/cloudproviders` with `resourcedetection/openshift` in the DaemonSet processor definitions and pipelines:

```yaml
processors:
  # Replace resourcedetection/cloudproviders with:
  resourcedetection/openshift:
    detectors: ["openshift"]
    override: true
```

Update all DaemonSet pipelines that reference `resourcedetection/cloudproviders` to use `resourcedetection/openshift` instead.

#### 2. API Server TLS (Deployment)

Set `insecure_skip_verify: true` for the apiserver job in the Deployment's `prometheus/controlplane` receiver:

```yaml
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true
```

#### 3. Control Plane Scraping (Deployment)

Update the `prometheus/controlplane` receiver for OpenShift namespaces and TLS:

- **controller-manager**: Change namespace from `kube-system` to `openshift-kube-controller-manager`, set `insecure_skip_verify: true`
- **scheduler**: Change namespace from `kube-system` to `openshift-kube-scheduler`, set `insecure_skip_verify: true`

```yaml
        - job_name: controller-manager
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - openshift-kube-controller-manager  # was: kube-system
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true  # was: false
          # ... rest stays the same

        - job_name: scheduler
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - openshift-kube-scheduler  # was: kube-system
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true  # was: false
          # ... rest stays the same
```

#### 4. KSM Scraping (Deployment)

Add a port filter to the KSM `relabel_configs` to target port 8080 (OpenShift exposes KSM on this port):

```yaml
receivers:
  prometheus/ksm:
    config:
      scrape_configs:
        - job_name: kube-state-metrics
          relabel_configs:
            - action: keep
              regex: kube-state-metrics
              source_labels:
                - __meta_kubernetes_pod_label_app_kubernetes_io_name
            # OpenShift: filter to port 8080
            - action: keep
              source_labels:
                - __address__
              regex: .*:8080$
            - action: replace
              target_label: job_label
              replacement: kube-state-metrics
```

#### 5. Log Exclusions (DaemonSet)

Add OpenShift-specific log exclusions to the `filelog` receiver:

```yaml
receivers:
  filelog:
    exclude:
      # ... existing exclusions ...
      # OpenShift-specific
      - /var/log/pods/*/openshift*/*.log
```

### GKE Autopilot

GKE Autopilot restricts host filesystem access and kubelet authentication. All changes below apply to the **DaemonSet** configuration only; the Deployment configuration does not require changes.

#### 1. Host Metrics Receiver (DaemonSet)

Remove `root_path: /hostfs` from the `hostmetrics` receiver (host filesystem is not accessible):

```yaml
receivers:
  hostmetrics:
    # Do NOT set root_path on GKE Autopilot
    collection_interval: 1m
    scrapers:
      # ... same scrapers as base config
```

Also remove the `/hostfs` volume mount from the DaemonSet manifest.

#### 2. Kubelet Stats Receiver (DaemonSet)

Change to the read-only kubelet port with unauthenticated access:

```yaml
receivers:
  kubeletstats:
    collection_interval: 1m
    endpoint: "${KUBE_NODE_NAME}:10255"  # was: 10250
    auth_type: "none"                     # was: "serviceAccount"
    # Remove insecure_skip_verify (not needed for unauthenticated)
```

#### 3. Disable Pod Logs (DaemonSet)

GKE Autopilot does not allow access to the host filesystem for pod logs. Remove the `filelog` receiver and `logs` pipeline entirely from the DaemonSet configuration.

### Collector Self-Metrics

To collect metrics from the collector itself, add Prometheus scrape jobs for the collector's built-in metrics endpoint.

#### DaemonSet

Add an `otel-collector` job to the existing `prometheus` receiver's `scrape_configs`:

```yaml
receivers:
  prometheus:
    config:
      scrape_configs:
        # ... existing cadvisor and kubelet jobs ...

        # Collector self-metrics
        - job_name: otel-collector
          scrape_interval: 1m
          static_configs:
            - targets: ['0.0.0.0:8888']
          relabel_configs:
            - action: replace
              target_label: job_label
              replacement: otel-collector-daemonset
```

The existing `transform/collector` processor already marks these metrics for low data mode.

#### Deployment

Add a separate `prometheus/collector` receiver:

```yaml
receivers:
  # ... existing receivers ...

  prometheus/collector:
    config:
      scrape_configs:
        - job_name: otel-collector
          scrape_interval: 1m
          static_configs:
            - targets: ['0.0.0.0:8888']
          relabel_configs:
            - action: replace
              target_label: job_label
              replacement: otel-collector-deployment
```

Add `prometheus/collector` to the receivers list of the `metrics/controlplane` pipeline (or create a separate pipeline for it).

---

## RBAC Requirements

The collector requires a ServiceAccount with permissions to read Kubernetes resources (nodes, pods, endpoints, etc.). Your ServiceAccount and ClusterRole must include at minimum the same permissions shown in these reference examples:

- **ServiceAccount**: [examples/k8s/rendered/serviceaccount.yaml](examples/k8s/rendered/serviceaccount.yaml)
- **ClusterRole**: [examples/k8s/rendered/clusterrole.yaml](examples/k8s/rendered/clusterrole.yaml)
- **ClusterRoleBinding**: [examples/k8s/rendered/clusterrolebinding.yaml](examples/k8s/rendered/clusterrolebinding.yaml)

---

## Using the OpenTelemetry Kube Stack Helm Chart

If you're already using (or prefer to use) the [opentelemetry-kube-stack](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-kube-stack) Helm chart, you can apply the configurations from this guide through its `values.yaml`. The kube-stack chart wraps the OpenTelemetry Operator, which watches `OpenTelemetryCollector` CRDs and creates the actual Kubernetes resources (DaemonSets, Deployments, ConfigMaps, Services).

### Kube Stack Prerequisites

**cert-manager** is required by the OpenTelemetry Operator for webhook certificates. Install it before deploying the kube-stack chart:

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

**Add the OpenTelemetry Helm repo:**

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

### Key Differences from the Standard Chart

The kube-stack chart + Operator architecture has several important differences from deploying raw Kubernetes manifests or the `nr-k8s-otel-collector` chart:

| Area | Behavior |
| --- | --- |
| **Volumes** | When presets are enabled, the chart auto-adds `hostfs`, `varlogpods`, and `varlibdockercontainers` volumes/mounts — do **not** duplicate these. When all presets are disabled (BYO config), you must provide these volumes and mounts yourself. |
| **Ports** | Uses Service-style `port` (not `containerPort`). |
| **Presets** | The daemon collector has presets enabled by default (`logsCollection`, `kubeletMetrics`, `hostMetrics`, `kubernetesAttributes`) that inject additional receivers and Prometheus scrape jobs. When providing a complete BYO config, **disable all presets** to avoid duplicate scrape job conflicts. |
| **scrape_configs_file** | The daemon collector loads `daemon_scrape_configs.yaml` by default, which injects `kubelet`, `kubernetes-pods`, and `node-exporter` scrape jobs. Set `scrape_configs_file: ""` when providing your own. |
| **ConfigMap naming** | The Operator creates ConfigMaps with a hash suffix (e.g., `<release>-daemon-collector-029afa75`). The config key is always `collector.yaml`. |
| **Config delivery** | The Operator always uses `--config=/conf/collector.yaml` and mounts its ConfigMap at `/conf`. This path **cannot be overridden** via `args`. |
| **Image** | The default image (`otel/opentelemetry-collector-k8s`) is a subset of the contrib distribution and does **not** include the `metricsgeneration` processor. Override with the full contrib image (`otel/opentelemetry-collector-contrib`), a custom-built image, or the NRDOT image (`newrelic/nrdot-collector`). |
| **RBAC** | The chart provides a top-level `clusterRole.rules` field for adding extra permissions. |

### Per-Node Config Injection with File Provider

The `metricsgeneration/calculate_percentage` processor needs per-node CPU and memory allocatable values for its `scale_by` fields. The standard `nr-k8s-otel-collector` chart uses an init container to patch the config file directly, but the kube-stack Operator **controls the config mount at `/conf`** and cannot be overridden via `args`.

The solution uses the OTel collector's **`${file:/path}` confmap provider**:

1. An init container fetches node allocatable values via `kubectl` and writes them to individual files on a shared `emptyDir` volume (e.g., `/node-env/cpu`, `/node-env/memory`).
2. The collector config references these files using `${file:/node-env/cpu}` and `${file:/node-env/memory}` in the `scale_by` fields.
3. The collector resolves `${file:...}` references at startup (before YAML parsing), so the numeric values are treated as `float64` — exactly what `scale_by` requires.

This approach works because:

- Each DaemonSet pod has its own `emptyDir` volume, so values are per-node.
- The `${file:...}` provider is part of the core OTel collector (no extra dependencies).
- No `command` override or config mount changes are needed.

The init container and volume configuration are shown in the values example below.

### Create a Custom `values.yaml`

The kube-stack chart uses a `collectors` map where each entry defines a collector instance. You need two collectors: a **DaemonSet** for node-level metrics/logs and a **Deployment** for cluster-wide metrics.

```yaml
# values-newrelic.yaml

kubeStateMetrics:
  enabled: true

clusterName: <YOUR_CLUSTER_NAME>

collectors:
  daemon:
    mode: daemonset
    enabled: true
    image:
      repository: "otel/opentelemetry-collector-contrib"
      tag: "0.144.0"
    scrape_configs_file: ""
    presets:
      logsCollection:
        enabled: false
      kubeletMetrics:
        enabled: false
      hostMetrics:
        enabled: false
      kubernetesAttributes:
        enabled: false
    env:
      - name: NR_LICENSE_KEY
        valueFrom:
          secretKeyRef:
            name: newrelic-license-key
            key: license-key
      - name: HOST_IP
        valueFrom:
          fieldRef:
            fieldPath: status.hostIP
      - name: POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name
      - name: POD_UID
        valueFrom:
          fieldRef:
            fieldPath: metadata.uid
      - name: KUBE_NODE_NAME
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: spec.nodeName
      - name: OTEL_RESOURCE_ATTRIBUTES
        value: service.instance.id=$(POD_NAME),k8s.pod.uid=$(POD_UID)
    args:
      feature-gates: "metricsgeneration.MatchAttributes,-processor.resourcedetection.propagateerrors"
    volumeMounts:
      - name: node-env
        mountPath: /node-env
      - name: hostfs
        mountPath: /hostfs
        readOnly: true
        mountPropagation: HostToContainer
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
    volumes:
      - name: node-env
        emptyDir: {}
      - name: hostfs
        hostPath:
          path: /
      - name: varlogpods
        hostPath:
          path: /var/log/pods
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
    # NOTE: This init container differs from the standard chart's version.
    # The standard chart patches the config file directly, but the kube-stack
    # Operator controls the config mount at /conf. Instead, this writes values
    # to individual files on a shared emptyDir, and the collector reads them
    # using the ${file:/node-env/cpu} and ${file:/node-env/memory} confmap
    # provider in the scale_by fields.
    initContainers:
      - name: get-node-allocatable
        image: "docker.io/bitnami/kubectl:latest"
        imagePullPolicy: IfNotPresent
        command:
          - sh
          - -c
          - |
            NODE_NAME=$KUBE_NODE_NAME
            echo "Node Name: $NODE_NAME"

            NODE_CPU_ALLOCATABLE=$(kubectl get node $NODE_NAME \
              -o jsonpath='{.status.allocatable.cpu}')

            if [ -z "$NODE_CPU_ALLOCATABLE" ] || [ "$NODE_CPU_ALLOCATABLE" = "0" ]; then
              echo "Could not retrieve CPU allocatable for node $NODE_NAME"
              exit 1
            fi

            # Convert milliCPU (e.g. 1900m) to whole CPU units
            if echo "$NODE_CPU_ALLOCATABLE" | grep -q 'm$'; then
              NODE_CPU_ALLOCATABLE=$(awk \
                "BEGIN {print ${NODE_CPU_ALLOCATABLE%?} / 1000}")
            fi

            NODE_MEMORY_ALLOCATABLE=$(kubectl get node $NODE_NAME \
              -o jsonpath='{.status.allocatable.memory}' | awk '
              /Ki$/ {printf "%.0f\n", $1 * 1024; next}
              /Mi$/ {printf "%.0f\n", $1 * 1024^2; next}
              /Gi$/ {printf "%.0f\n", $1 * 1024^3; next}
              /m$/  {printf "%.0f\n", $1 / 1000; next}
              {print $1}
            ')

            if [ -z "$NODE_MEMORY_ALLOCATABLE" ] || \
               [ "$NODE_MEMORY_ALLOCATABLE" = "0" ]; then
              echo "Could not retrieve Memory allocatable for node $NODE_NAME"
              exit 1
            fi

            echo "NODE_CPU_ALLOCATABLE=$NODE_CPU_ALLOCATABLE"
            echo "NODE_MEMORY_ALLOCATABLE=$NODE_MEMORY_ALLOCATABLE"

            # Write values to individual files for the collector's
            # ${file:/node-env/cpu} and ${file:/node-env/memory} confmap provider
            printf '%s' "$NODE_CPU_ALLOCATABLE" > /node-env/cpu
            printf '%s' "$NODE_MEMORY_ALLOCATABLE" > /node-env/memory
        env:
          - name: KUBE_NODE_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: spec.nodeName
        resources: {}
        volumeMounts:
          - name: node-env
            mountPath: /node-env
    config:
      # Paste the "Full DaemonSet Configuration" from above, with these changes:
      # 1. Replace placeholder values as described in that section's instructions
      # 2. In metricsgeneration/calculate_percentage, replace scale_by placeholders:
      #    - <NODE_CPU_ALLOCATABLE_PLACEHOLDER>    → ${file:/node-env/cpu}
      #    - <NODE_MEMORY_ALLOCATABLE_PLACEHOLDER> → ${file:/node-env/memory}

  cluster:
    mode: deployment
    enabled: true
    replicas: 1
    env:
      - name: NR_LICENSE_KEY
        valueFrom:
          secretKeyRef:
            name: newrelic-license-key
            key: license-key
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      - name: KUBE_NODE_NAME
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: spec.nodeName
    ports:
      - name: http
        port: 4318
        protocol: TCP
      - name: grpc
        port: 4317
        protocol: TCP
    config:
      # Paste the "Full Deployment Configuration" from above.
      # Replace placeholder values as described in that section's instructions.
```

### Create the License Key Secret

Create the Secret in the same namespace where you will install the chart:

```bash
kubectl create namespace <YOUR_NAMESPACE> --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic newrelic-license-key \
  --namespace <YOUR_NAMESPACE> \
  --from-literal=license-key=<YOUR_NEW_RELIC_LICENSE_KEY>
```

### Install the Chart

```bash
helm install otel-newrelic open-telemetry/opentelemetry-kube-stack \
  --namespace <YOUR_NAMESPACE> \
  --values values-newrelic.yaml
```

### Platform-Specific Adjustments

The [OpenShift](#openshift) and [GKE Autopilot](#gke-autopilot) changes apply the same way — modify the corresponding parts of the `config` block within your `values.yaml`.
