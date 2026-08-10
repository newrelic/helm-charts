{{/*
Determine whether the bundled kube-state-metrics should be deployed.
Returns "true" or "" (falsy).

Modes:
  "always" -> always deploy
  "never"  -> never deploy
  "auto"   -> deploy only if no existing KSM Deployment is found cluster-wide
              (lookup is inert during `helm template`/`--dry-run`, so auto always
              renders in dry-run output — real install/upgrade detects correctly).
*/}}
{{- define "nr-ebpf-agent.ksm.shouldDeploy" -}}
{{- $mode := .Values.nrdotCollector.kubeStateMetrics.mode | default "auto" -}}
{{- if eq $mode "always" -}}
true
{{- else if eq $mode "never" -}}
{{- else }}
{{- /* mode == auto: use lookup to check for an existing KSM deployment */ -}}
{{- $existing := (lookup "apps/v1" "Deployment" "" "" ) -}}
{{- $found := false -}}
{{- if and $existing $existing.items -}}
  {{- range $existing.items -}}
    {{- $labels := .metadata.labels | default dict -}}
    {{- if eq (index $labels "app.kubernetes.io/name" | default "") "kube-state-metrics" -}}
      {{- $found = true -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if not $found }}true{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Emit the prometheus `relabel_configs` keep rules that select which KSM pod(s) the
cluster collector scrapes.

Why this exists: a `role: pod` scrape with only a name-based keep matches EVERY
kube-state-metrics pod on the cluster. When more than one KSM is present (this chart
alongside nri-bundle's KSM, or another otel collector that ships its own KSM), all of
them are scraped and every cluster-wide `kube_*` series is ingested once per KSM —
silent duplicate ingest (measured ~2x KSM datapoints).

  - When this chart deploys its OWN KSM, pin the scrape to that instance
    (app.kubernetes.io/instance=<release>) so a foreign KSM is never scraped.
  - Otherwise derive keep rules from `nrdotCollector.ksmSelector` (comma-separated
    `label=value` pairs). If the cluster has multiple external KSMs, set ksmSelector
    to a single instance (e.g. "app.kubernetes.io/instance=newrelic-bundle") to avoid
    double-scraping — each KSM exposes identical cluster-wide series.

Output is authored at column 0; callers apply `nindent`.
*/}}
{{- define "nr-ebpf-agent.ksm.relabelKeep" -}}
{{- if include "nr-ebpf-agent.ksm.shouldDeploy" . -}}
- source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
  regex: kube-state-metrics
  action: keep
- source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_instance]
  regex: {{ .Release.Name | quote }}
  action: keep
{{- else -}}
{{- $sel := .Values.nrdotCollector.ksmSelector | default "app.kubernetes.io/name=kube-state-metrics" -}}
{{- range $pair := splitList "," $sel }}
{{- $kv := splitList "=" (trim $pair) }}
{{- if eq (len $kv) 2 }}
- source_labels: [__meta_kubernetes_pod_label_{{ regexReplaceAll "[^a-zA-Z0-9_]" (index $kv 0) "_" }}]
  regex: {{ index $kv 1 | quote }}
  action: keep
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}
