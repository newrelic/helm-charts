{{- define "deployment-receivers" }}
  {{- if .Values.receivers }}
    {{- if get .Values.receivers "deployment" | kindIs "map" -}}
      {{- .Values.receivers.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "deployment-processors" }}
  {{- if .Values.processors }}
    {{- if get .Values.processors "deployment" | kindIs "map" -}}
      {{- .Values.processors.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "deployment-exporters" }}
  {{- if .Values.exporters }}
    {{- if get .Values.exporters "deployment" | kindIs "map" -}}
      {{- .Values.exporters.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "deployment-extensions" }}
  {{- if .Values.extensions }}
    {{- if get .Values.extensions "deployment" | kindIs "map" -}}
      {{- .Values.extensions.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "deployment-pipelines" }}
  {{- if .Values.pipelines }}
    {{- $pipelines := deepCopy (.Values.pipelines.deployment | default (dict)) }}
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
{{- end }}

{{- define "deployment-connector" }}
  {{- if .Values.connectors }}
    {{- if get .Values.connectors "deployment" | kindIs "map" -}}
      {{- .Values.connectors.deployment | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}


{{- define "daemonset-receivers" }}
  {{- if .Values.receivers }}
    {{- if get .Values.receivers "daemonset" | kindIs "map" -}}
      {{- $daemonsetReceivers := .Values.receivers.daemonset | default (dict) | deepCopy }}

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
  {{- if .Values.processors }}
    {{- if get .Values.processors "daemonset" | kindIs "map" -}}
      {{- .Values.processors.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "daemonset-exporters" }}
  {{- if .Values.exporters }}
    {{- if get .Values.exporters "daemonset" | kindIs "map" -}}
      {{- .Values.exporters.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "daemonset-extensions" }}
  {{- if .Values.extensions }}
    {{- if get .Values.extensions "daemonset" | kindIs "map" -}}
      {{- .Values.extensions.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "daemonset-pipelines" }}
  {{- if .Values.pipelines }}
    {{- $pipelines := deepCopy (.Values.pipelines.daemonset | default (dict)) }}
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
{{- end }}

{{- define "daemonset-connector" }}
  {{- if .Values.connectors }}
    {{- if get .Values.connectors "daemonset" | kindIs "map" -}}
      {{- .Values.connectors.daemonset | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}


{{- define "shared-receivers" }}
  {{- if .Values.receivers }}
    {{- if get .Values.receivers "shared" | kindIs "map" -}}
      {{- .Values.receivers.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "shared-processors" }}
  {{- if .Values.processors }}
    {{- if get .Values.processors "shared" | kindIs "map" -}}
      {{- .Values.processors.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "shared-connector" }}
  {{- if .Values.connector }}
    {{- if get .Values.connector "shared" | kindIs "map" -}}
      {{- .Values.connector.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "shared-exporters" }}
  {{- if .Values.exporters }}
    {{- if get .Values.exporters "shared" | kindIs "map" -}}
      {{- .Values.exporters.shared | toYaml }}
    {{- end -}}
  {{- end -}}
{{- end }}