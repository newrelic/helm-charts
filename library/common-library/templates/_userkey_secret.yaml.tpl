{{/*
Renders the user key secret if user has not specified a custom secret.
*/}}
{{- define "newrelic.common.userKey.secret" }}
{{- if not (include "newrelic.common.userKey._customSecretName" .) }}
{{- /* Fail if user key is empty and required: */ -}}
{{- if not (include "newrelic.common.userKey._userKey" .) }}
    {{- fail "You must specify a userKey or a customUserKeySecretName containing it" }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "newrelic.common.userKey.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "newrelic.common.labels" . | nindent 4 }}
data:
  {{ include "newrelic.common.userKey.secretKeyName" . }}: {{ include "newrelic.common.userKey._userKey" . | b64enc }}
{{- end }}
{{- end }}
