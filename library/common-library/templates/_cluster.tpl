{{/*
Return the cluster
*/}}
{{- define "newrelic.common.cluster" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.cluster -}}
    {{- .Values.cluster -}}
{{- else if $global.cluster -}}
    {{- $global.cluster -}}
{{- else -}}
    {{ fail "There is not cluster name definition set neither in `.global.cluster' nor `.cluster' in your values.yaml. Cluster name is required." }}
{{- end -}}
{{- end -}}
