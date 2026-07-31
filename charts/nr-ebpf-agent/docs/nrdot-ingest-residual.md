# Notes

After the parity work, this chart's nrdot collector sends the same Kubernetes
metrics as New Relic's canonical `nr-k8s-otel-collector`. Comparing raw ingest
still shows eBPF higher. Two reasons, both expected — subtract them first.

## 1. Scrape interval (2×)

eBPF nrdot scrapes every **30s**, canonical every **60s**. Same metrics, twice
as often → twice the datapoints. Normalize this out before comparing.

> **Knob:** the interval is `nrdotCollector.collectionInterval` (default `30s`),
> and it drives **every** nrdot scraper — kubeletstats + all 5 prometheus
> receivers. Setting it to `60s` matches canonical and erases this 2× factor.
> Measured 2026-07-30 (LDM, `--set nrdotCollector.collectionInterval=60s`): nrdot
> datapoints **halved** (194,959 → 102,257 dp/h). Total eBPF only dropped ~33%,
> not 50%, because the prometheus agent and host `system.*` (§2) run on their own
> intervals and don't scale with this knob. Kept at `30s` by default (finer
> resolution than canonical; a 60s→30s regression vs nri-bundle otherwise).

## 2. Host metrics (not part of the k8s pipeline)

The eBPF agent also reports `system.*` / `host.*` (CPU, memory, disk, network)
for the **HOST** entity via its `host_stats` connector. Canonical has
hostmetrics disabled, so it sends none. This is the eBPF product's value-add,
not k8s telemetry — exclude it from any k8s-pipeline comparison. (~0.3 GB/day.)

> Note: these carry `k8s.cluster.name`, so a `cluster.name IS NOT NULL` filter
> does **not** drop them. Exclude by `metricName NOT LIKE 'system.%' AND
> NOT LIKE 'host.%'`.

## The residual: ~17%

After removing host metrics and normalizing the interval, eBPF's k8s pipeline is
**~1.17×** canonical. That extra 17% is four eBPF-only families. Two are used by
the UI; two are not (kept on purpose, to compare against the nri-bundle infra agent):

| Family | UI query? | Note |
|---|---|---|
| `container_memory_usage_bytes` | **yes** | container entity → Metrics tab |
| `container_network_*_bytes_total` | **yes** | node & workload network tiles query `max … FACET pod`, so the per-interface dimension is unused. **As of 1.5.0 (LDM) we aggregate per-interface → per-pod** (`metricstransform/aggregate_container_network_interfaces`), which canonical does **not** — so in LDM eBPF now sends **fewer** of these than canonical (25.4k → 4.6k dp/h; hostNetwork pods no longer fan out across ~17 host veths). LDM-off keeps per-interface (canonical parity). |
| `k8s.container.*_utilization` | **no** | UI queries the `k8s.pod.*_utilization` variants instead (both stacks send those) |
| `kube_pod_status_{scheduled,ready}_time` | **no** | confirmed droppable by the 2026-07-30 audit (not UI-queried, not an entity-synthesis key, not consumed by nri-kubernetes). Same for `kube_statefulset_persistentvolumeclaim_retention_policy`. Kept for now; ~4.5k dp/h total. |

The two unused families are kept deliberately for the nri-bundle comparison;
dropping them takes the residual to ~1.06×.

Everything else matches: **91 of 92** canonical families are present,
`container_network_*_errors_total` is dropped (always-zero), and scrape/`up`
meta is dropped. The one canonical-only family
(`go_sched_goroutines_not_in_go_goroutines`) is a partial-match artifact and
intentionally not copied.

## eBPF-only addition vs canonical: `k8s.persistent` on volume metrics (1.6.0)

Canonical's kubeletstats sends volume metrics with only `k8s.volume.name` — no
`k8s.volume.type`, no `k8s.persistent`. NR's node-overview volume table filters
`WHERE k8s.persistent='true'`, so it's **empty for all canonical OTel too**, not
just us.

1.6.0 adds, on volume metrics only: kubeletstats `extra_metadata_labels:
[container.id, k8s.volume.type]` + `k8s_api_config: {auth_type: serviceAccount}`,
then `transform/set_volume_persistent` derives `k8s.persistent` from
`k8s.volume.type == "persistentVolumeClaim"` (mirrors nri's `PVCRef != nil`).
This puts eBPF **slightly ahead** of canonical (a small ingest add: two attrs on
~40 volumes × ~8 metrics, negligible — a constant/low-cardinality envelope that
compresses). Validated live 2026-07-30: `k8s.persistent` + `k8s.volume.type`
(emptyDir/configMap/secret) now populate; table stays empty here only because the
test cluster has zero PVCs.

## Why metric-drops can't close the residual (2026-07-30 audit)

An exhaustive audit (60 `kube_*`, the kubeletstats×cadvisor container double-scrape,
apiserver, the attribute envelope) found the parity-safe reducible set is **~1%**
of ingest: only 3 `kube_*` metrics (~4.5k dp/h) are droppable; everything else is
UI-queried, an entity-synthesis key, or information nri-bundle also emits (so a
migrating customer may query it). Envelope trimming is cheap (NRDB compresses the
repeated identity). **The residual is the structural cost of the dimensional model,
not removable waste — the only material lever is the interval (§1).**

## In one line

`eBPF k8s ingest = canonical × 2 (interval) × 1.17 (four extra families)`, plus
a separate ~0.3 GB/day of host metrics that canonical doesn't collect at all.
