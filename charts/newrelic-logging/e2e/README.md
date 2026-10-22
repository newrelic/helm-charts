# E2E Tests

The e2e tests verify that the `newrelic-logging` chart correctly ships container logs to New Relic. They use the [`newrelic-integration-e2e-action`](https://github.com/newrelic/newrelic-integration-e2e-action) test runner.

Two scenarios are defined in `test-specs.yml`:

1. **Default install** — installs the chart with default settings and verifies a marker log line forwards to New Relic
2. **lowDataMode** — installs the chart with `lowDataMode=true` and verifies basic fields (`pod_name`, `container_name`, `namespace_name`) still survive while stripped metadata (e.g. `labels.app`) does not leak through

Both scenarios apply `e2e-resources.yml`, a `busybox` deployment in the `default` namespace that continuously emits a marker log line, so the tests exercise cross-namespace log collection.

## Automated (CI)

Tests run automatically on pull requests via `.github/workflows/newrelic-logging-e2e.yml` against a Minikube cluster on `ubuntu-latest`. PRs from forks run instead via `.github/workflows/newrelic-logging-e2e-external.yml`, which gates on the `E2E` GitHub environment so a maintainer must approve the run before it can use repo secrets.

Add the `ci/skip-e2e` label to a PR to skip these tests.

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

**2. Set environment variables:**

```shell
export LICENSE_KEY=<your-ingest-license-key>
export API_KEY=<your-user-api-key>
export ACCOUNT_ID=<your-account-id>
```

**3. Run the tests from the repo root:**

```shell
LICENSE_KEY=${LICENSE_KEY} \
go run github.com/newrelic/newrelic-integration-e2e-action@latest \
  --commit_sha=local-test \
  --retry_attempts=6 \
  --retry_seconds=90 \
  --account_id=${ACCOUNT_ID} \
  --api_key=${API_KEY} \
  --license_key=${LICENSE_KEY} \
  --spec_path=charts/newrelic-logging/e2e/test-specs.yml \
  --agent_enabled=false
```

The test runner will:
- Run `helm dependency update` on your local chart
- Install **your local chart** into your cluster (once per scenario, with different `--set` overrides)
- Apply `e2e-resources.yml` to generate marker log lines
- Wait for the marker logs to appear in New Relic
- Assert against the NRQL checks in `test-specs.yml`
- Uninstall the chart and clean up resources after each scenario

### Notes for Cloud Clusters

- **Namespace cleanup:** Each scenario creates a `nr-<scenario-tag>` namespace and removes it after the run. If a test run is interrupted, clean up manually:
  ```shell
  kubectl delete -f charts/newrelic-logging/e2e/e2e-resources.yml
  helm uninstall <scenario-tag> --namespace nr-<scenario-tag>
  kubectl delete namespace nr-<scenario-tag>
  ```

### Running a Single Scenario

To run only one of the two scenarios, pass `--scenario_tag` with a name that matches the scenario's `description` field in `test-specs.yml`. Refer to the [newrelic-integration-e2e-action docs](https://github.com/newrelic/newrelic-integration-e2e-action) for the full list of flags.
