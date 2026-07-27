# Notes

After the parity work, this chart's nrdot collector sends the same Kubernetes
metrics as New Relic's canonical `nr-k8s-otel-collector`. Comparing raw ingest
still shows eBPF higher. Two reasons, both expected — subtract them first.

## 1. Scrape interval (2×)

eBPF nrdot scrapes every **30s**, canonical every **60s**. Same metrics, twice
as often → twice the datapoints. Normalize this out before comparing.

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
| `container_network_*_bytes_total` | **yes** | node & workload network tiles (queries `max … FACET pod`, so the per-interface dimension is unused) |
| `k8s.container.*_utilization` | **no** | UI queries the `k8s.pod.*_utilization` variants instead (both stacks send those) |
| `kube_pod_status_{scheduled,ready}_time` | **no** | not queried anywhere |

The two unused families are kept deliberately for the nri-bundle comparison;
dropping them takes the residual to ~1.06×.

Everything else matches: **91 of 92** canonical families are present,
`container_network_*_errors_total` is dropped (always-zero), and scrape/`up`
meta is dropped. The one canonical-only family
(`go_sched_goroutines_not_in_go_goroutines`) is a partial-match artifact and
intentionally not copied.

## In one line

`eBPF k8s ingest = canonical × 2 (interval) × 1.17 (four extra families)`, plus
a separate ~0.3 GB/day of host metrics that canonical doesn't collect at all.
