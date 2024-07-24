{{- /*
    Auxiliary template until the PR that add these helpers to the common library are merged.
*/ -}}
{{- define "newrelic.common.apiKey.secretName" -}}
api-key-secret
{{- end -}}

{{- define "newrelic.common.apiKey.secretKeyName" -}}
a-secret-key
{{- end -}}

{{- define "newrelic.common.region" -}}
US
{{- end -}}
