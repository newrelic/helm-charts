{{- /*
A helper to return the affinity to apply to the ebpf daemonset.
*/ -}}
{{- define "nrEbpfAgent.ebpfAgent.affinity" -}}
{{- if .Values.ebpfAgent.affinity -}}
    {{- toYaml .Values.ebpfAgent.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
    {{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the affinity to apply to the Otel daemonset.
*/ -}}
{{- define "nrEbpfAgent.otelCollector.affinity" -}}
{{- if .Values.otelCollector.affinity -}}
    {{- toYaml .Values.otelCollector.affinity -}}
{{- else if include "newrelic.common.affinity" . -}}
    {{- include "newrelic.common.affinity" . -}}
{{- end -}}
{{- end -}}
{{- /*
Affinity for the control-plane DaemonSet: nrdotCollector.controlPlane.affinity, else
control-plane nodes only (same labels as nri-bundle's control-plane DaemonSet; the API
server warns on the deprecated node-role.kubernetes.io/master). Independent of the eBPF
agent's affinity.
*/ -}}
{{- define "nrEbpfAgent.controlPlane.affinity" -}}
{{- if .Values.nrdotCollector.controlPlane.affinity -}}
    {{- toYaml .Values.nrdotCollector.controlPlane.affinity -}}
{{- else -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      {{- range list "node-role.kubernetes.io/control-plane" "node-role.kubernetes.io/controlplane" "node-role.kubernetes.io/etcd" }}
      - matchExpressions:
          - key: {{ . }}
            operator: Exists
      {{- end }}
{{- end -}}
{{- end -}}
