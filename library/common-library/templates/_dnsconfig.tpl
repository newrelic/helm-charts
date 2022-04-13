{{- /* Defines the Pod dnsConfig */ -}}
{{- define "newrelic.common.dnsConfig" -}}
    {{- if .Values.dnsConfig -}}
        {{- toYaml .Values.dnsConfig -}}
    {{- else if .Values.global -}}
        {{- if .Values.global.dnsConfig -}}
            {{- toYaml .Values.global.dnsConfig -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
