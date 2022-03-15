{{/*
Renders the license key secret if user has not specified a custom secret.
*/}}
{{- define "common.license.secret" }}
{{- if not (include "common.license._customSecretName" .) }}
{{- /* Fail if licenseKey is empty and required: */ -}}
{{- if not (include "common.license._licenseKey" .) }}
    {{- if not (include "common.license.overrides.allowEmpty" .) }}
    {{- fail "You must specify a licenseKey or a customSecretName containing it" }}
    {{- end }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common.license.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
data:
  {{ include "common.license.secretKeyName" . }}: {{ include "common.license._licenseKey" . | b64enc }}
{{- end }}
{{- end }}
