{{- /*
Abstraction of the verbose toggle.
This helper allows to override the global `.global.verboseLog` with the value of `.verboseLog`.
Returns "true" if `verbose` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "common.verboseLog" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "verboseLog" | kindIs "bool") -}}
    {{- if .Values.verboseLog -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "common.verboseLog" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.verboseLog -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "verboseLog" | kindIs "bool" -}}
    {{- if $global.verboseLog -}}
        {{- $global.verboseLog -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
