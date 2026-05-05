{{/*
Return the name of the secret holding the Insights Key.
*/}}
{{- define "newrelic.common.insightsKey.secretName" -}}
{{- $default := include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "insightskey" ) -}}
{{- include "newrelic.common.insightsKey._customSecretName" . | default $default -}}
{{- end -}}

{{/*
Return the name key for the Insights Key inside the secret.
*/}}
{{- define "newrelic.common.insightsKey.secretKeyName" -}}
{{- include "newrelic.common.insightsKey._customSecretKey" . | default "insightsKey" -}}
{{- end -}}

{{/*
Return local insightsKey if set, global otherwise.
This helper is for internal use.
*/}}
{{- define "newrelic.common.insightsKey._licenseKey" -}}
{{- if .Values.insightsKey -}}
  {{- .Values.insightsKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.insightsKey -}}
    {{- .Values.global.insightsKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the Insights Key.
This helper is for internal use.
*/}}
{{- define "newrelic.common.insightsKey._customSecretName" -}}
{{- if .Values.customInsightsKeySecretName -}}
  {{- .Values.customInsightsKeySecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customInsightsKeySecretName -}}
    {{- .Values.global.customInsightsKeySecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the Insights Key inside the secret.
This helper is for internal use.
*/}}
{{- define "newrelic.common.insightsKey._customSecretKey" -}}
{{- if .Values.customInsightsKeySecretKey -}}
  {{- .Values.customInsightsKeySecretKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customInsightsKeySecretKey }}
    {{- .Values.global.customInsightsKeySecretKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
