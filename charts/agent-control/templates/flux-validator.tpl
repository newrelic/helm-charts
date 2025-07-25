{{- if index .Values "agent-control-cd" }}
{{- if (index .Values "agent-control-cd" "flux2").enabled -}}
  {{- if not (index .Values "agent-control-cd" "flux2").sourceController.create -}}
    {{- fail "sourceController.create cannot be disabled when flux is enabled" -}}
  {{- end -}}

  {{- if not (index .Values "agent-control-cd" "flux2").helmController.create -}}
    {{- fail "helmController.create cannot be disabled when flux is enabled" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
