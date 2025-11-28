# newrelic-logging Chart - Global Value Inheritance Assessment

**Chart Version**: 1.31.0
**Common-Library Version**: 1.3.3
**Workload Type**: DaemonSet (Linux + Windows)
**Current Test Status**: 61/61 tests passing (13 suites)

## Summary

The newrelic-logging chart has **partial global value support** with significant gaps in critical areas like proxy, scheduling constraints (nodeSelector, tolerations), and affinity. While the chart uses common-library helpers for some global values (images, security contexts, dnsConfig), it lacks comprehensive test coverage and misses key global values needed for enterprise environments.

## Current Global Value Coverage

### ✅ Implemented (via common-library, but needs test coverage)

| Global Value | Implementation | Test Coverage | Notes |
|--------------|---------------|---------------|-------|
| cluster | Helper: `newrelic-logging.cluster` | ❌ None | Propagates correctly via helper |
| licenseKey | Helper: `newrelic-logging.licenseKey` | ❌ None | Propagates correctly via helper |
| customSecretName | Helper: `newrelic-logging.customSecretName` | ❌ None | Alternative auth |
| customSecretLicenseKey | Helper: `newrelic-logging.customSecretKey` | ❌ None | Alternative auth |
| images.registry | `newrelic.common.images.image` | ✅ 3 tests | Working correctly |
| images.pullSecrets | `newrelic.common.images.renderPullSecrets` | ✅ 2 tests | Working correctly |
| podLabels | Direct template | ❌ None | Propagates correctly |
| labels | Helper: `newrelic-logging.labels` | ❌ None | Propagates correctly |
| dnsConfig | `newrelic.common.dnsConfig` | ⚠️ Partial | Local test only |
| podSecurityContext | `newrelic.common.securityContext.pod` | ❌ None | Common-library helper |
| containerSecurityContext | `newrelic.common.securityContext.container` | ❌ None | Common-library helper |
| serviceAccount.create | `newrelic.common.serviceAccount.name` | ❌ None | Common-library helper |
| serviceAccount.name | `newrelic.common.serviceAccount.name` | ❌ None | Common-library helper |
| serviceAccount.annotations | Unknown | ❌ None | Need to verify |
| lowDataMode | Helper: `newrelic-logging.lowDataMode` | ❌ None | Propagates correctly |
| nrStaging | Helper: `newrelic-logging.logsEndpoint` | ❌ None | Used for endpoint selection |

### ❌ Missing Implementation (CRITICAL GAPS)

| Global Value | Current Status | Priority | Impact |
|--------------|----------------|----------|--------|
| **proxy** | ❌ Not implemented | **P0** | **CRITICAL** - Blocks corporate environments |
| **priorityClassName** | ❌ Local only (line 208) | **P0** | Scheduling failures |
| **nodeSelector** | ❌ Local only (line 225-234) | **P0** | Can't schedule on tagged nodes |
| **tolerations** | ❌ Local only (line 235-238) | **P0** | Can't tolerate node taints |
| **affinity** | ❌ Partial (Fargate only) | **P1** | Advanced scheduling broken |
| **hostNetwork** | ❌ Local only (line 50-52) | **P1** | Can't inherit global setting |
| **verboseLog** | ❌ Not implemented | **P2** | Debug logging broken |

### ⚠️ Not Applicable (7/27)

- provider: Not used by logging chart
- privileged: DaemonSet doesn't require privileged mode
- customAttributes: Not applicable to log forwarding
- fargate: Special handling exists (affinity exclusion)
- fedramp.enabled: Need to verify endpoint logic
- insightsKey: Deprecated

## Gaps Analysis

### 1. Proxy Support (P0 - CRITICAL)

**Current State**:
- No proxy support implemented
- Comments in values.yaml (lines 52-54) show example of using `fluentBit.extraEnv`
- Users must manually add HTTP_PROXY/HTTPS_PROXY to extraEnv

**Impact**:
- Fluent Bit cannot reach New Relic in corporate proxy environments
- Silent telemetry loss
- Most reported issue according to project plan

**Required Fix**:
```yaml
# Add to daemonset.yaml env section
{{- $globalProxy := "" }}
{{- if .Values.global }}
  {{- $globalProxy = .Values.global.proxy | default "" }}
{{- end }}
{{- $proxy := .Values.proxy | default $globalProxy | default "" }}
{{- if $proxy }}
- name: HTTP_PROXY
  value: {{ $proxy | quote }}
- name: HTTPS_PROXY
  value: {{ $proxy | quote }}
{{- end }}
```

### 2. Scheduling Constraints (P0 - CRITICAL)

**Current State**:
- `priorityClassName` uses only `.Values.priorityClassName` (line 208)
- `nodeSelector` uses only `.Values.nodeSelector` (line 225-234)
- `tolerations` uses only `.Values.tolerations` (line 235-238)
- No global inheritance for any scheduling value

**Impact**:
- Can't apply cluster-wide node selection rules
- DaemonSet pods fail to schedule on tainted nodes
- Priority scheduling broken

**Required Fix**: Use common-library helpers:
- `newrelic.common.priorityClassName`
- `newrelic.common.nodeSelector`
- `newrelic.common.tolerations`

### 3. Affinity (P1)

**Current State**:
- Only handles Fargate exclusion via nodeAffinity (lines 211-224)
- No support for global.affinity
- No common-library helper usage

**Impact**:
- Advanced pod scheduling rules don't work
- Can't use global affinity patterns

**Required Fix**: Use `newrelic.common.affinity` helper

### 4. Host Network (P1)

**Current State**:
- Uses only `.Values.hostNetwork` (line 50-52)
- No global inheritance

**Impact**:
- Global hostNetwork setting ignored
- Inconsistent with other charts

**Required Fix**:
```yaml
{{- $hostNetwork := false }}
{{- if not (kindIs "invalid" .Values.hostNetwork) }}
  {{- $hostNetwork = .Values.hostNetwork }}
{{- else if .Values.global }}
  {{- if not (kindIs "invalid" .Values.global.hostNetwork) }}
    {{- $hostNetwork = .Values.global.hostNetwork }}
  {{- end }}
{{- end }}
{{- if $hostNetwork }}
hostNetwork: {{ $hostNetwork }}
{{- end }}
```

### 5. Verbose Logging (P2)

**Current State**:
- Chart has `fluentBit.logLevel` field
- No verboseLog implementation
- No mapping from global.verboseLog to logLevel

**Impact**:
- Global debug logging doesn't work
- Inconsistent with other charts

**Required Fix**:
```yaml
{{- $verboseLog := include "newrelic.common.verboseLog" . -}}
{{- $logLevel := .Values.fluentBit.logLevel | default "info" -}}
{{- if eq $verboseLog "true" }}
  {{- $logLevel = "debug" }}
{{- end }}
- name: LOG_LEVEL
  value: {{ $logLevel | quote }}
```

## Test Coverage Gaps

### Existing Tests (5 test scenarios)
1. ✅ global.images.registry propagation (images_test.yaml)
2. ✅ local registry overrides global (images_test.yaml)
3. ✅ pullSecrets merge (images_test.yaml)
4. ⚠️ dnsConfig local only (dns_config_test.yaml - no global test)
5. ⚠️ hostNetwork local only (host_network_test.yaml - no global test)

### Missing Tests (15+ global values)
- cluster, licenseKey, customSecret*
- proxy, priorityClassName, nodeSelector, tolerations, affinity
- hostNetwork (global), verboseLog
- podLabels, labels, podSecurityContext, containerSecurityContext
- lowDataMode, nrStaging, serviceAccount.*

## Implementation Plan

### Phase 1: Template Fixes (P0 - Critical)

1. **Add Proxy Support** (deployment.yaml, deployment-windows.yaml)
   - Add proxy environment variables with precedence
   - Add values.yaml field `proxy: ""`
   - Ensure extraEnv preserves existing behavior

2. **Fix Scheduling Constraints** (deployment.yaml, deployment-windows.yaml)
   - Replace priorityClassName with `newrelic.common.priorityClassName`
   - Replace nodeSelector with `newrelic.common.nodeSelector`
   - Replace tolerations with `newrelic.common.tolerations`

3. **Fix Affinity** (deployment.yaml, deployment-windows.yaml)
   - Integrate `newrelic.common.affinity` while preserving Fargate exclusion

4. **Fix HostNetwork** (deployment.yaml, deployment-windows.yaml)
   - Add global.hostNetwork precedence logic

5. **Add Verbose Logging** (deployment.yaml, deployment-windows.yaml)
   - Map global.verboseLog to LOG_LEVEL=debug

### Phase 2: Comprehensive Test Suite

Create `tests/global-inheritance_test.yaml` with test coverage for:

1. **Proxy** (3 tests)
   - None set (no env vars)
   - Global set (HTTP_PROXY/HTTPS_PROXY appear)
   - Local overrides global

2. **PriorityClassName** (3 tests)
   - None, global, local override

3. **NodeSelector** (3 tests)
   - None, global, local override

4. **Tolerations** (3 tests)
   - None (defaults to Exists), global, local override

5. **Affinity** (4 tests)
   - None, global, local override, Fargate exclusion preserved

6. **HostNetwork** (4 tests)
   - None (field not rendered), false (not rendered), true (rendered), global inheritance

7. **VerboseLog** (4 tests)
   - None (LOG_LEVEL=info), global true (debug), local logLevel, override

8. **Security Contexts** (6 tests)
   - podSecurityContext: global, local override
   - containerSecurityContext: global, local override, merge

9. **ServiceAccount** (4 tests)
   - create, name, annotations, global inheritance

10. **Cluster/License** (4 tests)
    - cluster propagation, licenseKey propagation, customSecret variants

11. **LowDataMode** (3 tests)
    - None (false), global true, local override

12. **NrStaging** (3 tests)
    - None (prod endpoint), global true (staging endpoint), local override

**Total New Tests**: ~44 tests covering all applicable global values

### Phase 3: Documentation

1. Update values.yaml comments explaining global inheritance
2. Update README.md with global values section
3. Add CHANGELOG.md entry
4. Create PR description with comprehensive global values table

## Applicable Global Values (20/27)

| Global Value | Applicable | Reason |
|--------------|------------|--------|
| cluster | ✅ Yes | Required for entity relationship |
| licenseKey | ✅ Yes | Required for authentication |
| customSecretName | ✅ Yes | Alternative auth |
| customSecretLicenseKey | ✅ Yes | Alternative auth |
| provider | ❌ No | Not used by logging |
| labels | ✅ Yes | Applied to all resources |
| podLabels | ✅ Yes | Applied to pods |
| images.registry | ✅ Yes | Air-gapped support |
| images.pullSecrets | ✅ Yes | Air-gapped support |
| serviceAccount.* | ✅ Yes | IAM roles (IRSA, Workload Identity) |
| hostNetwork | ✅ Yes | DaemonSet scheduling |
| dnsConfig | ✅ Yes | DNS configuration |
| proxy | ✅ Yes | Corporate environments |
| priorityClassName | ✅ Yes | Scheduling priority |
| nodeSelector | ✅ Yes | Node targeting |
| tolerations | ✅ Yes | Taint tolerance |
| affinity | ✅ Yes | Advanced scheduling |
| podSecurityContext | ✅ Yes | Pod security |
| containerSecurityContext | ✅ Yes | Container security |
| privileged | ❌ No | Not required for log collection |
| customAttributes | ❌ No | Not applicable to logging |
| lowDataMode | ✅ Yes | Reduces log attributes |
| fargate | ⚠️ Partial | Special Fargate exclusion logic exists |
| nrStaging | ✅ Yes | Endpoint selection |
| fedramp.enabled | ⚠️ Unknown | Need to verify endpoint logic |
| verboseLog | ✅ Yes | Maps to fluentBit.logLevel |
| insightsKey | ❌ No | Deprecated |

**Total Applicable**: 20/27 (74%)

## Acceptance Criteria

- [ ] All 6 missing global values implemented in templates
- [ ] 44+ comprehensive tests added covering all applicable globals
- [ ] All tests pass (100% pass rate)
- [ ] No breaking changes to existing configurations
- [ ] CHANGELOG.md entry added
- [ ] PR description includes complete 27-value table
- [ ] Windows DaemonSet templates updated (same changes as Linux)
