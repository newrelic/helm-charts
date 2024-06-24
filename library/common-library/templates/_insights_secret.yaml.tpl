{{/*
Renders the insights key secret if user has not specified a custom secret.
*/}}
{{- define "newrelic.common.insightsKey.secret" }}
{{- if not (include "newrelic.common.insightsKey._customSecretName" .) }}
{{- /* Fail if licenseKey is empty and required: */ -}}
{{- if not (include "newrelic.common.insightsKey._licenseKey" .) }}
    {{- fail "You must specify a insightsKey or a customInsightsSecretName containing it" }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "newrelic.common.insightsKey.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  {{ include "newrelic.common.insightsKey.secretKeyName" . }}: {{ include "newrelic.common.insightsKey._licenseKey" . | b64enc }}
{{- end }}
{{- end }}
