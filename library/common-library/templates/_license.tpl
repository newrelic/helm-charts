{{/*
Return the name of the secret holding the License Key.
*/}}
{{- define "common.license.secretName" -}}
{{ include "common.license._customSecretName" . | default (printf "%s-license" (include "common.naming.fullname" . )) }}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret.
*/}}
{{- define "common.license.secretKeyName" -}}
{{ include "common.license._customSecretKey" . | default "licenseKey" }}
{{- end -}}

{{/*
Return local licenseKey if set, global otherwise.
This helper is for internal use.
*/}}
{{- define "common.license._licenseKey" -}}
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
{{- define "common.license._customSecretName" -}}
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
{{- define "common.license._customSecretKey" -}}
{{- if .Values.customSecretLicenseKey -}}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
