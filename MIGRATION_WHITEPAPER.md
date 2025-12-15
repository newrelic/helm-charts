# OpenTelemetry Operator Migration

## Goal

Replace old Deployment/DaemonSet manifests with OpenTelemetryCollector CRs managed by the OTEL Operator.

- Single source of truth (no config drift between ConfigMap and manifests)
- Operator handles pod lifecycle automatically
- Foundation for future features (Dynamic Prometheus target discovery via Target Allocator, tail sampling, HPA)
- Cleaner, modular configuration

## Why Kube-Stack Instead of Core Operator Helm Chart

I chose `opentelemetry-kube-stack` subchart (not direct operator installation) to solve a known race condition:

When installing the OTEL Operator directly, the admission webhook can race with CRD installation, causing deployment failures if:

- CRD isn't fully registered when webhook tries to validate
- Webhook pod starts before CRD is available
- Timing issues between multiple components initializing

**Reference:** [opentelemetry-helm-charts Issue #677](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/677)

**The Solution (Kube-Stack):**

```yaml
admissionWebhooks:
  failurePolicy: "Ignore"  # Allow CR creation even if webhook isn't ready
  certManager:
    enabled: false
  autoGenerateCert:
    enabled: true  # Generate certs on-the-fly without cert-manager
```

**Result:**

- ✅ Eliminates race condition on initial deployment
- ✅ Webhook comes up safely after CRDs
- ✅ No cert-manager dependency required
- ✅ Reliable deployments across all Kubernetes distributions

## What I Did

### 1. Created OpenTelemetryCollector CRs

- `daemonset.yaml` - Daemonset CR (runs on every node)
- `statefulset.yaml` - Statefulset CR (central cluster metrics)
- Both CRs have feature parity with old manifests

### 2. Refactored Helper Files

Before: 1 monolithic `_config_map.tpl` (10KB+)
After: Modular helpers

- `_cadvisor.tpl` - cAdvisor receiver
- `_hostmetrics.tpl` - HostMetrics receiver
- `_kubeletstats.tpl` - Kubelet stats receiver
- `_kube_state_metrics.tpl` - KubeState Metrics processor
- `_k8s_events.tpl` - K8s events receiver
- `_filelog.tpl` - File log receiver
- `_shared_components.tpl` - Common processors & exporters
- `_routing_connectors.tpl` - Metrics routing

Benefits: Easier to find code, cleaner diffs

## Future Enhancements

**Target Allocator** - Dynamic Prometheus target discovery (currently only own targets enabled)
**Auto-Instrumentation** - Zero-code app instrumentation
**Collector Load Balancer CR** - Receiver with trace.id-based routing
**Collector Gateway CRs** - Multiple gateway collectors for tail sampling
**Tail Sampling** - Sample whole traces based on conditions in each gateway
**HPA** - Auto-scale gateways based on trace throughput
**Pod Disruption Budgets (PDB)** - Ensure availability during cluster maintenance

Architecture:

```
Agent Collectors
    ↓
Collector LoadBalancer (trace.id routing)
    ↓ (routes same trace.id to same gateway)
Collector Gateways (tail sampling processors)
    ↓
New Relic
```