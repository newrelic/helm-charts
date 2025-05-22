{{- define "agent-control.release.name" -}}
  {{- printf "%s-deployment" .Release.Name -}}
{{- end -}}

{{- define "agent-control.secret.name" -}}
  {{- printf "%s-deployment" .Release.Name -}}
{{- end -}}
