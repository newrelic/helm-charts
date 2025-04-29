{{- define "deployment-collector.baseConfig" -}}
{{- $config := deepCopy .Values.deployment.configMap.config }}
{{- if include "newrelic.common.verboseLog" . | eq "true" }}
    {{- $_ := set $config "service" (dict "telemetry" (dict "logs" (dict "level" "debug"))) }}
{{- end }}
{{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}    
    {{- /* Process for metrics/nr_ksm pipeline */ -}}
    {{- $nr_ksm := get $config.service.pipelines "metrics/nr_ksm" | default dict -}}
    {{- $processors := get $nr_ksm "processors" | default list -}}
    {{- $filteredProcessors := list -}}
    {{- range $processors }}
        {{- if not (or 
            (eq . "metricstransform/ldm") 
            (eq . "metricstransform/k8s_cluster_info_ldm") 
            (eq . "metricstransform/ksm") 
            (eq . "filter/exclude_metrics_low_data_mode") 
            (eq . "transform/low_data_mode_inator") 
            (eq . "resource/low_data_mode_inator")) }}
            {{- $filteredProcessors = append $filteredProcessors . -}}
        {{- end }}
    {{- end }}
    {{- $_ := set $nr_ksm "processors" $filteredProcessors -}}
    {{- $_ := set $config.service.pipelines "metrics/nr_ksm" $nr_ksm -}}
    
    {{- /* Process for metrics/nr_controlplane pipeline */ -}}
    {{- $nr_controlplane := get $config.service.pipelines "metrics/nr_controlplane" | default dict -}}
    {{- $processors := get $nr_controlplane "processors" | default list -}}
    {{- $filteredProcessors := list -}}
    {{- range $processors }}
        {{- if not (or 
            (eq . "metricstransform/ldm") 
            (eq . "metricstransform/k8s_cluster_info_ldm") 
            (eq . "metricstransform/apiserver") 
            (eq . "filter/exclude_metrics_low_data_mode") 
            (eq . "transform/low_data_mode_inator") 
            (eq . "resource/low_data_mode_inator")) }}
            {{- $filteredProcessors = append $filteredProcessors . -}}
        {{- end }}
    {{- end }}
    {{- $_ := set $nr_controlplane "processors" $filteredProcessors -}}
    {{- $_ := set $config.service.pipelines "metrics/nr_controlplane" $nr_controlplane -}}
{{- end }}
{{- /* Output the modified configuration */ -}}
{{- $config | toYaml }}
{{- end }}


{{- define "daemonset-collector.baseConfig" -}}
{{- $config := deepCopy .Values.daemonset.configMap.config }}
{{- if include "newrelic.common.verboseLog" . | eq "true" }}
    {{- $_ := set $config "service" (dict "telemetry" (dict "logs" (dict "level" "debug"))) }}
{{- end }}

{{- if .Values.gkeAutopilot | default false | eq false }}
    {{- /* Process for non-gkeAutopilot environments */ -}}
    {{- $hostmetrics_conf := $config.receivers.hostmetrics | default dict -}}
    {{- if $hostmetrics_conf.root_path }}
        {{- $_ := set $config.receivers.hostmetrics "root_path" $hostmetrics_conf.root_path }}
    {{- end }}
    {{- $kubeletstats_conf := $config.receivers.kubeletstats | default dict -}}
    {{- $_ := set $config.receivers.kubeletstats "endpoint" "${KUBE_NODE_NAME}:10250" }}
    {{- $_ := set $config.receivers.kubeletstats "auth_type" "serviceAccount" }}
    {{- $_ := set $config.receivers.kubeletstats "insecure_skip_verify" true }}
{{- else }}
    {{- /* Process for gkeAutopilot environments */ -}}
    {{- $hostmetrics_conf := $config.receivers.hostmetrics | default dict -}}
    {{- /* In GKE Autopilot, we omit the root_path */ -}}
    {{- $_ := unset $config.receivers.hostmetrics "root_path" }}
    {{- $kubeletstats_conf := $config.receivers.kubeletstats | default dict -}}
    {{- $_ := set $config.receivers.kubeletstats "endpoint" "${KUBE_NODE_NAME}:10255" }}
    {{- $_ := set $config.receivers.kubeletstats "auth_type" "none" }}
{{- end }}

{{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}
    {{- /* Process for metrics/nr pipeline */ -}}
    {{- $nr_metrics := get $config.service.pipelines "metrics/nr" | default dict -}}
    {{- $processors := get $nr_metrics "processors" | default list -}}
    {{- $filteredProcessors := list -}}
    {{- range $processors }}
        {{- if not (or
            (eq . "metricstransform/ldm")
            (eq . "metricstransform/kubeletstats")
            (eq . "metricstransform/cadvisor")
            (eq . "metricstransform/kubelet")
            (eq . "metricstransform/hostmetrics")
            (eq . "filter/exclude_metrics_low_data_mode")
            (eq . "transform/low_data_mode_inator")
            (eq . "resource/low_data_mode_inator")) }}
            {{- $filteredProcessors = append $filteredProcessors . -}}
        {{- end }}
    {{- end }}
    {{- $_ := set $nr_metrics "processors" $filteredProcessors -}}
    {{- $_ := set $config.service.pipelines "metrics/nr" $nr_metrics -}}
{{- end }}
{{- /* Output the modified configuration */ -}}
{{- $config | toYaml }}
{{- end }}