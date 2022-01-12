{{/*
Returns true if .Values.ksm.enabled is true and the legacy disableKubeStateMetrics is not set
*/}}
{{- define "newrelic.compatibility.ksm.enabled" -}}
{{- if and .Values.ksm.enabled (not .Values.disableKubeStateMetrics) -}}
true
{{- end -}}
{{- end -}}

{{/*
Returns legacy ksm values
*/}}
{{- define "newrelic.compatibility.ksm.legacyData" -}}
enabled: true
{{- if .Values.kubeStateMetricsScheme }}
scheme: {{ .Values.kubeStateMetricsScheme }}
{{- end -}}
{{- if .Values.kubeStateMetricsPort }}
port: {{ .Values.kubeStateMetricsPort }}
{{- end -}}
{{- if .Values.kubeStateMetricsUrl }}
staticURL: {{ .Values.kubeStateMetricsUrl }}
{{- end -}}
{{- if .Values.kubeStateMetricsPodLabel }}
selector: {{ printf "%s=kube-state-metrics" .Values.kubeStateMetricsPodLabel }}
{{- end -}}
{{- if  .Values.kubeStateMetricsNamespace }}
namespace: {{ .Values.kubeStateMetricsNamespace}}
{{- end -}}
{{- end -}}

{{/*
Returns the new value if available, otherwise falling back on the legacy one
*/}}
{{- define "newrelic.compatibility.valueWithFallback" -}}
{{- if .supported }}
{{- toYaml .supported}}
{{- else if .legacy -}}
{{- toYaml .legacy}}
{{- end }}
{{- end -}}

{{/*
Returns a dictionary with legacy runAsUser config
*/}}
{{- define "newrelic.compatibility.securityContext" -}}
{{- if  .Values.runAsUser -}}
{{ dict "runAsUser" .Values.runAsUser | toYaml }}
{{- end -}}
{{- end -}}

{{/*
Returns agent configmap merged with legacy config and legacy eventQueueDepth config
*/}}
{{- define "newrelic.compatibility.agentConfig" -}}
{{ $config:= (include "newrelic.compatibility.valueWithFallback" (dict "legacy" .Values.config "supported" .Values.common.agentConfig ) | fromYaml )}}
{{- if .Values.eventQueueDepth -}}
{{- mustMergeOverwrite $config (dict "event_queue_depth" .Values.eventQueueDepth ) | toYaml }}
{{- else -}}
{{- $config | toYaml}}
{{- end -}}
{{- end -}}

{{/*
Returns legacy integrations_config configmap data
*/}}
{{- define "newrelic.compatibility.integrations" -}}
{{- if .Values.integrations_config -}}
{{- range .Values.integrations_config }}
{{ .name -}}: |-
  {{- toYaml .data | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}
