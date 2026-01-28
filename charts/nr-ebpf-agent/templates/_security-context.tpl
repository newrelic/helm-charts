{{/*
Return pod security context - precedence: local (ebpfAgent.podSecurityContext) > global (global.podSecurityContext) > default (empty)
*/}}
{{- define "nrEbpfAgent.ebpfAgent.securityContext.pod" -}}
{{- if .Values.ebpfAgent.podSecurityContext }}
  {{- .Values.ebpfAgent.podSecurityContext | toYaml }}
{{- else if and .Values.global (hasKey .Values.global "podSecurityContext") .Values.global.podSecurityContext }}
  {{- .Values.global.podSecurityContext | toYaml }}
{{- end }}
{{- end -}}
