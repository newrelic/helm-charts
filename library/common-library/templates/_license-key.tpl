{{/*
Return the licenseKey
*/}}
{{- define "common.licenseKey" -}}
    {{- if .Values.licenseKey -}}
        {{- .Values.licenseKey -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.licenseKey -}}
            {{- .Values.global.licenseKey -}}
        {{- end -}}
    {{- end -}}
{{- end -}}