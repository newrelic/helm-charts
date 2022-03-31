{{/*
This function allows easily to overwrite custom attributes to the function "common.customAttributes"
*/}}
{{- define "common.customAttributes.overrideAttributes" -}}
{{- end }}



{{/*
This will render custom attributes as a YAML ready to  be templated or be used with `fromYaml`.
Chart writers can override `common.customAttributes.overrideAttributes`, which will be included in the output of this helper.
*/}}
{{- define "common.customAttributes" -}}
{{- $customAttributes := dict -}}

{{- $global := index .Values "global" | default dict -}}
{{- if $global.customAttributes -}}
{{- $customAttributes = mergeOverwrite $customAttributes $global.customAttributes -}}
{{- end -}}

{{- if .Values.customAttributes -}}
{{- $customAttributes = mergeOverwrite $customAttributes .Values.customAttributes -}}
{{- end -}}

{{- if include "common.customAttributes.overrideAttributes" . -}}
{{- $customAttributes = mustMergeOverwrite $customAttributes (fromYaml (include "common.customAttributes.overrideAttributes" . )) -}}
{{- end -}}

{{- toYaml $customAttributes -}}
{{- end -}}
