# GKE Autopilot variant confirmation (manual e2e)

Manual end-to-end check of the `nr-k8s-otel-collector` chart on a real GKE Autopilot cluster: it
deploys each GKE Autopilot variant, applies the matching New Relic `WorkloadAllowlist` where needed,
and asserts the metrics that variant should produce. This is **not** wired into CI — the CI e2e runs
on Minikube (`../e2e/test-specs.yml`).

## Variants tested

| Variant | Values | Allowlist CR | Adds |
|---|---|---|---|
| baseline | `../e2e/e2e-values-gke-autopilot-baseline.yml` (`provider: GKE_AUTOPILOT`) | none | kubelet/cAdvisor metrics with no privilege |
| filesystem | `../e2e/e2e-values-gke-autopilot-filesystem.yml` (`+ gkeAutopilotAllowlist: true`) | `newrelic-nr-k8s-otel-collector-pod-scoped-hostnet-off` | `system.filesystem.*` |
| atp | `../e2e/e2e-values-gke-autopilot-atp.yml` (`+ enable_atp: true`) | same pod-scoped CR | `process.*` |

The **node-scoped / host-network** variant (node `system.network.*` + `process.cpu.time`) needs the
daemonset `hostPID`/`hostNetwork` chart change from PR #2403 (`otel/daemonset-host-namespaces`). It is
not reachable on this branch (PR #2426 is filesystem-only). When #2403 lands, add a fourth scenario
using the `newrelic-nr-k8s-otel-collector-node-scoped-hostnet-on` CR (already included here as a
fixture) and values that set the host-namespace flags.

The two CRs are byte-identical copies of the submission candidates in the gke-autopilot-allowlist
staging repo (`allowListToSubmit/finalized_v3/`). Keep them in sync.

## Prerequisites

- An existing GKE Autopilot cluster you can reach (default context
  `gke_k8s-o11y-team_us-west2_gke-autopilot-truong`). Applying a CR directly requires a "blessed"
  project; customers use the `AllowlistSynchronizer` instead.
- A New Relic **production** account (Autopilot is not on staging): `ACCOUNT_ID`, a USER API key, an
  INGEST license key — all for the same account/region.
- `helm` v3, `kubectl`, `go`. The published `newrelic/nrdot-collector` image is used by default (no
  build needed).

## Run it

```bash
cd charts/nr-k8s-otel-collector
bash e2e/run-gke-autopilot-e2e.sh
```

The runner prompts for anything missing (context, region, account, keys), offers to save to a
gitignored `.env`, adds the required helm repos, and runs all three variants. It never switches your
kube-context or any identity.

## Notes

- Query scoping is `k8s.cluster.name` (OTel-native); `global.cluster` is set to the scenario tag.
  Assertions use `filter(...)` so the e2e-action's appended cluster filter is the only `WHERE`.
- Managed control-plane metrics (apiserver/scheduler/etcd) are not collected on Autopilot — expected.
- To validate your own collector build, push it and set `COLLECTOR_REGISTRY`/`COLLECTOR_TAG` in `.env`.
