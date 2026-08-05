{{/*
Determine whether the cluster collector should scrape the control plane
(kube-apiserver / controller-manager / scheduler). Returns "true" or "" (falsy).

Why: scraping kube-apiserver /metrics is expensive — the endpoint returns ~26k
series (~3.6 MB) with no server-side filtering, and the collector keeps ~6. The
prometheus receiver buffers the whole body and caches every dropped series, costing
~22 MB of collector heap. On managed control planes (EKS/GKE/AKS) this mirrors what
nri-bundle does: its control-plane DaemonSet only schedules on control-plane nodes
(nodeAffinity on node-role.kubernetes.io/control-plane|controlplane|etcd), so on a
managed cluster it never scrapes the control plane at all.

Modes (.Values.nrdotCollector.controlPlane.mode, default "auto"):
  "always" -> always scrape
  "never"  -> never scrape
  "auto"   -> scrape only if the cluster has control-plane nodes (labelled
              node-role.kubernetes.io/control-plane|controlplane|master|etcd).
              Managed control planes expose no such node -> no scrape.
              `lookup` is inert during `helm template`/client-side --dry-run
              (returns no nodes); in that case we preserve current behaviour
              (scrape) so rendered output is unchanged. A real install/upgrade
              (or --dry-run=server) performs the lookup and detects correctly.
*/}}
{{- define "nr-ebpf-agent.controlPlane.shouldScrape" -}}
{{- $cp := .Values.nrdotCollector.controlPlane | default dict -}}
{{- $mode := $cp.mode | default "auto" -}}
{{- if eq $mode "always" -}}
true
{{- else if eq $mode "never" -}}
{{- else -}}
{{- $nodes := (lookup "v1" "Node" "" "") -}}
{{- if and $nodes $nodes.items -}}
  {{- /* real cluster: scrape only if a control-plane node exists */ -}}
  {{- $found := false -}}
  {{- range $nodes.items -}}
    {{- $labels := .metadata.labels | default dict -}}
    {{- if or (hasKey $labels "node-role.kubernetes.io/control-plane") (hasKey $labels "node-role.kubernetes.io/controlplane") (hasKey $labels "node-role.kubernetes.io/master") (hasKey $labels "node-role.kubernetes.io/etcd") -}}
      {{- $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if $found }}true{{- end -}}
{{- else -}}
  {{- /* lookup inert (helm template / client dry-run): preserve current behaviour */ -}}
true
{{- end -}}
{{- end -}}
{{- end -}}
