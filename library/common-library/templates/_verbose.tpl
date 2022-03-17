{{- /*
Abstraction of the verbose toggle.
This helper allows to override the global `.global.verbose` with the value of `.verbose`.
Returns "true" if `verbose` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "common.verbose" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "verbose" | kindIs "bool") -}}
    {{- if .Values.verbose -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "common.verbose" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.verbose -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "verbose" | kindIs "bool" -}}
    {{- if $global.verbose -}}
        {{- $global.verbose -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
