{{- define "deployment-collector.baseConfig" -}}
{{- $config := deepCopy .Values.deployment.configMap.config }}
{{- if tpl (include "newrelic.common.verboseLog" .) . }}
    {{- $_ := set $config "service" (dict "telemetry" (dict "logs" (dict "level" "debug"))) }}
{{- end }}
{{- if include "nrKubernetesOtel.lowDataMode" . | default "false" | eq "false" }}
    {{- $processors := get $config.service.pipelines.metrics "processors" | default list -}}
    {{- $filteredProcessors := list -}} 
    {{- range $processors }}
        {{- if not (or (eq . "metricstransform/ldm") (eq . "metricstransform/k8s_cluster_info_ldm") (eq . "metricstransform/ksm") (eq . "filter/exclude_metrics_low_data_mode") (eq . "transform/low_data_mode_inator") (eq . "resource/low_data_mode_inator")) }}
            {{- $filteredProcessors = append $filteredProcessors . -}}
        {{- end }}
    {{- end }}
    {{- $_ := set $config.service.pipelines.metrics "processors" $filteredProcessors -}}
    {{- $ksm := get $config.service.pipelines "metrics/ksm" | default dict -}}
    {{- $processors := get $ksm "processors" | default list -}}
    {{- $filteredProcessors := list -}}
    {{- range $processors }}
        {{- if not (or (eq . "k8s_cluster_info_ldm") (eq . "metricstransform/ldm") (eq . "metricstransform/k8s_cluster_info_ldm") (eq . "metricstransform/ksm") (eq . "filter/exclude_metrics_low_data_mode") (eq . "transform/low_data_mode_inator") (eq . "resource/low_data_mode_inator")) }}
            {{- $filteredProcessors = append $filteredProcessors . -}}
        {{- end }}
    {{- end }}
    {{- $_ := set $ksm "processors" $filteredProcessors -}}
    {{- $_ := set $config.service.pipelines "metrics/ksm" $ksm -}}
    {{- end }}
{{- $config | toYaml }}
{{- end }}
