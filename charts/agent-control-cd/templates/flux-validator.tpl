{{- if .Values.flux2.enabled -}}
  {{- if not .Values.flux2.sourceController.create -}}
    {{- fail "sourceController.create cannot be disabled when flux is enabled" -}}
  {{- end -}}

  {{- if not .Values.flux2.helmController.create -}}
    {{- fail "helmController.create cannot be disabled when flux is enabled" -}}
  {{- end -}}
{{- end -}}
