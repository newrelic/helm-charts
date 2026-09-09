# Nightly Chart Builds - nr-k8s-otel-collector

**Warning:** Nightly builds are experimental and intended for testing only. Use stable releases for production environments.

---

## Current: GitHub Pages Repository (Recommended)

**Repository:** `https://newrelic.github.io/helm-charts/nightly/`

### Adding the Repository

```bash
# Add nightly repository
helm repo add newrelic-nightly https://newrelic.github.io/helm-charts/nightly/
helm repo update

# Search for available nightly versions
helm search repo newrelic-nightly/nr-k8s-otel-collector --versions
```

### Installing with Helm CLI

```bash
# Install specific nightly version
helm install nr-k8s-otel-collector-nightly \
  newrelic-nightly/nr-k8s-otel-collector \
  --version 0.10.14-nightly.20260318.a1b2c3d \
  --set licenseKey='<YOUR_LICENSE_KEY>' \
  --set cluster='<YOUR_CLUSTER_NAME>' \
  -n newrelic --create-namespace
```

### ArgoCD Integration (GitHub Pages)

**Auto-track latest nightly:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nr-k8s-otel-collector-nightly
spec:
  source:
    repoURL: https://newrelic.github.io/helm-charts/nightly/
    chart: nr-k8s-otel-collector
    targetRevision: '*'  # Always use latest nightly
    helm:
      values: |
        licenseKey: "YOUR_LICENSE_KEY"
        cluster: "canary-cluster"
  destination:
    server: https://kubernetes.default.svc
    namespace: newrelic
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Pin to specific version:**
```yaml
spec:
  source:
    targetRevision: '0.10.14-nightly.20260318.a1b2c3d'
```

**Benefits:**
- No authentication required (public GitHub Pages)
- Standard Helm repository protocol
- Works with all Helm tooling
- ArgoCD wildcards work reliably

---

## Legacy: GHCR OCI Registry

**Repository:** `oci://ghcr.io/newrelic/helm-charts-nightly`

**Note:** This method requires authentication and may have compatibility issues. Kept for reference.

### Installing Nightly Charts with ArgoCD (GHCR)

**Recommended: Auto-track latest nightly**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nr-k8s-otel-collector-nightly
spec:
  source:
    repoURL: oci://ghcr.io/newrelic/helm-charts-nightly
    chart: nr-k8s-otel-collector
    targetRevision: '*-0'  # Always use latest nightly (including prereleases)
    helm:
      values: |
        licenseKey: "YOUR_LICENSE_KEY"
        cluster: "canary-cluster"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Alternative: Pin to specific nightly for reproducible testing**
```yaml
spec:
  source:
    targetRevision: '0.10.14-nightly.20260317.a1b2c3d'
```

**Using Helm Chart Dependencies**
```yaml
# In your Chart.yaml
dependencies:
  - name: nr-k8s-otel-collector
    version: '0.10.14-nightly.20260317.a1b2c3d'  # Must use specific version
    repository: oci://ghcr.io/newrelic/helm-charts-nightly
```
Note: Chart.yaml dependencies require exact versions; wildcards are not supported.

### Installing with Helm CLI

```shell
# List available nightly versions
helm search repo oci://ghcr.io/newrelic/helm-charts-nightly/nr-k8s-otel-collector --versions

# Pull specific nightly for inspection
helm pull oci://ghcr.io/newrelic/helm-charts-nightly/nr-k8s-otel-collector \
  --version 0.10.14-nightly.20260318.a1b2c3d

# Install specific nightly version
helm install test-nr-k8s-otel-collector \
  oci://ghcr.io/newrelic/helm-charts-nightly/nr-k8s-otel-collector \
  --version 0.10.14-nightly.20260318.a1b2c3d \
  --set licenseKey='<YOUR_LICENSE_KEY>' \
  --set cluster='<YOUR_CLUSTER_NAME>' \
  -n newrelic --create-namespace
```

Note: Helm CLI requires exact version numbers. Use ArgoCD with `targetRevision: '*-0'` for automatic nightly tracking.
