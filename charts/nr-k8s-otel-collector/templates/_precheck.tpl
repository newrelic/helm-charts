{{- define "nrKubernetesOtel.limits.check" -}}
{{- if .Values.enableNodeUtilizationMetrics }}
{{- if .Values.daemonset.resources.limits }}
{{- fail "Resource limits must not be set for otel-collector-daemonset when enabling enableNodeUtilizationMetrics" }}
{{- end }}
{{- end }}
{{- end }}
