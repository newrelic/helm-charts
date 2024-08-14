{{/*
Return the name of the secret holding the API Key.
*/}}
{{- define "newrelic.common.apiKey.secretName" -}}
{{- $default := include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "apikey" ) -}}
{{- include "newrelic.common.apiKey._customSecretName" . | default $default -}}
{{- end -}}

{{/*
Return the name key for the API Key inside the secret.
*/}}
{{- define "newrelic.common.apiKey.secretKeyName" -}}
{{- include "newrelic.common.apiKey._customSecretKey" . | default "apiKey" -}}
{{- end -}}

{{/*
Return local API Key if set, global otherwise.
This helper is for internal use.
*/}}
{{- define "newrelic.common.apiKey._apiKey" -}}
{{- if .Values.apiKey -}}
  {{- .Values.apiKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.apiKey -}}
    {{- .Values.global.apiKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the API Key.
This helper is for internal use.
*/}}
{{- define "newrelic.common.apiKey._customSecretName" -}}
{{- if .Values.customAPIKeySecretName -}}
  {{- .Values.customAPIKeySecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customAPIKeySecretName -}}
    {{- .Values.global.customAPIKeySecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the API Key inside the secret.
This helper is for internal use.
*/}}
{{- define "newrelic.common.apiKey._customSecretKey" -}}
{{- if .Values.customAPIKeySecretKey -}}
  {{- .Values.customAPIKeySecretKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customAPIKeySecretKey }}
    {{- .Values.global.customAPIKeySecretKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
