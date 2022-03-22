{{- /*
Abstraction of the hostNetwork toggle.
This helper allows to override the global `.global.hostNetwork` with the value of `.hostNetwork`.
Returns "true" if `hostNetwork` is enabled, otherwise fallbacks to a overridable function
*/ -}}
{{- define "common.hostNetwork" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}

{{- /*
`get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs

We also want only to return when this is true, returning `false` here will template "false" (string) when doing
an `(include "common.hostNetwork" .)`, which is not an "empty string" so it is `true` if it is used
as an evaluation somewhere else.
*/ -}}
{{- if get .Values "hostNetwork" | kindIs "bool" -}}
{{- if .Values.hostNetwork -}}
{{- .Values.hostNetwork -}}
{{- end -}}
{{- else if get $global "hostNetwork" | kindIs "bool" -}}
{{- if $global.hostNetwork -}}
{{- $global.hostNetwork -}}
{{- end -}}
{{- else -}}
{{- include "common.hostNetwork.defaultOverride" . -}}
{{- end -}}
{{- end -}}


{{- /*
Abstraction of the hostNetwork toggle.
This helper abstracts the function "common.hostNetwork" to return true or false directly.
*/ -}}
{{- define "common.hostNetwork.value" -}}
{{- if include "common.hostNetwork" . -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- /*
This allows to change the default of the helper `common.hostNetwork`. Defaults to false
*/ -}}
{{- define "common.hostNetwork.defaultOverride" -}}
{{- end -}}
