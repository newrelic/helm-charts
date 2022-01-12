{{/* Returns whether the controlPlane component needs needsHostNetwork to work, that is, if they do not have a staticEndpoint configured */}}
{{- define "newrelic.controlPlane.hostNetwork" -}}
{{- if .Values.privileged -}}
true
{{- else if .Values.controlPlane.unprivilegedHostNetwork -}}
true
{{- end -}}
{{- end -}}
