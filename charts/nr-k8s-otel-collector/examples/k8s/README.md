# Rendered Examples

This directory contains example Kubernetes manifests that will be deployed using this Helm chart.

## Directory Structure

### `/rendered/`
All generated manifests organized by chart/component:

**Root level** (main nr-k8s-otel-collector chart):
- `daemonset.yaml` - DaemonSet collector CR
- `statefulset.yaml` - StatefulSet collector CR
- `serviceaccount.yaml` - Separate ServiceAccounts for DaemonSet and StatefulSet
- `clusterrole.yaml` - RBAC permissions for collectors
- `clusterrolebinding.yaml` - RBAC bindings
- `secret.yaml` - License key secret
- `service.yaml` - Service for collector

**`crds/`** - All OpenTelemetry Custom Resource Definitions:
- `opentelemetry.io_opentelemetrycollectors.yaml` - OpenTelemetryCollector CRD
- `opentelemetry.io_targetallocators.yaml` - Target Allocator CRD
- `opentelemetry.io_instrumentations.yaml` - Auto-instrumentation CRD
- `opentelemetry.io_opampbridges.yaml` - OpAMP Bridge CRD

**`kube-state-metrics/`** - KSM subchart resources:
- `deployment.yaml`, `service.yaml`, `serviceaccount.yaml`
- `role.yaml`, `clusterrolebinding.yaml`

**`opentelemetry-operator/`** - OTEL Operator subchart resources:
- `deployment.yaml` - Operator deployment
- `service.yaml`, `serviceaccount.yaml`
- `clusterrole.yaml`, `clusterrolebinding.yaml`, `role.yaml`, `rolebinding.yaml`
- `admission-webhooks/` - Validating/mutating webhook configurations
- `tests/` - Test resources

**`opentelemetry-kube-stack/`** - Kube-stack hooks:
- `hooks.yaml` - Pre-install and pre-delete hooks

**Generated with:** `helm template --include-crds --output-dir` (v3.8+)

## Key Resources

### CRDs (from opentelemetry-kube-stack subchart)
- `OpenTelemetryCollector` - Defines collector deployments (our DaemonSet and StatefulSet)
- `TargetAllocator` - Manages dynamic Prometheus target discovery
- `Instrumentation` - Enables auto-instrumentation of applications (future feature)
- `OpAMPBridge` - Provides OpAMP protocol support (future feature)

### Custom Resources (CRs) - Instances
- **DaemonSet Collector** - Runs on every node to collect kubelet stats, cAdvisor metrics, and host metrics
- **StatefulSet Collector** - Runs centrally to collect cluster-wide metrics from Kube-State-Metrics and control plane

### RBAC
- **Separate ServiceAccounts** - One for DaemonSet (node-level access), one for StatefulSet (cluster-level access)
- **ClusterRoles** - Define permissions needed for each deployment mode
- **ClusterRoleBindings** - Bind roles to service accounts

## How These Are Used

```
helm install my-release . \
  --namespace monitoring \
  --set licenseKey=<YOUR_LICENSE_KEY> \
  --set cluster=<CLUSTER_NAME>
```

When you run `helm install`:
1. Helm applies CRDs first (from kube-stack subchart)
2. Then creates ServiceAccounts, RBAC resources, and OpenTelemetryCollector CRs
3. OpenTelemetry Operator automatically reconciles the CRs into running pods

## Regenerating These Examples

To regenerate these manifests after making changes to the chart:

```bash
# From the root of the repo
make generate-examples
```

This will:
1. Build Helm dependencies for the chart
2. Run `helm template --include-crds --output-dir` to generate all manifests with CRDs
3. Organize outputs into logical subdirectories (crds/, kube-state-metrics/, opentelemetry-operator/, etc.)
4. Place all organized outputs in the `rendered/` folder

The `--include-crds` flag ensures all OpenTelemetry CRDs are included in the rendered output.

## Customization

These rendered examples use default values. To customize:
- Modify the chart (`charts/nr-k8s-otel-collector/templates/`)
- Modify `values.yaml` to change default configuration
- Run `make generate-examples` to regenerate these manifests
- Review the organized resource files to see the impact

## Resource Counts

**Typical rendered output includes:**
- **4 CRDs** in `crds/` (OpenTelemetryCollector, TargetAllocator, Instrumentation, OpAMPBridge)
- **2 OpenTelemetryCollector CRs** at root (DaemonSet and StatefulSet collector instances)
- **2 Deployments** (Operator in `opentelemetry-operator/`, Kube-State-Metrics in `kube-state-metrics/`)
- **3+ ClusterRoles** across components (collectors, operator, kube-state-metrics)
- **5+ ServiceAccounts** (DaemonSet, StatefulSet, Operator, Kube-State-Metrics, etc.)
- **Multiple ClusterRoleBindings & Roles** for RBAC
- **3-4 Services** (collector, operator, kube-state-metrics)
- **Webhooks** (admission controllers for operator)
- **Pre-install hooks** (pre-delete cleanup jobs)

## More Information

- [OpenTelemetry Operator Docs](https://opentelemetry.io/docs/kubernetes/operator/)
- [New Relic Kubernetes Monitoring](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/)
- [Chart Values Documentation](../values.yaml)
