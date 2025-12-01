#!/bin/bash

# Functional E2E Tests for Global Value Inheritance
# Tests that global values propagate correctly to newrelic-logging DaemonSet
# Does NOT validate telemetry (no New Relic account required)

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RELEASE_NAME="nr-logging-e2e"
NAMESPACE="default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    log_info "Test $TESTS_RUN: $1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✓ PASS: $1"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log_error "✗ FAIL: $1"
}

cleanup() {
    log_info "Cleaning up test resources..."
    helm delete ${RELEASE_NAME} --namespace ${NAMESPACE} 2>/dev/null || true
    kubectl delete pod test-pod-for-exec --namespace ${NAMESPACE} 2>/dev/null || true
    kubectl label node --all test-label- 2>/dev/null || true
    kubectl taint node --all test-taint- 2>/dev/null || true
}

wait_for_pod_creation() {
    local timeout=30
    local interval=2
    local elapsed=0

    log_info "Waiting for pod to be created (timeout: ${timeout}s)..."

    while [ $elapsed -lt $timeout ]; do
        # Check if DaemonSet exists
        if ! kubectl get daemonset ${RELEASE_NAME}-newrelic-logging --namespace ${NAMESPACE} &>/dev/null; then
            log_warn "DaemonSet not found yet, waiting..."
            sleep $interval
            elapsed=$((elapsed + interval))
            continue
        fi

        # Check if at least one pod exists (not checking readiness)
        local pod_count=$(kubectl get pods --namespace ${NAMESPACE} -l "app.kubernetes.io/name=newrelic-logging" --no-headers 2>/dev/null | wc -l)

        if [ "$pod_count" -gt 0 ]; then
            log_info "Pod created (count: ${pod_count})"
            # Give Kubernetes a moment to populate the pod spec
            sleep 2
            return 0
        fi

        log_warn "No pods found yet (${elapsed}s elapsed)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    log_error "Pod was not created within ${timeout}s"
    return 1
}

get_pod_name() {
    kubectl get pods --namespace ${NAMESPACE} -l "app.kubernetes.io/name=newrelic-logging" -o jsonpath='{.items[0].metadata.name}'
}

# =============================================================================
# Test 1: Proxy Configuration Propagation
# =============================================================================
test_proxy_configuration() {
    test_start "Proxy configuration propagation"

    cleanup

    # Install with global.proxy
    log_info "Installing chart with global.proxy..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.proxy="http://test-proxy.example.com:3128" \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "Proxy test - Pod not created"
        return
    fi

    local pod_name=$(get_pod_name)
    log_info "Testing pod: ${pod_name}"

    # Verify HTTP_PROXY environment variable
    local http_proxy=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.containers[0].env[?(@.name=="HTTP_PROXY")].value}')
    local https_proxy=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.containers[0].env[?(@.name=="HTTPS_PROXY")].value}')

    if [ "$http_proxy" == "http://test-proxy.example.com:3128" ]; then
        test_pass "HTTP_PROXY environment variable set correctly"
    else
        test_fail "HTTP_PROXY not set or incorrect: got '${http_proxy}'"
        return
    fi

    if [ "$https_proxy" == "http://test-proxy.example.com:3128" ]; then
        test_pass "HTTPS_PROXY environment variable set correctly"
    else
        test_fail "HTTPS_PROXY not set or incorrect: got '${https_proxy}'"
        return
    fi
}

# =============================================================================
# Test 2: Proxy Override (Local Value Takes Precedence)
# =============================================================================
test_proxy_override() {
    test_start "Proxy override (local > global)"

    cleanup

    # Install with both global.proxy and proxy (local should win)
    log_info "Installing chart with both global.proxy and proxy..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.proxy="http://global-proxy.example.com:3128" \
        --set proxy="http://local-proxy.example.com:8080" \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "Proxy override test - Pod not created"
        return
    fi

    local pod_name=$(get_pod_name)
    local http_proxy=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.containers[0].env[?(@.name=="HTTP_PROXY")].value}')

    if [ "$http_proxy" == "http://local-proxy.example.com:8080" ]; then
        test_pass "Local proxy value correctly overrides global"
    else
        test_fail "Proxy override failed: got '${http_proxy}', expected 'http://local-proxy.example.com:8080'"
    fi
}

# =============================================================================
# Test 3: NodeSelector Propagation
# =============================================================================
test_nodeselector_propagation() {
    test_start "NodeSelector propagation"

    cleanup

    # Label the node
    log_info "Labeling node with test-label=true..."
    kubectl label node --all test-label=true --overwrite

    # Install with global.nodeSelector
    log_info "Installing chart with global.nodeSelector..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.nodeSelector."test-label"="true" \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "NodeSelector test - Pod not created"
        kubectl label node --all test-label-
        return
    fi

    local pod_name=$(get_pod_name)
    local node_selector=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.nodeSelector.test-label}')

    if [ "$node_selector" == "true" ]; then
        test_pass "NodeSelector correctly propagated to pod"
    else
        test_fail "NodeSelector not set or incorrect: got '${node_selector}'"
    fi

    # Cleanup label
    kubectl label node --all test-label-
}

# =============================================================================
# Test 4: Tolerations Propagation
# =============================================================================
test_tolerations_propagation() {
    test_start "Tolerations propagation"

    cleanup

    # Taint the node
    log_info "Tainting node with test-taint=true:NoSchedule..."
    kubectl taint node --all test-taint=true:NoSchedule --overwrite

    # Install with global.tolerations
    log_info "Installing chart with global.tolerations..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set 'global.tolerations[0].key=test-taint' \
        --set 'global.tolerations[0].operator=Exists' \
        --set 'global.tolerations[0].effect=NoSchedule' \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "Tolerations test - Pod not created (pod may not tolerate taint)"
        kubectl taint node --all test-taint-
        return
    fi

    local pod_name=$(get_pod_name)
    local tolerations=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.tolerations}')

    # Check if tolerations contain our test taint
    if echo "$tolerations" | grep -q "test-taint"; then
        test_pass "Tolerations correctly propagated to pod"
    else
        test_fail "Tolerations not found in pod spec"
    fi

    # Cleanup taint
    kubectl taint node --all test-taint-
}

# =============================================================================
# Test 5: Custom Registry Propagation
# =============================================================================
test_registry_propagation() {
    test_start "Custom registry propagation"

    cleanup

    # Install with global.images.registry
    log_info "Installing chart with global.images.registry..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.images.registry="custom-registry.example.com" \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "Registry test - Pod not created"
        return
    fi

    local pod_name=$(get_pod_name)
    local image=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.containers[0].image}')

    if echo "$image" | grep -q "custom-registry.example.com"; then
        test_pass "Custom registry correctly applied to image: ${image}"
    else
        test_fail "Custom registry not applied: got '${image}'"
    fi
}

# =============================================================================
# Test 6: ServiceAccount Annotations Propagation
# =============================================================================
test_serviceaccount_annotations() {
    test_start "ServiceAccount annotations propagation"

    cleanup

    # Install with global.serviceAccount.annotations
    log_info "Installing chart with global.serviceAccount.annotations..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set 'global.serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::123456789012:role/test-role' \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "ServiceAccount annotations test - Pod not created"
        return
    fi

    # Get the service account name
    local sa_name="${RELEASE_NAME}-newrelic-logging"
    local annotation=$(kubectl get serviceaccount ${sa_name} --namespace ${NAMESPACE} -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}')

    if [ "$annotation" == "arn:aws:iam::123456789012:role/test-role" ]; then
        test_pass "ServiceAccount annotation correctly propagated"
    else
        test_fail "ServiceAccount annotation not set or incorrect: got '${annotation}'"
    fi
}

# =============================================================================
# Test 7: VerboseLog Propagation (global.verboseLog -> LOG_LEVEL=debug)
# =============================================================================
test_verboselog_propagation() {
    test_start "VerboseLog propagation (global.verboseLog -> LOG_LEVEL=debug)"

    cleanup

    # Install with global.verboseLog=true
    log_info "Installing chart with global.verboseLog=true..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.verboseLog=true \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "VerboseLog test - Pod not created"
        return
    fi

    local pod_name=$(get_pod_name)
    local log_level=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}')

    if [ "$log_level" == "debug" ]; then
        test_pass "VerboseLog correctly mapped to LOG_LEVEL=debug"
    else
        test_fail "VerboseLog not mapped correctly: got LOG_LEVEL='${log_level}', expected 'debug'"
    fi
}

# =============================================================================
# Test 8: HostNetwork Propagation
# =============================================================================
test_hostnetwork_propagation() {
    test_start "HostNetwork propagation"

    cleanup

    # Install with global.hostNetwork=true
    log_info "Installing chart with global.hostNetwork=true..."
    helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
        --namespace ${NAMESPACE} \
        --set licenseKey="test-license-key-000000000000000000000000000000000000NRAL" \
        --set global.hostNetwork=true \
        --set image.tag="test" \
        --set image.pullPolicy="Never" \
        --wait=false

    if ! wait_for_pod_creation; then
        test_fail "HostNetwork test - Pod not created"
        return
    fi

    local pod_name=$(get_pod_name)
    local host_network=$(kubectl get pod ${pod_name} --namespace ${NAMESPACE} -o jsonpath='{.spec.hostNetwork}')

    if [ "$host_network" == "true" ]; then
        test_pass "HostNetwork correctly set to true"
    else
        test_fail "HostNetwork not set or incorrect: got '${host_network}'"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    log_info "Starting functional E2E tests for global value inheritance"
    log_info "Chart: ${CHART_DIR}"

    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found - please install kubectl"
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        log_error "helm not found - please install Helm"
        exit 1
    fi

    # Verify kubectl context
    local context=$(kubectl config current-context)
    log_info "Using kubectl context: ${context}"

    # Run tests
    test_proxy_configuration
    test_proxy_override
    test_nodeselector_propagation
    test_tolerations_propagation
    test_registry_propagation
    test_serviceaccount_annotations
    test_verboselog_propagation
    test_hostnetwork_propagation

    # Final cleanup
    cleanup

    # Print summary
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    ${TESTS_RUN}"
    echo "Tests passed: ${TESTS_PASSED}"
    echo "Tests failed: ${TESTS_FAILED}"
    echo "========================================"

    if [ ${TESTS_FAILED} -eq 0 ]; then
        log_info "All tests passed!"
        exit 0
    else
        log_error "${TESTS_FAILED} test(s) failed"
        exit 1
    fi
}

# Run main
main "$@"
