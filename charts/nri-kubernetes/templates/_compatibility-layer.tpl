{{- if .Values.compatibilityLayer }}
{{ fail "Compatibility Layer is still a work in progress and will not be properly configured and tested until we release the version 3" }}
{{- end -}}
