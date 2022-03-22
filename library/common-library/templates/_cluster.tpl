{{/*
Return the cluster
*/}}
{{- define "common.cluster" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}

{{- if .Values.cluster -}}
    {{- .Values.cluster -}}
{{- else if $global.cluster -}}
    {{- $global.cluster -}}
{{- else if (include "common.cluster.failIfEmpty" . ) -}}
    {{ fail "There is not cluster name definition set neither in `.global.cluster' nor `.cluster' in your values.yaml. Cluster name is required." }}
{{- end -}}
{{- end -}}



{{/*
Return the default behaviour if "common.cluster" helper does not find one in the values
*/}}
{{- define "common.cluster.failIfEmpty" -}}
true
{{- end -}}
