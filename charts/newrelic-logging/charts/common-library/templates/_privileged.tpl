{{- /*
This is a helper that returns whether the chart should assume the user is fine deploying privileged pods.
*/ -}}
{{- define "newrelic.common.privileged" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists. */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if get .Values "privileged" | kindIs "bool" -}}
    {{- if .Values.privileged -}}
        {{- .Values.privileged -}}
    {{- end -}}
{{- else if get $global "privileged" | kindIs "bool" -}}
    {{- if $global.privileged -}}
        {{- $global.privileged -}}
    {{- end -}}
{{- end -}}
{{- end -}}



{{- /* Return directly "true" or "false" based in the exist of "newrelic.common.privileged" */ -}}
{{- define "newrelic.common.privileged.value" -}}
{{- if include "newrelic.common.privileged" . -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
