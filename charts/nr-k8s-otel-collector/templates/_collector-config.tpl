{{- define "deployment-receivers" }}
{{- if .Values.otel }}
  {{- if .Values.otel.receivers }}
    {{- if get .Values.otel.receivers "deployment" | kindIs "map" -}}
      {{- .Values.otel.receivers.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "deployment-processors" }}
{{- if .Values.otel }}
  {{- if .Values.otel.processors }}
    {{- if get .Values.otel.processors "deployment" | kindIs "map" -}}
      {{- .Values.otel.processors.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "deployment-pipelines" }}
{{- if .Values.otel }}
  {{- if .Values.otel.pipelines }}
    {{- $pipelines := deepCopy (.Values.otel.pipelines.deployment | default (dict)) }}
    {{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}
      {{- /* Process metrics/nr_ksm pipeline */}}
      {{- if hasKey $pipelines "metrics/nr_ksm" }}
        {{- $nr_ksm := get $pipelines "metrics/nr_ksm" | default dict -}}
        {{- $ksmProcessors := get $nr_ksm "processors" | default list -}}
        {{- $ksmFiltered := list -}}
        {{- range $ksmProcessors }}
          {{- if not (or (eq . "metricstransform/ldm") (eq . "metricstransform/k8s_cluster_info_ldm") (eq . "metricstransform/ksm") (eq . "filter/exclude_metrics_low_data_mode") (eq . "transform/low_data_mode_inator") (eq . "resource/low_data_mode_inator")) }}{{- $ksmFiltered = append $ksmFiltered . }}{{- end }}
        {{- end }}
        {{- $_ := set $nr_ksm "processors" $ksmFiltered -}}
        {{- $_ := set $pipelines "metrics/nr_ksm" $nr_ksm -}}
      {{- end }}

      {{- /* Process metrics/nr_controlplane pipeline */}}
      {{- if hasKey $pipelines "metrics/nr_controlplane" }}
        {{- $nr_cp := get $pipelines "metrics/nr_controlplane" | default dict -}}
        {{- $cpProcessors := get $nr_cp "processors" | default list -}}
        {{- $cpFiltered := list -}}
        {{- range $cpProcessors }}
          {{- if not (or (eq . "metricstransform/ldm") (eq . "metricstransform/k8s_cluster_info_ldm") (eq . "metricstransform/apiserver") (eq . "filter/exclude_metrics_low_data_mode") (eq . "transform/low_data_mode_inator") (eq . "resource/low_data_mode_inator")) }}{{- $cpFiltered = append $cpFiltered . }}{{- end }}
        {{- end }}
        {{- $_ := set $nr_cp "processors" $cpFiltered -}}
        {{- $_ := set $pipelines "metrics/nr_controlplane" $nr_cp -}}
      {{- end }}
    {{- end }}
    {{- $pipelines | toYaml }}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "deployment-connector" }}
{{- if .Values.otel }}
  {{- if .Values.otel.connectors }}
    {{- if get .Values.otel.connectors "deployment" | kindIs "map" -}}
      {{- .Values.otel.connectors.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "daemonset-receivers" }}
{{- if .Values.otel }}
  {{- if .Values.otel.receivers }}
    {{- $daemonsetReceivers := .Values.otel.receivers.daemonset | default (dict) | deepCopy }}

    {{- if .Values.gkeAutopilot | default false | eq false }}
      {{- /* Non-GKE Autopilot: set root_path if present, set kubeletstats for serviceAccount */}}
      {{- if get $daemonsetReceivers.hostmetrics "root_path" }}
        {{- $_ := set $daemonsetReceivers.hostmetrics "root_path" (get $daemonsetReceivers.hostmetrics "root_path") }}
      {{- end }}
      {{- $_ := set $daemonsetReceivers.kubeletstats "endpoint" "${KUBE_NODE_NAME}:10250" }}
      {{- $_ := set $daemonsetReceivers.kubeletstats "auth_type" "serviceAccount" }}
      {{- $_ := set $daemonsetReceivers.kubeletstats "insecure_skip_verify" true }}
    {{- else }}
      {{- /* GKE Autopilot: remove root_path, set kubeletstats for no auth */}}
      {{- $_ := unset $daemonsetReceivers.hostmetrics "root_path" }}
      {{- $_ := set $daemonsetReceivers.kubeletstats "endpoint" "${KUBE_NODE_NAME}:10255" }}
      {{- $_ := set $daemonsetReceivers.kubeletstats "auth_type" "none" }}
    {{- end }}
    {{- $daemonsetReceivers | toYaml }}
  {{- end -}}
{{- end -}}
{{- end }}


{{- define "daemonset-processors" }}
{{- if .Values.otel }}
  {{- if .Values.otel.processors }}
    {{- if get .Values.otel.processors "daemonset" | kindIs "map" -}}
      {{- .Values.otel.processors.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "daemonset-pipelines" }}
{{- if .Values.otel }}
  {{- if .Values.otel.pipelines }}
    {{- $pipelines := deepCopy (.Values.otel.pipelines.daemonset | default (dict)) }}
    {{- /* Remove logs pipelines if GKE Autopilot is enabled */}}
    {{- if .Values.gkeAutopilot | default false }}
      {{- $_ := unset $pipelines "logs" }}
    {{- end }}
    {{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}
      {{- /* Process metrics/nr pipeline */}}
      {{- if hasKey $pipelines "metrics/nr" }}
        {{- $nr_metrics := get $pipelines "metrics/nr" | default dict -}}
        {{- $processors := get $nr_metrics "processors" | default list -}}
        {{- $filteredProcessors := list -}}

        {{- range $processors }}
          {{- if not (or (eq . "metricstransform/ldm") (eq . "metricstransform/kubeletstats") (eq . "metricstransform/cadvisor") (eq . "metricstransform/kubelet") (eq . "metricstransform/hostmetrics") (eq . "filter/exclude_metrics_low_data_mode") (eq . "transform/low_data_mode_inator") (eq . "resource/low_data_mode_inator")) }}{{- $filteredProcessors = append $filteredProcessors . }}{{- end }}
        {{- end }}
        {{- $_ := set $nr_metrics "processors" $filteredProcessors -}}
        {{- $_ := set $pipelines "metrics/nr" $nr_metrics -}}
      {{- end }}
    {{- end }}
    {{- $pipelines | toYaml }}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "daemonset-connector" }}
{{- if .Values.otel }}
  {{- if .Values.otel.connectors }}
    {{- if get .Values.otel.connectors "daemonset" | kindIs "map" -}}
      {{- .Values.otel.connectors.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}


{{- define "shared-processors" }}
{{- if .Values.otel }}
  {{- if .Values.otel.processors }}
    {{- if get .Values.otel.processors "shared" | kindIs "map" -}}
      {{- .Values.otel.processors.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "shared-exporters" }}
{{- if .Values.otel }}
  {{- if .Values.otel.exporters }}
    {{- if get .Values.otel.exporters "shared" | kindIs "map" -}}
      {{- .Values.otel.exporters.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}