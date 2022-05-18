{{- /* Defines the Pod affinity */ -}}
{{- define "newrelic.common.affinity" -}}
    {{- if .Values.affinity -}}
        {{- toYaml .Values.affinity -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.affinity -}}
            {{- toYaml .Values.global.affinity -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
