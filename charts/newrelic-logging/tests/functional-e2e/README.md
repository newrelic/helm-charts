# Functional E2E Tests for Global Value Inheritance

## Overview

This directory contains functional end-to-end (E2E) tests that validate global value inheritance for the newrelic-logging chart in a real Kubernetes environment. Unlike helm-unittest tests (which only validate template rendering), these tests deploy the chart to a Kubernetes cluster and verify that configuration values actually reach the running containers.

**Important**: These tests do NOT validate telemetry (whether data reaches New Relic). They only validate functional configuration propagation. For telemetry validation, see the main repository E2E test suite using `newrelic-integration-e2e-action`.

## What These Tests Validate

The test suite validates that the following global values propagate correctly to the newrelic-logging DaemonSet:

1. **Proxy Configuration** (`global.proxy`)
   - HTTP_PROXY and HTTPS_PROXY environment variables are set in Fluent Bit containers
   - Local `proxy` value overrides `global.proxy` (precedence validation)

2. **NodeSelector** (`global.nodeSelector`)
   - Global node selection constraints apply to DaemonSet pods
   - Pods schedule only on nodes matching the selector

3. **Tolerations** (`global.tolerations`)
   - Global tolerations allow pods to tolerate node taints
   - Pods can schedule on tainted nodes

4. **Custom Registry** (`global.images.registry`)
   - Container images pull from custom registry
   - Image paths include the custom registry domain

5. **ServiceAccount Annotations** (`global.serviceAccount.annotations`)
   - Annotations (e.g., for IRSA, Workload Identity) propagate to ServiceAccount
   - Critical for cloud IAM role bindings

6. **Verbose Logging** (`global.verboseLog`)
   - `global.verboseLog: true` maps to `LOG_LEVEL=debug` in containers
   - Enables debug logging across all components

7. **Host Network** (`global.hostNetwork`)
   - `global.hostNetwork: true` enables host network mode for DaemonSet pods
   - Required for certain networking configurations

## Test Approach and Limitations

### What These Tests Validate

These tests validate **configuration propagation** - they verify that Helm values reach the Kubernetes pod specifications correctly. The tests:

- ✅ Deploy the chart using Helm with specific global values
- ✅ Wait for pod objects to be created in Kubernetes
- ✅ Inspect pod specifications to verify configuration is present
- ✅ Validate environment variables, nodeSelectors, tolerations, etc.

### What These Tests Do NOT Validate

These tests do NOT validate runtime behavior:

- ❌ Pods do NOT need to become "Ready" (tests don't wait for readiness)
- ❌ Fluent Bit does NOT need to actually run
- ❌ No telemetry validation (data reaching New Relic)
- ❌ No functional testing of log collection

### Rationale

This approach allows fast, lightweight testing of configuration inheritance without requiring:
- Working container images in the test environment
- New Relic account credentials
- Long test execution times (tests complete in ~2-3 minutes vs ~10+ minutes)

The tests use lightweight test images (or image pull policy `Never`) to speed up execution and reduce dependencies. Since we're only validating pod specifications (which Kubernetes populates immediately), we don't need the containers to successfully start.

**For runtime and telemetry validation**, see the main repository E2E test suite using `newrelic-integration-e2e-action`.

## Prerequisites

### Required Tools

- **kubectl**: Kubernetes command-line tool
- **helm**: Helm 3.x
- **Kubernetes cluster**: Minikube, KIND, or any Kubernetes cluster

### Cluster Requirements

- Cluster must have at least 1 node
- User must have permissions to:
  - Deploy DaemonSets and ServiceAccounts
  - Label nodes
  - Taint nodes
  - Create/delete Helm releases

### Test Environment Setup

The tests are designed to run on local Kubernetes clusters (Minikube, KIND, k3d). Example setup with k3d:

```bash
# Install k3d (lightweight Kubernetes)
brew install k3d  # macOS
# OR
# curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create a local cluster
k3d cluster create demo

# Verify cluster is running
kubectl get nodes

# Build lightweight test image
docker build -t e2e/newrelic-fluentbit-output:test -f Dockerfile.test .

# Load image into k3d cluster
k3d image import e2e/newrelic-fluentbit-output:test -c demo
```

**Note**: The test image can be any lightweight image (busybox, alpine) since tests only validate pod specifications, not runtime behavior. The chart is configured with `image.pullPolicy=Never` to use locally loaded images.

## Running the Tests

### Run All Tests

```bash
cd charts/newrelic-logging/tests/functional-e2e
./test-global-values.sh
```

### Test Output

The test script provides colored output:
- 🟢 **[INFO]**: General information
- 🟡 **[WARN]**: Warnings (non-fatal)
- 🔴 **[ERROR]**: Errors (fatal)
- ✓ **PASS**: Test passed
- ✗ **FAIL**: Test failed

Example output:

```
[INFO] Starting functional E2E tests for global value inheritance
[INFO] Using kubectl context: minikube
[INFO] Test 1: Proxy configuration propagation
[INFO] Installing chart with global.proxy...
[INFO] Waiting for DaemonSet to be ready (timeout: 120s)...
[INFO] DaemonSet ready: 1/1 pods
[INFO] ✓ PASS: HTTP_PROXY environment variable set correctly
[INFO] ✓ PASS: HTTPS_PROXY environment variable set correctly
...
========================================
Test Summary
========================================
Tests run:    8
Tests passed: 8
Tests failed: 0
========================================
[INFO] All tests passed!
```

### Test Duration

- **Per test**: ~30-60 seconds (Helm install + DaemonSet ready wait)
- **Total suite**: ~5-8 minutes

## Test Details

### Test 1: Proxy Configuration Propagation

**What it tests**: `global.proxy` → `HTTP_PROXY`/`HTTPS_PROXY` environment variables

**Steps**:
1. Install chart with `global.proxy: "http://test-proxy.example.com:3128"`
2. Wait for DaemonSet to be ready
3. Inspect pod spec for HTTP_PROXY and HTTPS_PROXY env vars
4. Validate values match expected proxy URL

**Why it matters**: Corporate environments require proxy configuration for outbound connections.

---

### Test 2: Proxy Override

**What it tests**: Local `proxy` value takes precedence over `global.proxy`

**Steps**:
1. Install chart with both `global.proxy` and `proxy` set
2. Verify HTTP_PROXY uses local `proxy` value (not global)

**Why it matters**: Validates precedence model (local > global > default).

---

### Test 3: NodeSelector Propagation

**What it tests**: `global.nodeSelector` applies to DaemonSet pods

**Steps**:
1. Label cluster node with `test-label=true`
2. Install chart with `global.nodeSelector.test-label: "true"`
3. Verify pod has nodeSelector field with correct label
4. Cleanup: Remove node label

**Why it matters**: Enables node targeting for dedicated monitoring nodes.

---

### Test 4: Tolerations Propagation

**What it tests**: `global.tolerations` allows pods to tolerate node taints

**Steps**:
1. Taint cluster node with `test-taint=true:NoSchedule`
2. Install chart with `global.tolerations` matching taint
3. Verify pod schedules despite taint (has toleration in spec)
4. Cleanup: Remove node taint

**Why it matters**: Enables deployment on tainted nodes (e.g., monitoring-dedicated nodes).

---

### Test 5: Custom Registry Propagation

**What it tests**: `global.images.registry` changes container image paths

**Steps**:
1. Install chart with `global.images.registry: "custom-registry.example.com"`
2. Inspect pod spec for container image path
3. Verify image path includes custom registry

**Why it matters**: Critical for air-gapped environments and private registries.

---

### Test 6: ServiceAccount Annotations Propagation

**What it tests**: `global.serviceAccount.annotations` propagate to ServiceAccount

**Steps**:
1. Install chart with `global.serviceAccount.annotations.eks.amazonaws.com/role-arn`
2. Inspect ServiceAccount for annotation
3. Verify annotation value matches expected

**Why it matters**: Required for IAM roles (AWS IRSA, GCP Workload Identity, Azure Pod Identity).

---

### Test 7: VerboseLog Propagation

**What it tests**: `global.verboseLog: true` → `LOG_LEVEL=debug`

**Steps**:
1. Install chart with `global.verboseLog: true`
2. Inspect pod spec for LOG_LEVEL env var
3. Verify value is "debug" (not default "info")

**Why it matters**: Enables debug logging for troubleshooting.

---

### Test 8: HostNetwork Propagation

**What it tests**: `global.hostNetwork: true` enables host network mode

**Steps**:
1. Install chart with `global.hostNetwork: true`
2. Inspect pod spec for hostNetwork field
3. Verify field is true

**Why it matters**: Required for certain networking configurations (e.g., UDP log forwarding).

---

## Troubleshooting

### Test Failures

#### "DaemonSet did not become ready within 120s"

**Cause**: Image not available, insufficient resources, or scheduling constraints preventing pod from running.

**Solutions**:
1. Verify image is loaded into Minikube: `minikube image ls | grep newrelic-fluentbit`
2. Check pod events: `kubectl describe pod <pod-name>`
3. Check pod logs: `kubectl logs <pod-name>`
4. Verify cluster has resources: `kubectl top nodes`

#### "NodeSelector test failing"

**Cause**: Node label not applied or multiple nodes present.

**Solutions**:
1. Verify node has label: `kubectl get nodes --show-labels`
2. If multiple nodes, ensure label is on all nodes or adjust test

#### "Tolerations test failing"

**Cause**: Taint not applied or pod doesn't have toleration.

**Solutions**:
1. Verify node has taint: `kubectl describe node <node-name> | grep Taints`
2. Check pod tolerations: `kubectl get pod <pod-name> -o yaml | grep -A 10 tolerations`

### Cleanup Issues

If tests fail midway, you may need to manually clean up:

```bash
# Delete Helm release
helm delete nr-logging-e2e --namespace default

# Remove node labels
kubectl label node --all test-label-

# Remove node taints
kubectl taint node --all test-taint-

# Delete test pods
kubectl delete pod test-pod-for-exec --namespace default
```

## Integration with CI/CD

These tests are designed to run in GitHub Actions workflows. See `.github/workflows/functional-e2e.yaml` for the workflow configuration.

### Workflow Triggers

- **On PR**: Run against all supported Kubernetes versions
- **On Push to main**: Run regression tests
- **Manual**: Via workflow_dispatch

### Kubernetes Version Matrix

Tests run against:
- v1.34.0
- v1.33.0
- v1.32.0
- v1.31.0
- v1.30.0

## Limitations

### What These Tests Don't Cover

1. **Telemetry Validation**: Tests don't verify that logs reach New Relic (use `newrelic-integration-e2e-action` for that)
2. **Fluent Bit Functionality**: Tests don't verify log parsing, filtering, or forwarding logic
3. **Multi-Node Scheduling**: Tests assume single-node cluster (Minikube)
4. **Windows DaemonSet**: Tests only cover Linux DaemonSet (Windows requires Windows node)
5. **Performance**: No load testing or resource usage validation

### Known Issues

- **Image Loading**: Tests require pre-built image loaded into Minikube (not pulled from registry)
- **Single Node**: Tests may not catch multi-node scheduling issues
- **No Proxy Server**: Tests validate proxy env vars but don't test actual proxy connectivity

## Future Enhancements

1. **Multi-Chart Tests**: Validate global values across multiple charts in nri-bundle
2. **Real Proxy Test**: Deploy Squid proxy in Minikube and validate connectivity
3. **Air-Gapped Registry Test**: Deploy local registry and validate image pull
4. **Windows Support**: Add Windows node to Minikube and test Windows DaemonSet
5. **Fargate Exclusion Test**: Validate that affinity rules exclude Fargate nodes
6. **Priority Class Test**: Validate `global.priorityClassName` propagation
7. **Affinity Test**: Validate `global.affinity` propagation

## Related Documentation

- [Helm Unit Tests](../README.md): Template-level tests using helm-unittest
- [E2E Telemetry Tests](../../../../e2e/README.md): Telemetry validation tests (if available)
- [Global Values Specification](../../../../CLAUDE.md): Complete list of 27 global values

## Support

For issues or questions:
- **GitHub Issues**: [newrelic/helm-charts/issues](https://github.com/newrelic/helm-charts/issues)
- **Pull Requests**: Contributions welcome!
- **Documentation**: [New Relic Kubernetes Integration Docs](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/get-started/introduction-kubernetes-integration/)
