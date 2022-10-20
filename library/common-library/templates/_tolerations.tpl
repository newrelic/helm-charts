{{- /* Defines the Pod tolerations */ -}}
{{- define "newrelic.common.tolerations" -}}
    {{- if .Values.tolerations -}}
        {{- toYaml .Values.tolerations -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.tolerations -}}
            {{- toYaml .Values.global.tolerations -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
