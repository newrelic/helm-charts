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
