{{- /*
This helper detect if the user set a value for the LowDataMode toggle and use it or defaults to `true`.
*/ -}}
{{- define "nrKubernetesOtel.lowDataMode" -}}
{{- $userSetAValue := false -}}
{{- $lowDataMode := "" -}}

{{- $global := index .Values "global" | default dict -}}
{{- if get $global "lowDataMode" | kindIs "bool" -}}
    {{- $userSetAValue = true -}}
    {{- $lowDataMode = $global.lowDataMode -}}
{{- end -}}

{{- if (get .Values "lowDataMode" | kindIs "bool") -}}
    {{- $userSetAValue = true -}}
    {{- $lowDataMode = .Values.lowDataMode -}}
{{- end -}}

{{- if $userSetAValue -}}
    {{- if $lowDataMode -}}
        {{- $lowDataMode -}}
    {{- end -}}
{{- else -}}
    {{- /* This is the default we need for this chart */ -}}
    true
{{- end -}}
{{- end -}}
