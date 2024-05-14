{{- /*
A helper to return the NR endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-otlp.nr-data.net"
{{- else -}}
    "https://otlp.nr-data.net"
{{- end -}}
{{- end -}}