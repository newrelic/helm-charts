# GKE Autopilot WorkloadAllowlist (nr-ebpf-agent)

New Relic's GKE Autopilot `WorkloadAllowlist` for the `nr-ebpf-agent` chart, tracked here for
visibility. This is the submission candidate hosted by Google at `gke://NewRelic/nr-ebpf-agent/`.

- `newrelic-nr-ebpf-agent-hostnet-on.workloadallowlist.yaml` — the single eBPF shape.

The eBPF agent always runs `privileged: true` with host namespaces (`hostNetwork`/`hostPID`): BPF
map access needs privilege, host namespaces expose node-wide network flows, and the init container
writes the host root to stage kernel headers. There is no unprivileged shape, so this is the only
CR and the allowlist is required. Without it GKE Warden denies the pod at admission and no eBPF
data flows.

Customers install it via Google's `AllowlistSynchronizer`; this file is not templated by the chart.
Keep it in sync with what New Relic submits to Google. The `newrelic.com/tested-*` annotations
record the chart and app versions the shape was last live-verified on.
