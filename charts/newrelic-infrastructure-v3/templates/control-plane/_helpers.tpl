{{/* Returns whether the controlPlane scraper should run with hostNetwork: true based on the user configuration. */}}
{{- define "newrelic.controlPlane.hostNetwork" -}}
{{- if .Values.privileged -}}
true
{{- else if .Values.controlPlane.unprivilegedHostNetwork -}}
true
{{- end -}}
{{- end -}}
