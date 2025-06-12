{{- define "newrelic.common.provider" -}}
  {{- $provider := .Values.provider -}}
  {{- if and (not $provider) .Values.global -}}
    {{- $provider = .Values.global.provider -}}
  {{- end -}}

  {{- if $provider -}}
    {{if contains $provider  "[GKE_AUTOPILOT, FARGATE, OPEN_SHIFT]" }}
      {{- $provider -}}
    {{else}}
      {{- fail "provider must be one of: [GKE_AUTOPILOT, FARGATE, OPEN_SHIFT]" }}
    {{- end -}}
  {{- end -}}

  {{- if or (and .Values.gkeAutopilot (or .Values.openShift .Values.fargate)) (and .Values.openShift .Values.fargate) -}}
  {{- fail "Multiple Kubernetes providers enabled. Please only select one gkeAutopilot:<bool>, openShift:<bool>, fargate:<bool>." -}}
  {{- end -}}
{{- end -}}


{{- define "newrelic.common.gkeAutopilot" -}}
{{- $provider := include "newrelic.common.provider" . -}}
  {{- if and $provider (eq $provider "GKE_AUTOPILOT") -}}
    true

  {{/* For backwards compatibility only, that is why we do not check global here. */}}
  {{else if and (not $provider) .Values.gkeAutopilot}}
    true
  {{- end -}}

{{- end -}}

{{- define "newrelic.common.openShift" -}}
{{- $provider := include "newrelic.common.provider" . -}}
  {{- if and $provider (eq $provider "OPEN_SHIFT") -}}
    true

  {{/* For backwards compatibility only, that is why we do not check global here. */}}
  {{else if and (not $provider) .Values.openShift}}
    true
  {{- end -}}

{{- end -}}

{{- define "newrelic.common.fargate" -}}
{{- $provider := include "newrelic.common.provider" . -}}
  {{- if eq $provider "FARGATE" -}}
    true

  {{/* For backwards compatibility only, that is why we do not check global here. */}}
  {{else if and (not $provider) .Values.fargate}}
    true
  {{- end -}}

{{- end -}}
