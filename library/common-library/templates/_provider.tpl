{{- $provider := .Values.provider | default .Values.global.provider -}}

{{/* If the user has set the provider config, it will take priority */}}
{{- if $provider -}}
  {{- if eq $provider "GKE_AUTOPILOT" -}}
    {{- define "newrelic.common.gkeAutopilot" -}}
      true
    {{- end -}}
    {{- define "newrelic.common.fargate" -}}
    {{- end -}}
    {{- define "newrelic.common.openshift" -}}
    {{- end -}}
  {{- else if eq $provider "FARGATE" -}}
    {{- define "newrelic.common.fargate" -}}
      true
    {{- end -}}
  {{- else if eq $provider "OPEN_SHIFT" -}}
    {{- define "newrelic.common.openshift" -}}
      true
    {{- end -}}
  {{- else -}}
  {{/* "Throws and error" if they have set provider, and it is not a valid value */}}
    {{- fail "provider must be one of: [GKE_AUTOPILOT, FARGATE, OPEN_SHIFT]" }}
  {{- end -}}
{{- else -}}
{{/* Backwards compatibility for charts that have already have fargate: <bool>, etc... in their charts */}}
  {{- if .Values.gkeAutopilot -}}
    {{- define "newrelic.common.gkeAutopilot" -}}
      true
    {{- end -}}
  {{- else if .Values.fargate -}}
    {{- define "newrelic.common.fargate" -}}
      true
    {{- end -}}
  {{- else if .Values.openShift -}}
    {{- define "newrelic.common.openShift" -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

