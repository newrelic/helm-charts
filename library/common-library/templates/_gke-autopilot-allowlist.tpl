{{- /*
Abstraction of the gkeAutopilotAllowlist toggle.
This helper allows to override the global `.global.gkeAutopilotAllowlist` with the value of `.gkeAutopilotAllowlist`.
Returns "true" if `gkeAutopilotAllowlist` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "newrelic.common.gkeAutopilotAllowlist" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "gkeAutopilotAllowlist" | kindIs "bool") -}}
    {{- if .Values.gkeAutopilotAllowlist -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "newrelic.common.gkeAutopilotAllowlist" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.gkeAutopilotAllowlist -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "gkeAutopilotAllowlist" | kindIs "bool" -}}
    {{- if $global.gkeAutopilotAllowlist -}}
        {{- $global.gkeAutopilotAllowlist -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
