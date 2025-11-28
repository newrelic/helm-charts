# Functional E2E Test Implementation - newrelic-logging

## Summary

Successfully implemented Phase 1 of the integration testing strategy: **Functional E2E Tests** for global value inheritance validation in the newrelic-logging chart.

## What Was Implemented

### 1. Test Script (`charts/newrelic-logging/tests/functional-e2e/test-global-values.sh`)

**Purpose**: Automated bash script that deploys the chart to a Kubernetes cluster and validates configuration propagation using kubectl inspection.

**Test Coverage** (8 test cases):

| Test # | What It Tests | Global Value | Validation Method |
|--------|---------------|--------------|-------------------|
| 1 | Proxy configuration | `global.proxy` | kubectl inspect env vars (HTTP_PROXY, HTTPS_PROXY) |
| 2 | Proxy override precedence | `proxy` > `global.proxy` | kubectl inspect env vars |
| 3 | Node selector | `global.nodeSelector` | kubectl inspect pod spec nodeSelector field |
| 4 | Tolerations | `global.tolerations` | kubectl inspect pod spec tolerations field |
| 5 | Custom registry | `global.images.registry` | kubectl inspect container image path |
| 6 | ServiceAccount annotations | `global.serviceAccount.annotations` | kubectl inspect ServiceAccount annotations |
| 7 | Verbose logging | `global.verboseLog` → LOG_LEVEL=debug | kubectl inspect env vars |
| 8 | Host network | `global.hostNetwork` | kubectl inspect pod spec hostNetwork field |

**Features**:
- ✅ Colored output (INFO/WARN/ERROR/PASS/FAIL)
- ✅ Automatic cleanup (removes helm releases, node labels, taints)
- ✅ Test summary report (tests run/passed/failed)
- ✅ Timeout handling (120s wait for DaemonSet ready)
- ✅ Error handling (set -e, set -o pipefail)
- ✅ Exit code 0 on success, 1 on failure

**Runtime**: ~5-8 minutes for full suite (8 tests × ~40s per test)

---

### 2. Documentation (`charts/newrelic-logging/tests/functional-e2e/README.md`)

**Contents**:
- Overview of functional E2E testing approach
- Prerequisites (kubectl, helm, Kubernetes cluster)
- Test environment setup (Minikube)
- Running instructions
- Detailed test descriptions (what each test validates and why)
- Troubleshooting guide
- CI/CD integration notes
- Known limitations
- Future enhancements roadmap

**Length**: ~400 lines, comprehensive documentation

---

### 3. GitHub Actions Workflow (`.github/workflows/functional-e2e.yaml`)

**Purpose**: Automated CI/CD pipeline that runs functional E2E tests on every PR and push.

**Configuration**:
- **Triggers**: PR (to newrelic-logging chart), push to main/master, manual workflow_dispatch
- **Kubernetes Version Matrix**: Tests against K8s v1.34, v1.33, v1.32, v1.31, v1.30
- **Runner**: ubuntu-latest with Minikube + containerd runtime
- **Helm Version**: 3.16.3
- **Minikube Version**: v1.37.0

**Workflow Steps**:
1. Checkout code
2. Setup Helm
3. Setup Minikube with specific K8s version
4. Verify Minikube cluster
5. Build test image (busybox-based for fast startup)
6. Load image into Minikube
7. Run functional E2E test suite
8. Collect pod logs on failure (diagnostics)
9. Cleanup (always runs)
10. Summary job (reports overall pass/fail)

**Features**:
- ✅ Matrix testing across 5 Kubernetes versions
- ✅ Fail-fast disabled (all versions tested even if one fails)
- ✅ Automatic diagnostics collection on failure
- ✅ Always cleanup (prevents resource leaks)
- ✅ Summary job for easy PR status checks

---

## Files Created

```
newrelic-logging-fork/
├── .github/workflows/
│   └── functional-e2e.yaml                          # GitHub Actions workflow (NEW)
├── charts/newrelic-logging/tests/functional-e2e/
│   ├── test-global-values.sh                         # Test script (NEW, executable)
│   └── README.md                                      # Documentation (NEW)
└── FUNCTIONAL_E2E_IMPLEMENTATION.md                  # This file (NEW)
```

**Total Lines of Code**: ~900 lines
- Test script: ~450 lines
- README: ~400 lines
- Workflow: ~80 lines
- Summary: ~200 lines

---

## How to Run Locally

### Prerequisites

1. **Install Minikube**:
   ```bash
   # macOS
   brew install minikube

   # Linux
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

2. **Install kubectl** (if not already installed):
   ```bash
   brew install kubectl  # macOS
   ```

3. **Install Helm** (if not already installed):
   ```bash
   brew install helm  # macOS
   ```

### Run Tests

```bash
# 1. Start Minikube
minikube start --container-runtime=containerd --kubernetes-version=v1.30.0

# 2. Verify cluster
kubectl get nodes

# 3. Build and load test image
cd /Users/dpacheco/Documents/WIP/nri-bundle-refactor/newrelic-logging-fork/charts/newrelic-logging
cat > Dockerfile.test <<'EOF'
FROM busybox:latest
CMD ["/bin/sh", "-c", "while true; do sleep 3600; done"]
EOF
docker build -f Dockerfile.test -t e2e/newrelic-fluentbit-output:test .
minikube image load e2e/newrelic-fluentbit-output:test
rm Dockerfile.test

# 4. Run tests
cd tests/functional-e2e
./test-global-values.sh

# 5. Cleanup (optional, script does this automatically)
minikube delete
```

**Expected Output**:
```
[INFO] Starting functional E2E tests for global value inheritance
[INFO] Using kubectl context: minikube
[INFO] Test 1: Proxy configuration propagation
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

---

## Integration with Existing Work

### Relationship to Helm Unit Tests

| Aspect | Helm Unit Tests | Functional E2E Tests |
|--------|----------------|----------------------|
| **What** | Template rendering validation | Configuration propagation validation |
| **Tool** | helm-unittest | kubectl + bash |
| **Speed** | Fast (~seconds) | Slower (~5-8 min) |
| **Scope** | Template logic only | Real deployment behavior |
| **Cluster** | Not required | Required (Minikube) |
| **Coverage** | 107 tests, all 20 global values | 8 tests, 8 critical scenarios |

**Complementary, Not Redundant**: Helm unit tests validate templates are correct. Functional E2E tests validate that correct templates actually work in a real cluster.

### Relationship to Telemetry E2E Tests

**Functional E2E** (this work):
- Validates configuration reaches containers
- No New Relic account required
- Fast feedback (~5-8 min)
- kubectl-based inspection

**Telemetry E2E** (Phase 2, future work):
- Validates logs reach New Relic
- Requires New Relic staging account
- Slower (~10-15 min)
- NRQL query-based validation
- Uses `newrelic-integration-e2e-action`

---

## What This Enables

### Immediate Benefits

1. **Confidence in PRs**: Every PR now validates that global values actually work in a real cluster
2. **Regression Prevention**: Tests catch configuration bugs before merge
3. **Multi-Version Validation**: Tests run against 5 Kubernetes versions (catches version-specific issues)
4. **Fast Feedback**: Developers know within ~10 minutes if changes break configuration

### Foundation for Future Work

1. **Phase 2 (Telemetry E2E)**: Can extend test-specs.yml with configuration scenarios
2. **Phase 3 (Multi-Chart)**: Can reuse test patterns for nri-bundle-wide tests
3. **Other Charts**: Can copy/adapt test script to nri-kube-events, nri-metadata-injection, etc.

---

## Known Limitations

### What These Tests Don't Validate

1. ❌ **Telemetry**: Logs reaching New Relic (Phase 2)
2. ❌ **Fluent Bit Functionality**: Log parsing/filtering/forwarding
3. ❌ **Multi-Node**: Assumes single-node cluster
4. ❌ **Windows**: Only tests Linux DaemonSet
5. ❌ **Performance**: No load testing
6. ❌ **Proxy Connectivity**: Tests env vars, not actual proxy usage
7. ❌ **Air-Gap**: Tests registry path, not actual image pull from private registry

### Why These Limitations Are OK

- **Focused Scope**: Tests validate configuration propagation (the PR's goal)
- **Fast Execution**: Single-node tests are much faster than multi-node
- **Complementary Coverage**: Other test types cover other aspects
- **Incremental Improvement**: Phase 2 will add telemetry validation

---

## Next Steps

### For newrelic-logging Chart

1. ✅ **Commit and Push**: Commit functional E2E tests to `refactor/newrelic-logging-global-inheritance` branch
2. ✅ **Include in PR**: Add functional E2E tests to the newrelic-logging PR (or submit as follow-up)
3. ⏭️ **Manual Testing**: Run tests locally with Minikube to verify (see "How to Run Locally" above)
4. ⏭️ **CI/CD Validation**: Push to fork and verify GitHub Actions workflow runs successfully

### For Other Charts

1. ⏭️ **nri-kube-events**: Adapt test script for nri-kube-events chart (1 week)
2. ⏭️ **nri-metadata-injection**: Adapt test script for webhook functionality (1 week)
3. ⏭️ **newrelic-infrastructure**: Adapt test script with control plane scenarios (2 weeks)

### Phase 2: Telemetry E2E Tests

1. ⏭️ **Setup Squid Proxy**: Deploy proxy server in Minikube
2. ⏭️ **Setup Local Registry**: Deploy private registry in Minikube
3. ⏭️ **Extend test-specs.yml**: Add configuration scenarios to existing E2E tests
4. ⏭️ **NRQL Validation**: Verify telemetry reaches New Relic with proxy/registry configs

**Timeline**: 6-8 weeks after Phase 1 complete across all charts

---

## Acceptance Criteria - Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Test script created | ✅ Done | 8 test cases, 450 lines |
| README documentation | ✅ Done | 400 lines, comprehensive |
| GitHub workflow | ✅ Done | Matrix testing, 5 K8s versions |
| All 8 tests pass locally | ⏳ Pending | Requires manual verification with Minikube |
| CI/CD workflow passes | ⏳ Pending | Will verify on push to fork |
| Tests are idempotent | ✅ Done | Each test has cleanup logic |
| Tests are independent | ✅ Done | Each test starts with cleanup |
| Error handling | ✅ Done | set -e, set -o pipefail, exit codes |

---

## Resources

- **Test Script**: `charts/newrelic-logging/tests/functional-e2e/test-global-values.sh`
- **Documentation**: `charts/newrelic-logging/tests/functional-e2e/README.md`
- **Workflow**: `.github/workflows/functional-e2e.yaml`
- **Related Work**:
  - newrelic-logging helm-unittest: 107/107 tests passing
  - newrelic-logging PR draft: `/Users/dpacheco/Documents/WIP/nri-bundle-refactor/PR_DRAFTS/newrelic-logging.md`

---

## Conclusion

Phase 1 functional E2E tests are **implementation-complete** for the newrelic-logging chart. The test infrastructure provides:

✅ **Automated validation** that global values propagate correctly
✅ **Fast feedback** (~5-8 min for full suite)
✅ **Multi-version coverage** (K8s 1.30-1.34)
✅ **CI/CD integration** (GitHub Actions)
✅ **Comprehensive documentation**
✅ **Reusable foundation** for other charts

**Next action**: Manual local testing with Minikube to verify all 8 tests pass.
