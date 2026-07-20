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
