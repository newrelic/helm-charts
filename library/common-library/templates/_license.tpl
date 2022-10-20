{{/*
Return the name of the secret holding the License Key.
*/}}
{{- define "newrelic.common.license.secretName" -}}
{{ include "newrelic.common.license._customSecretName" . | default (printf "%s-license" (include "newrelic.common.naming.fullname" . )) }}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret.
*/}}
{{- define "newrelic.common.license.secretKeyName" -}}
{{ include "newrelic.common.license._customSecretKey" . | default "licenseKey" }}
{{- end -}}

{{/*
Return local licenseKey if set, global otherwise.
This helper is for internal use.
*/}}
{{- define "newrelic.common.license._licenseKey" -}}
{{- if .Values.licenseKey -}}
  {{- .Values.licenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.licenseKey -}}
    {{- .Values.global.licenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key.
This helper is for internal use.
*/}}
{{- define "newrelic.common.license._customSecretName" -}}
{{- if .Values.customSecretName -}}
  {{- .Values.customSecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretName -}}
    {{- .Values.global.customSecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret.
This helper is for internal use.
*/}}
{{- define "newrelic.common.license._customSecretKey" -}}
{{- if .Values.customSecretLicenseKey -}}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
