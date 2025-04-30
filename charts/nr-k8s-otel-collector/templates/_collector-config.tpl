{{- define "deployment-receivers" }}
{{- .Values.otel.receivers.deployment | toYaml }}
{{- end }}

{{- define "deployment-processors" }}
{{- .Values.otel.processors.deployment | toYaml }}
{{- end }}

{{- define "deployment-pipelines" }}
{{- $pipelines := deepCopy .Values.otel.pipelines.deployment }}
{{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}
  {{- /* Process metrics/nr_ksm pipeline */}}
  {{- if hasKey $pipelines "metrics/nr_ksm" }}
    {{- $nr_ksm := get $pipelines "metrics/nr_ksm" | default dict -}}
    {{- $ksmProcessors := get $nr_ksm "processors" | default list -}}
    {{- $ksmFiltered := list -}}

    {{- range $ksmProcessors }}
      {{- if not (or
        (eq . "metricstransform/ldm")
        (eq . "metricstransform/k8s_cluster_info_ldm")
        (eq . "metricstransform/ksm")
        (eq . "filter/exclude_metrics_low_data_mode")
        (eq . "transform/low_data_mode_inator")
        (eq . "resource/low_data_mode_inator")) }}
        {{- $ksmFiltered = append $ksmFiltered . }}
      {{- end }}
    {{- end }}
    {{- $_ := set $nr_ksm "processors" $ksmFiltered -}}
    {{- $_ := set $pipelines "metrics/nr_ksm" $nr_ksm -}}
  {{- end }}

  {{- /* Process metrics/nr_controlplane pipeline */}}
  {{- if hasKey $pipelines "metrics/nr_controlplane" }}
    {{- $nr_cp := get $pipelines "metrics/nr_controlplane" | default dict -}}
    {{- $cpProcessors := get $nr_cp
         "processors" | default list -}}
    {{- $cpFiltered := list -}}
    {{- range $cpProcessors }}
      {{- if not (or
        (eq . "metricstransform/ldm")
        (eq . "metricstransform/k8s_cluster_info_ldm")
        (eq . "metricstransform/apiserver")
        (eq . "filter/exclude_metrics_low_data_mode")
        (eq . "transform/low_data_mode_inator")
        (eq . "resource/low_data_mode_inator")) }}
        {{- $cpFiltered = append $cpFiltered . }}
      {{- end }}
    {{- end }}
    {{- $_ := set $nr_cp "processors" $cpFiltered -}}
    {{- $_ := set $pipelines "metrics/nr_controlplane" $nr_cp -}}
  {{- end }}
{{- end }}
{{- $pipelines | toYaml }}
{{- end }}

{{- define "deployment-connector" }}
{{- .Values.otel.connectors.deployment | toYaml }}
{{- end }}



{{- define "daemonset-receivers" }}
{{- .Values.otel.receivers.daemonset | toYaml }}
{{- end }}

{{- define "daemonset-processors" }}
{{- .Values.otel.processors.daemonset | toYaml }}
{{- end }}

{{- define "daemonset-pipelines" }}
{{- .Values.otel.pipelines.daemonset | toYaml }}
{{- end }}

{{- define "daemonset-connector" }}
{{- .Values.otel.connectors.daemonset | toYaml }}
{{- end }}



{{- define "shared-processors" }}
{{- .Values.otel.processors.shared | toYaml }}
{{- end }}

{{- define "shared-exporters" }}
{{- .Values.otel.exporters.shared | toYaml }}
{{- end }}
