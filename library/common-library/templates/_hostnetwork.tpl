{{- /*
Abstraction of the hostNetwork toggle.
This helper allows to override the global `.global.hostNetwork` with the value of `.hostNetwork`.
Returns "true" if `hostNetwork` is enabled, otherwise fallbacks to a overridable function
*/ -}}
{{- define "common.hostNetwork" -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}

{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if get .Values "hostNetwork" | kindIs "bool" -}}
    {{- if .Values.hostNetwork -}}
        true
    {{- else -}}
        false
    {{- end -}}
{{- else if get $global "hostNetwork" | kindIs "bool" -}}
    {{- if $global.hostNetwork -}}
        true
    {{- else -}}
        false
    {{- end -}}
{{- else -}}
    {{- include "common.hostNetwork.defaultOverride" . -}}
{{- end -}}
{{- end -}}


{{- /*
This allows to change the default of the helper `common.hostNetwork`. Defaults to empty string: "" (Helm falsiness)
*/ -}}
{{- define "common.hostNetwork.defaultOverride" -}}
false
{{- end -}}
