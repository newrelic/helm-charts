{{/*
Return the name of the secret holding the API Key.
*/}}
{{- define "newrelic.common.userKey.secretName" -}}
{{- $default := include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "userkey" ) -}}
{{- include "newrelic.common.userKey._customSecretName" . | default $default -}}
{{- end -}}

{{/*
Return the name key for the API Key inside the secret.
*/}}
{{- define "newrelic.common.userKey.secretKeyName" -}}
{{- include "newrelic.common.userKey._customSecretKey" . | default "userKey" -}}
{{- end -}}

{{/*
Return local API Key if set, global otherwise.
This helper is for internal use.
*/}}
{{- define "newrelic.common.userKey._userKey" -}}
{{- if .Values.userKey -}}
  {{- .Values.userKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.userKey -}}
    {{- .Values.global.userKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the API Key.
This helper is for internal use.
*/}}
{{- define "newrelic.common.userKey._customSecretName" -}}
{{- if .Values.customUserKeySecretName -}}
  {{- .Values.customUserKeySecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customUserKeySecretName -}}
    {{- .Values.global.customUserKeySecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the API Key inside the secret.
This helper is for internal use.
*/}}
{{- define "newrelic.common.userKey._customSecretKey" -}}
{{- if .Values.customUserKeySecretKey -}}
  {{- .Values.customUserKeySecretKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customUserKeySecretKey }}
    {{- .Values.global.customUserKeySecretKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
