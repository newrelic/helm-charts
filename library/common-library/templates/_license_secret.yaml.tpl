{{/*
Renders the license key secret if user has not specified a custom secret.
*/}}
{{- define "newrelic.common.license.secret" }}
{{- if not (include "newrelic.common.license._customSecretName" .) }}
{{- /* Fail if licenseKey is empty and required: */ -}}
{{- if not (include "newrelic.common.license._licenseKey" .) }}
    {{- fail "You must specify a licenseKey or a customSecretName containing it" }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "newrelic.common.license.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  {{ include "newrelic.common.license.secretKeyName" . }}: {{ include "newrelic.common.license._licenseKey" . | b64enc }}
{{- end }}
{{- end }}
