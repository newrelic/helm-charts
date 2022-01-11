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
Returns the new value if available, falling back on the legacy one
*/}}
{{- define "newrelic.compatibility.valueWithFallback" -}}
{{- if .supported }}
{{- toYaml .supported}}
{{- else if .legacy -}}
{{- toYaml .legacy}}
{{- end }}
{{- end -}}

{{/*
Returns securityContext merged with old runAsUser config
*/}}
{{- define "newrelic.compatibility.securityContext" -}}
{{- if  .Values.runAsUser -}}
{{- mustMergeOverwrite .Values.securityContext (dict "runAsUser" .Values.runAsUser ) | toYaml }}
{{- else -}}
{{- .Values.securityContext | toYaml }}
{{- end -}}
{{- end -}}

{{/*
Returns agent configmap merged with old eventQueueDepth config
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
Returns integration configmap data with legacy fallback
*/}}
{{- define "newrelic.compatibility.integrations" -}}
{{- if (include "newrelic.integrations" .) -}}
{{- include "newrelic.integrations" . -}}

{{- else if .Values.integrations -}}
{{- range $k, $v := .Values.integrations }}
{{ $k | trimSuffix ".yaml" | trimSuffix ".yml" }}.yaml: |-
    {{- tpl ($v | toYaml) $ | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}
