{{- /* Defines if the deployment config map has to be created or not */ -}}
{{- define "nrKubernetesOtel.deployment.configMap.config" -}}

{{- /* Look for a local creation of a deployment config map */ -}}
{{- if get .Values.deployment "configMap" | kindIs "map" -}}
    {{- if .Values.deployment.configMap.config -}}
        {{- toYaml .Values.deployment.configMap.config -}}
    {{- end -}}
{{- end -}}
{{- end -}}
