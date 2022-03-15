{{/*
Return the cluster
*/}}
{{- define "common.cluster" -}}
    {{- if .Values.cluster -}}
        {{- .Values.cluster -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.cluster -}}
            {{- .Values.global.cluster -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

