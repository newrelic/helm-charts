{{/*
Resolve the effective lowDataMode setting. Checks (in order):
1. .Values.nrdotCollector.lowDataMode (chart-local override)
2. .Values.global.lowDataMode (global umbrella override)
3. Default: true

Returns "true" or "" (falsy).
*/}}
{{- define "nr-ebpf-agent.lowDataMode" -}}
{{- $ldm := true -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "lowDataMode" | kindIs "bool" -}}
  {{- $ldm = $global.lowDataMode -}}
{{- end -}}
{{- if hasKey .Values.nrdotCollector "lowDataMode" -}}
  {{- if kindIs "bool" .Values.nrdotCollector.lowDataMode -}}
    {{- $ldm = .Values.nrdotCollector.lowDataMode -}}
  {{- end -}}
{{- end -}}
{{- if $ldm -}}true{{- end -}}
{{- end -}}
