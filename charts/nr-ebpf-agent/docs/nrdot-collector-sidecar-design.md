# nr-k8s-otel-collector — Design & Implementation Guide

## Context

The `nr-ebpf-agent` chart previously shipped a separate otel-collector DaemonSet alongside the eBPF
agent. **That DaemonSet has been removed.** Kubernetes infrastructure telemetry (pod/container
metrics, deployment health, kubelet stats) is now provided by embedding `newrelic/nrdot-collector`
directly into the chart as two lightweight components controlled by a **single master toggle**.

When the toggle is `false` — the default — the chart behaves exactly as it does today: one
DaemonSet, one container, no collector overhead.

```
nrOtelCollector.enabled: false   →   DaemonSet (nr-ebpf-agent only), no Deployment
nrOtelCollector.enabled: true    →   DaemonSet (nr-ebpf-agent + sidecar) + single Deployment
```

The eBPF agent pod already has everything the sidecar needs to work without extra privileges:

| Pod capability | Used by |
|---|---|
| `hostNetwork: true` | Sidecar reaches kubelet API at `hostIP:10250` |
| `hostPID: true` | Sidecar process-level visibility for hostmetrics |
| `/host` mount (hostPath `/`) | Covers `/proc`, `/run/udev`, filesystem scrapers |
| `/sys` mount (hostPath `/sys`) | CPU, block device, network interface scrapers |
| Existing RBAC | pods, nodes, namespaces, services, replicasets already granted |

---

## Why two components, not one

Receivers fall into two scopes that physically cannot share a workload:

| Receiver | Scope | Must run as | Reason |
|---|---|---|---|
| `kubeletstats` | Per-node | DaemonSet sidecar | Reads the **local** kubelet at `hostIP:10250` |
| `hostmetrics` | Per-node | DaemonSet sidecar | Reads `/proc` and `/sys` of the local host |
| `k8s_events` | Per-node | DaemonSet sidecar | One watcher per node is fine |
| `k8s_cluster` | Cluster-wide | **Single Deployment** | Watches the API server — running it on every node sends N duplicate streams |

`k8s_cluster` is the receiver that provides deployment-level data:

```
k8s.deployment.desired / available          k8s.replicaset.desired / available
k8s.statefulset.desired_pods / ready_pods   k8s.daemonset.desired_scheduled / ready_nodes
k8s.pod.phase                               k8s.container.ready / restarts
k8s.horizontalpodautoscaler.*               k8s.job.*   k8s.cronjob.*
```

Both components are gated by the same `nrOtelCollector.enabled` flag. Flipping it to `false`
removes the sidecar container from every DaemonSet pod **and** deletes the Deployment — no
collector resources remain in the cluster.

---

## Architecture

```
nrOtelCollector.enabled: true

┌──────────────────────── DaemonSet pod (×N nodes) ────────────────────────┐
│                                                                           │
│  ┌──────────────────────────┐      ┌──────────────────────────────────┐  │
│  │     nr-ebpf-agent        │      │     nrdot-collector (sidecar)    │  │
│  │                          │      │                                  │  │
│  │  eBPF network traces     │      │  kubeletstats  (pod/container)   │  │
│  │  APM spans               │      │  hostmetrics   (opt, see note)   │  │
│  │  host metrics            │      │  k8s_events    (opt)             │  │
│  └────────────┬─────────────┘      └──────────────────┬───────────────┘  │
│               │ OTLP/gRPC                             │ OTLP/HTTP        │
└───────────────┼───────────────────────────────────────┼──────────────────┘
                ▼                                       ▼
           New Relic                               New Relic

┌──────────────────────── Deployment pod (×1 per cluster) ─────────────────┐
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │     nr-k8s-otel-collector                                          │  │
│  │                                                                    │  │
│  │  k8s_cluster receiver                                              │  │
│  │  → deployment / replicaset / statefulset / daemonset metrics       │  │
│  │  → pod phase, container restarts, HPA, job, cronjob metrics        │  │
│  └─────────────────────────────────────┬──────────────────────────────┘  │
│                                        │ OTLP/HTTP                       │
└────────────────────────────────────────┼────────────────────────────────-┘
                                         ▼
                                    New Relic
```

---

## What each component covers

| Metric category | Receiver | Component | Example metrics |
|---|---|---|---|
| Node CPU / memory / disk | `hostmetrics` (eBPF agent, existing) | DaemonSet — eBPF container | `system.cpu.utilization`, `system.memory.usage` |
| Per-pod CPU / memory | `kubeletstats` | DaemonSet sidecar | `k8s.pod.cpu.utilization`, `k8s.pod.memory.working_set` |
| Per-container CPU / memory | `kubeletstats` | DaemonSet sidecar | `k8s.container.cpu.request.utilization` |
| Pod network I/O | `kubeletstats` | DaemonSet sidecar | `k8s.pod.network.io`, `k8s.pod.network.errors` |
| Kubernetes events | `k8s_events` | DaemonSet sidecar | Eviction, OOMKill, BackOff as log records |
| Deployment replica counts | `k8s_cluster` | **Deployment** | `k8s.deployment.desired`, `k8s.deployment.available` |
| ReplicaSet health | `k8s_cluster` | **Deployment** | `k8s.replicaset.desired`, `k8s.replicaset.available` |
| StatefulSet pod counts | `k8s_cluster` | **Deployment** | `k8s.statefulset.desired_pods`, `k8s.statefulset.ready_pods` |
| DaemonSet scheduling | `k8s_cluster` | **Deployment** | `k8s.daemonset.desired_scheduled`, `k8s.daemonset.ready_nodes` |
| Pod phase | `k8s_cluster` | **Deployment** | `k8s.pod.phase` (Running / Pending / Failed) |
| Container restarts | `k8s_cluster` | **Deployment** | `k8s.container.restarts` |
| HPA | `k8s_cluster` | **Deployment** | `k8s.hpa.current_replicas`, `k8s.hpa.desired_replicas` |
| eBPF network traces | eBPF agent (existing) | DaemonSet — eBPF container | HTTP spans, TCP stats, DNS |

---

## Implementation steps

### Step 1 — Single values block with master toggle

Add after the `ebpfAgent:` block in [values.yaml](../values.yaml):

```yaml
# -- Embedded nr-k8s-otel-collector stack.
# A single toggle controls both components:
#   enabled: false  →  no sidecar, no Deployment (default, zero overhead)
#   enabled: true   →  nrdot-collector sidecar in every DaemonSet pod
#                      + single-replica Deployment for cluster-scoped metrics
nrOtelCollector:
  enabled: false

  # Shared image for both the sidecar and the Deployment.
  image:
    registry: docker.io
    repository: newrelic/nrdot-collector
    # Pin this to a specific release in production.
    tag: ""
    pullPolicy: IfNotPresent

  # ---------------------------------------------------------------------------
  # sidecar — runs inside the nr-ebpf-agent DaemonSet pod, one per node
  # ---------------------------------------------------------------------------
  sidecar:
    resources:
      limits:
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi

    receivers:
      hostmetrics:
        # The eBPF agent already reports host metrics.
        # Enable only if you disable host metrics in the eBPF agent first.
        enabled: false
        collectionInterval: 60s
        scrapers: [cpu, disk, filesystem, load, memory, network, paging, processes]
      kubeletstats:
        enabled: true
        collectionInterval: 30s
        # Add volume or ephemeral-storage to extraMetricGroups if needed.
        extraMetricGroups: []
      k8sEvents:
        enabled: false

    # Drop-in replacement for the full sidecar pipeline config.
    # When set, the chart-generated config is ignored entirely.
    configOverride: ""

  # ---------------------------------------------------------------------------
  # clusterCollector — single-replica Deployment, cluster-scoped metrics only
  # ---------------------------------------------------------------------------
  clusterCollector:
    resources:
      limits:
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi

    collectionInterval: 30s
    nodeConditionsToReport:
      - Ready
      - MemoryPressure
      - DiskPressure
      - PIDPressure
      - NetworkUnavailable
    allocatableTypesToReport:
      - cpu
      - memory
      - ephemeral-storage

    # Drop-in replacement for the full clusterCollector pipeline config.
    configOverride: ""
```

> **Note on `hostmetrics.enabled`:** The eBPF agent already ships host metrics via its own pipeline.
> Enabling both sends the same time series twice under different `instrumentation.provider` values,
> causing double counting and double billing. Leave it `false` unless you explicitly migrate host
> metrics ownership to the OTel collector (requires disabling it in the eBPF agent).

---

### Step 2 — ConfigMap for the DaemonSet sidecar pipeline

Create [templates/nr-ebpf-agent-nrdot-sidecar-config.yaml](../templates/nr-ebpf-agent-nrdot-sidecar-config.yaml):

```yaml
{{- if .Values.nrOtelCollector.enabled }}
{{- $region := include "newrelic.common.region" . }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "nr-ebpf-agent.fullname" . }}-nrdot-sidecar-config
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  config.yaml: |
    {{- if .Values.nrOtelCollector.sidecar.configOverride }}
    {{ .Values.nrOtelCollector.sidecar.configOverride | nindent 4 }}
    {{- else }}
    receivers:
      {{- if .Values.nrOtelCollector.sidecar.receivers.hostmetrics.enabled }}
      hostmetrics:
        root_path: /host
        collection_interval: {{ .Values.nrOtelCollector.sidecar.receivers.hostmetrics.collectionInterval }}
        scrapers:
          {{- range .Values.nrOtelCollector.sidecar.receivers.hostmetrics.scrapers }}
          {{ . }}: {}
          {{- end }}
      {{- end }}
      {{- if .Values.nrOtelCollector.sidecar.receivers.kubeletstats.enabled }}
      kubeletstats:
        collection_interval: {{ .Values.nrOtelCollector.sidecar.receivers.kubeletstats.collectionInterval }}
        auth_type: serviceAccount
        endpoint: "https://${env:HOST_IP}:10250"
        insecure_skip_verify: true
        metric_groups:
          - node
          - pod
          - container
          {{- range .Values.nrOtelCollector.sidecar.receivers.kubeletstats.extraMetricGroups }}
          - {{ . }}
          {{- end }}
        extra_metadata_labels:
          - container.id
      {{- end }}
      {{- if .Values.nrOtelCollector.sidecar.receivers.k8sEvents.enabled }}
      k8s_events:
        auth_type: serviceAccount
      {{- end }}

    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
        spike_limit_percentage: 25
      batch:
        send_batch_max_size: 1000
        timeout: 30s
        send_batch_size: 800
      k8sattributes:
        auth_type: serviceAccount
        passthrough: false
        extract:
          metadata:
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.namespace.name
            - k8s.node.name
            - k8s.deployment.name
            - k8s.daemonset.name
            - k8s.statefulset.name
            - k8s.replicaset.name
        pod_association:
          - sources:
            - from: resource_attribute
              name: k8s.pod.ip
          - sources:
            - from: resource_attribute
              name: k8s.pod.uid
          - sources:
            - from: connection

    exporters:
      otlphttp:
        endpoint: https://{{ if eq $region "EU" }}otlp.eu01.nr-data.net{{ else if eq $region "Staging" }}staging-otlp.nr-data.net{{ else }}otlp.nr-data.net{{ end }}
        headers:
          api-key: ${env:NEW_RELIC_LICENSE_KEY}
        compression: gzip

    service:
      pipelines:
        {{- $hasMetrics := or .Values.nrOtelCollector.sidecar.receivers.hostmetrics.enabled .Values.nrOtelCollector.sidecar.receivers.kubeletstats.enabled }}
        {{- if $hasMetrics }}
        metrics:
          receivers:
            {{- if .Values.nrOtelCollector.sidecar.receivers.hostmetrics.enabled }}
            - hostmetrics
            {{- end }}
            {{- if .Values.nrOtelCollector.sidecar.receivers.kubeletstats.enabled }}
            - kubeletstats
            {{- end }}
          processors: [memory_limiter, k8sattributes, batch]
          exporters: [otlphttp]
        {{- end }}
        {{- if .Values.nrOtelCollector.sidecar.receivers.k8sEvents.enabled }}
        logs:
          receivers: [k8s_events]
          processors: [memory_limiter, k8sattributes, batch]
          exporters: [otlphttp]
        {{- end }}
    {{- end }}
{{- end }}
```

---

### Step 3 — ConfigMap for the cluster-collector Deployment pipeline

Create [templates/nr-k8s-otel-collector-config.yaml](../templates/nr-k8s-otel-collector-config.yaml):

```yaml
{{- if .Values.nrOtelCollector.enabled }}
{{- $region := include "newrelic.common.region" . }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "nr-ebpf-agent.fullname" . }}-k8s-otel-collector-config
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  config.yaml: |
    {{- if .Values.nrOtelCollector.clusterCollector.configOverride }}
    {{ .Values.nrOtelCollector.clusterCollector.configOverride | nindent 4 }}
    {{- else }}
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        collection_interval: {{ .Values.nrOtelCollector.clusterCollector.collectionInterval }}
        node_conditions_to_report:
          {{- range .Values.nrOtelCollector.clusterCollector.nodeConditionsToReport }}
          - {{ . }}
          {{- end }}
        allocatable_types_to_report:
          {{- range .Values.nrOtelCollector.clusterCollector.allocatableTypesToReport }}
          - {{ . }}
          {{- end }}

    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
        spike_limit_percentage: 25
      batch:
        send_batch_max_size: 1000
        timeout: 30s
        send_batch_size: 800
      resource:
        attributes:
          - key: k8s.cluster.name
            value: {{ if .Values.global }}{{ .Values.global.cluster | default .Values.cluster }}{{ else }}{{ .Values.cluster }}{{ end }}
            action: upsert

    exporters:
      otlphttp:
        endpoint: https://{{ if eq $region "EU" }}otlp.eu01.nr-data.net{{ else if eq $region "Staging" }}staging-otlp.nr-data.net{{ else }}otlp.nr-data.net{{ end }}
        headers:
          api-key: ${env:NEW_RELIC_LICENSE_KEY}
        compression: gzip

    service:
      pipelines:
        metrics:
          receivers: [k8s_cluster]
          processors: [memory_limiter, resource, batch]
          exporters: [otlphttp]
    {{- end }}
{{- end }}
```

---

### Step 4 — Sidecar container in the DaemonSet

In [templates/nr-ebpf-agent-daemonset.yaml](../templates/nr-ebpf-agent-daemonset.yaml):

**Add the sidecar container** after the `nr-ebpf-agent` container's closing `volumeMounts`, before
`dnsPolicy`:

```yaml
      {{- if .Values.nrOtelCollector.enabled }}
      - name: nrdot-collector
        image: "{{ .Values.nrOtelCollector.image.registry }}/{{ .Values.nrOtelCollector.image.repository }}:{{ .Values.nrOtelCollector.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.nrOtelCollector.image.pullPolicy }}
        args: ["--config=/etc/nrdot/config.yaml"]
        resources: {{ .Values.nrOtelCollector.sidecar.resources | toYaml | nindent 10 }}
        env:
          - name: NEW_RELIC_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                {{- if (include "newrelic.common.license._licenseKey" .) }}
                key: NEW_RELIC_LICENSE_KEY
                name: nr-ebpf-agent-secrets
                {{- else }}
                key: {{ include "newrelic.common.license._customSecretKey" . }}
                name: {{ include "newrelic.common.license._customSecretName" . }}
                {{- end }}
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
        volumeMounts:
          - name: nrdot-sidecar-config
            mountPath: /etc/nrdot
            readOnly: true
          {{- if .Values.nrOtelCollector.sidecar.receivers.hostmetrics.enabled }}
          - name: host-root-volume
            mountPath: /host
            readOnly: true
          - name: sys-volume
            mountPath: /sys
            readOnly: true
          {{- end }}
      {{- end }}
```

**Add the ConfigMap volume** in the `volumes:` section:

```yaml
      {{- if .Values.nrOtelCollector.enabled }}
      - name: nrdot-sidecar-config
        configMap:
          name: {{ include "nr-ebpf-agent.fullname" . }}-nrdot-sidecar-config
      {{- end }}
```

**Wire the checksum annotation** so pods roll when the sidecar config changes:

```yaml
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- if .Values.nrOtelCollector.enabled }}
        checksum/nrdot-sidecar-config: {{ include (print $.Template.BasePath "/nr-ebpf-agent-nrdot-sidecar-config.yaml") . | sha256sum }}
        {{- end }}
```

---

### Step 5 — Cluster-collector Deployment

Create [templates/nr-k8s-otel-collector-deployment.yaml](../templates/nr-k8s-otel-collector-deployment.yaml):

```yaml
{{- if .Values.nrOtelCollector.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nr-ebpf-agent.fullname" . }}-k8s-otel-collector
  namespace: {{ .Release.Namespace }}
  labels:
    app: nr-k8s-otel-collector
    component: cluster-metrics
    {{- include "newrelic.common.labels" . | nindent 4 }}
spec:
  # Never set this above 1 — k8s_cluster produces N duplicate streams at N replicas.
  replicas: 1
  selector:
    matchLabels:
      app: nr-k8s-otel-collector
      {{- include "newrelic.common.labels.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        app: nr-k8s-otel-collector
        component: cluster-metrics
        {{- include "newrelic.common.labels.podLabels" . | nindent 8 }}
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/nr-k8s-otel-collector-config.yaml") . | sha256sum }}
    spec:
      serviceAccountName: {{ include "nr-ebpf-agent.service.name" . }}
      {{- with include "newrelic.common.priorityClassName" . }}
      priorityClassName: {{ . }}
      {{- end }}
      {{- with include "nr-ebpf-agent.imagePullSecrets" . }}
      imagePullSecrets:
        {{- . | nindent 8 }}
      {{- end }}
      containers:
      - name: nr-k8s-otel-collector
        image: "{{ .Values.nrOtelCollector.image.registry }}/{{ .Values.nrOtelCollector.image.repository }}:{{ .Values.nrOtelCollector.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.nrOtelCollector.image.pullPolicy }}
        args: ["--config=/etc/nr-k8s-otel/config.yaml"]
        resources: {{ .Values.nrOtelCollector.clusterCollector.resources | toYaml | nindent 10 }}
        env:
          - name: NEW_RELIC_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                {{- if (include "newrelic.common.license._licenseKey" .) }}
                key: NEW_RELIC_LICENSE_KEY
                name: nr-ebpf-agent-secrets
                {{- else }}
                key: {{ include "newrelic.common.license._customSecretKey" . }}
                name: {{ include "newrelic.common.license._customSecretName" . }}
                {{- end }}
        volumeMounts:
          - name: k8s-otel-collector-config
            mountPath: /etc/nr-k8s-otel
            readOnly: true
      volumes:
        - name: k8s-otel-collector-config
          configMap:
            name: {{ include "nr-ebpf-agent.fullname" . }}-k8s-otel-collector-config
{{- end }}
```

---

### Step 6 — RBAC additions

In [templates/nr-ebpf-agent-rbac.yaml](../templates/nr-ebpf-agent-rbac.yaml), extend the existing
`ClusterRole` under a single `if` block:

```yaml
{{- if .Values.nrOtelCollector.enabled }}
# kubeletstats receiver (sidecar) — kubelet API proxy access
- apiGroups: [""]
  resources: [nodes/stats, nodes/proxy]
  verbs: [get]
# k8sattributes processor (sidecar) — already partially covered by existing rules
- apiGroups: ["events.k8s.io"]
  resources: [events]
  verbs: [get, watch, list]
# k8s_cluster receiver (cluster-collector Deployment)
- apiGroups: [""]
  resources: [resourcequotas]
  verbs: [get, watch, list]
- apiGroups: ["apps"]
  resources: [deployments, replicasets, statefulsets, daemonsets]
  verbs: [get, watch, list]
- apiGroups: ["batch"]
  resources: [jobs, cronjobs]
  verbs: [get, watch, list]
- apiGroups: ["autoscaling"]
  resources: [horizontalpodautoscalers]
  verbs: [get, watch, list]
{{- end }}
```

> `nodes/stats` and `nodes/proxy` are the two most commonly missed permissions. Without them,
> `kubeletstats` starts but logs 403 errors and produces no metrics.

---

### Step 7 — Verify

```bash
# Default — must produce zero nrOtelCollector resources
helm template nr-ebpf-agent ./charts/nr-ebpf-agent \
  --set cluster=test --set licenseKey=fake \
  | grep -c nrdot    # expect 0

# Enabled — sidecar present in DaemonSet + Deployment created
helm template nr-ebpf-agent ./charts/nr-ebpf-agent \
  --set cluster=test --set licenseKey=fake \
  --set nrOtelCollector.enabled=true \
  | grep -E "name: nrdot-collector|kind: Deployment"

# Existing tests must still pass
helm unittest ./charts/nr-ebpf-agent
```

---

## Files to create / modify

| Action | File |
|---|---|
| Modify | [values.yaml](../values.yaml) — add `nrOtelCollector:` block |
| Create | [templates/nr-ebpf-agent-nrdot-sidecar-config.yaml](../templates/nr-ebpf-agent-nrdot-sidecar-config.yaml) |
| Create | [templates/nr-k8s-otel-collector-config.yaml](../templates/nr-k8s-otel-collector-config.yaml) |
| Create | [templates/nr-k8s-otel-collector-deployment.yaml](../templates/nr-k8s-otel-collector-deployment.yaml) |
| Modify | [templates/nr-ebpf-agent-daemonset.yaml](../templates/nr-ebpf-agent-daemonset.yaml) — sidecar container, volume, checksum annotation |
| Modify | [templates/nr-ebpf-agent-rbac.yaml](../templates/nr-ebpf-agent-rbac.yaml) — kubelet proxy, events, k8s_cluster object types |

---

## Minimal working `values.yaml` override

```yaml
cluster: my-cluster
licenseKey: YOUR_LICENSE_KEY

nrOtelCollector:
  enabled: true          # false = no sidecar, no Deployment — chart is eBPF-only
  image:
    tag: "1.0.0"         # pin to a specific release
  sidecar:
    receivers:
      hostmetrics:
        enabled: false   # eBPF agent owns host metrics — leave false
      kubeletstats:
        enabled: true    # pod/container metrics from kubelet API
      k8sEvents:
        enabled: true
  clusterCollector:
    collectionInterval: 30s
```

## Decisions to align on before implementation

1. **Host metrics ownership** — eBPF agent ships host metrics today. If you later want to migrate
   that responsibility to the OTel collector (`hostmetrics` scraper), disable it in the eBPF agent
   first. Running both simultaneously causes duplicate time series and double billing.

2. **`replicas: 1` is a hard constraint** — `k8s_cluster` watches the API server globally. Two
   replicas = two copies of every deployment metric. This is not an HA knob.

3. **Image tag pinning** — `nrOtelCollector.image.tag` defaults to `Chart.AppVersion`. Pin it
   explicitly in production so collector upgrades are intentional, not a side effect of a chart
   version bump.

4. **`configOverride` escape hatch** — both `sidecar.configOverride` and
   `clusterCollector.configOverride` accept a full OTel pipeline YAML that replaces the
   chart-generated config. Use this for non-standard exporters, additional processors, or
   Prometheus scraping without forking the chart.
