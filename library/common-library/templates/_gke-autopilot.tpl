{{- /*
This helper allows to override the global `.global.gkeAutopilot` with the value of `.gkeAutopilot`.
Returns "true" if `gkeAutopilot` is enabled, otherwise "" (empty string)
# Source: ./_hostNetwork.tpl
*/ -}}
{{- define "newrelic.common.gkeAutopilot" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "gkeAutopilot" | kindIs "bool") -}}
    {{- if .Values.gkeAutopilot -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "newrelic.common.gkeAutopilot" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.gkeAutopilot -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "gkeAutopilot" | kindIs "bool" -}}
    {{- if $global.gkeAutopilot -}}
        {{- $global.gkeAutopilot -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
