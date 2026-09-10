# E2E Tests

The e2e tests verify that the `nr-k8s-otel-collector` chart correctly collects and ships Kubernetes metrics to New Relic. They use the [`newrelic-integration-e2e-action`](https://github.com/newrelic/newrelic-integration-e2e-action) test runner.

Two scenarios are defined in `test-specs.yml`:

1. **cluster-metrics** — installs the chart and verifies standard K8s OTel metrics are collected
2. **cluster-apm-metrics** — installs the chart plus the OpenTelemetry demo app and verifies APM + infrastructure metrics are collected together

## Automated (CI)

Tests run automatically on pull requests via `.github/workflows/nr-k8s-otel-e2e.yml` against a Minikube cluster on `ubuntu-latest`.

## Running Manually Against a Cloud Cluster

You can run the same tests locally against any cloud-provider managed cluster (EKS, GKE, AKS, etc.). This is useful for one-off validation or testing cluster-specific behavior that differs from Minikube.

### Prerequisites

- `kubectl` configured with a context pointing to your target cluster
- `helm` v3
- Go toolchain (to run the e2e binary)
- A New Relic account with the following keys:
  - **License Key** (Ingest - License)
  - **API Key** (User key)
  - **Account ID**

  See [New Relic API Keys](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/) for details on finding these.

### Steps

**1. Verify your kubectl context points to the correct cluster:**

```shell
kubectl config current-context
kubectl get nodes
```

**2. Add required Helm repositories:**

The tests install the chart directly from your local working tree (`../` relative to the `e2e/` directory), so no `newrelic` chart repo is needed for the chart itself. The following repos are required for chart subchart dependencies (`common-library`, `kube-state-metrics`) and the OTel demo app used in the APM scenario:

```shell
helm repo add newrelic https://helm-charts.newrelic.com
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

**3. Set environment variables:**

```shell
export LICENSE_KEY=<your-ingest-license-key>
export API_KEY=<your-user-api-key>
export ACCOUNT_ID=<your-account-id>
```

**4. Run the tests from the repo root:**

```shell
LICENSE_KEY=${LICENSE_KEY} \
go run github.com/newrelic/newrelic-integration-e2e-action@latest \
  --commit_sha=local-test \
  --retry_attempts=10 \
  --retry_seconds=90 \
  --account_id=${ACCOUNT_ID} \
  --api_key=${API_KEY} \
  --license_key=${LICENSE_KEY} \
  --spec_path=charts/nr-k8s-otel-collector/e2e/test-specs.yml \
  --agent_enabled=false
```

The test runner will:
- Run `helm dependency update` on your local chart
- Install **your local chart** (and demo app for the APM scenario) into your cluster
- Wait for metrics to appear in New Relic
- Assert against the metric specs in `cluster-metrics.yml` and `cluster-apm-metrics.yml`
- Uninstall the chart and clean up resources after each scenario

### Notes for Cloud Clusters

- **Exceptions:** `exceptions.yml` lists metrics excluded from Minikube CI (e.g. `kube_service_status_load_balancer_ingress`, `container.memory.usage`). On a cloud cluster with a load balancer, some of these metrics may actually be present — the exceptions file only skips assertions, so extra metrics do not cause failures.
- **Control plane metrics:** Managed clusters (EKS, GKE, AKS) typically restrict access to control plane components. Metrics from the apiserver, controller-manager, scheduler, and etcd receivers may not be collected. This is expected and does not indicate a chart misconfiguration.
- **Namespace cleanup:** Each scenario creates a `nr-<scenario-tag>` namespace and removes it after the run. If a test run is interrupted, clean up manually:
  ```shell
  helm uninstall <scenario-tag> --namespace nr-<scenario-tag>
  kubectl delete namespace nr-<scenario-tag>
  ```

### Running a Single Scenario

To run only one of the two scenarios, pass `--scenario_tag` with a name that matches the scenario's `description` field in `test-specs.yml`. Refer to the [newrelic-integration-e2e-action docs](https://github.com/newrelic/newrelic-integration-e2e-action) for the full list of flags.
