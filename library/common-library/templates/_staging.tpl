{{- /*
Abstraction of the nrStaging toggle.
This helper allows to override the global `.global.nrStaging` with the value of `.nrStaging`.
Returns "true" if `nrStaging` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "common.nrStaging" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "nrStaging" | kindIs "bool") -}}
{{- if .Values.nrStaging -}}
{{- /*
We want only to return when this is true, returning `false` here will template "false" (string) when doing
an `(include "common.nrStaging" .)`, which is not an "empty string" so it is `true` if it is used
as an evaluation somewhere else.
*/ -}}
{{- .Values.nrStaging -}}
{{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "nrStaging" | kindIs "bool" -}}
{{- if $global.nrStaging -}}
{{- $global.nrStaging -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
