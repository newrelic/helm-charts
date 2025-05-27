{{- define "agent-control.release.name" -}}
  {{- printf "%s-deployment" .Release.Name -}}
{{- end -}}

{{- define "agent-control.secret.name" -}}
  {{ include "agent-control.release.name" . }}
{{- end -}}
