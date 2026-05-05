{{- /* Defines the proxy */ -}}
{{- define "newrelic.common.proxy" -}}
    {{- if .Values.proxy -}}
        {{- .Values.proxy -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.proxy -}}
            {{- .Values.global.proxy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
