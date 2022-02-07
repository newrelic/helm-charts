{{/* Returns whether the controlPlane scraper should run with hostNetwork: true based on the user configuration. */}}
{{- define "newrelic.controlPlane.hostNetwork" -}}
{{- if eq .Values.controlPlane.kind "Daemonset" -}}
{{- if .Values.privileged -}}
true
{{- else if .Values.controlPlane.unprivilegedHostNetwork -}}
true
{{- end -}}
{{- end -}}
{{/* Error handling */}}
{{- if and (eq .Values.controlPlane.kind "Deployment") .Values.controlPlane.unprivilegedHostNetwork -}}
{{- fail ".controlPlane.unprivilegedHostNetwork is meant to be used with Daemonsets, not with Deployments" -}}
{{- end -}}
{{- end -}}
