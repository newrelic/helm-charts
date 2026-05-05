{{- /*
Abstraction of the lowDataMode toggle.
This helper allows to override the global `.global.lowDataMode` with the value of `.lowDataMode`.
Returns "true" if `lowDataMode` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "newrelic.common.lowDataMode" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "lowDataMode" | kindIs "bool") -}}
    {{- if .Values.lowDataMode -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "newrelic.common.lowDataMode" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.lowDataMode -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "lowDataMode" | kindIs "bool" -}}
    {{- if $global.lowDataMode -}}
        {{- $global.lowDataMode -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
