{{/*
Renders the API key secret if user has not specified a custom secret.
*/}}
{{- define "newrelic.common.apiKey.secret" }}
{{- if not (include "newrelic.common.apiKey._customSecretName" .) }}
{{- /* Fail if API Key is empty and required: */ -}}
{{- if not (include "newrelic.common.apiKey._apiKey" .) }}
    {{- fail "You must specify a apiKey or a customAPIKeySecretName containing it" }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "newrelic.common.apiKey.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  {{ include "newrelic.common.apiKey.secretKeyName" . }}: {{ include "newrelic.common.apiKey._apiKey" . | b64enc }}
{{- end }}
{{- end }}
