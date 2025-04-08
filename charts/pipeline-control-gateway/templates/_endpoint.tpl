{{- /*
A helper to return the NR endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-otlp.nr-data.net"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://otlp.eu01.nr-data.net"
    {{- else -}}
        "https://otlp.nr-data.net"
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the NR GRPC endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.grpc.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "staging-otlp.nr-data.net:443"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "otlp.eu01.nr-data.net:443"
    {{- else -}}
        "otlp.nr-data.net:443"
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the NR collector endpoint for data
*/ -}}
{{- define "nrCollector.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    https://staging-collector.newrelic.com
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        https://collector.eu.newrelic.com
    {{- else -}}
        https://collector.newrelic.com
    {{- end -}}
{{- end -}}
{{- end -}}


{{- /*
A helper to return the NR Event endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.event.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-insights-collector.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://insights-collector.eu01.nr-data.net"
    {{- else -}}
        "https://insights-collector.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}


{{- /*
A helper to return the NR Logs endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.log.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-log-api.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://log-api.eu.newrelic.com"
    {{- else -}}
        "https://log-api.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}


{{- /*
A helper to return the NR Metrics endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.metrics.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-metric-api.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://metric-api.eu.newrelic.com"
    {{- else -}}
        "https://metric-api.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the NR Traces endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.traces.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-trace-api.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://trace-api.eu.newrelic.com"
    {{- else -}}
        "https://trace-api.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}


{{- /*
A helper to return the NR Infra Event endpoint to send data to
*/ -}}
{{- define "nrKubernetesOtel.infra-event.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "https://staging-infra-api.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "https://infra-api.eu.newrelic.com"
    {{- else -}}
        "https://infra-api.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}

{{- /*
A helper to return the NR host endpoint for data
*/ -}}
{{- define "nrKubernetesOtel.NrHost.endpoint" -}}
{{- if include "newrelic.common.nrStaging" . -}}
    "staging-collector.newrelic.com"
{{- else -}}
    {{- if hasPrefix "eu" (include "newrelic.common.license._licenseKey" . ) -}}
        "collector.eu01.nr-data.net"
    {{- else -}}
        "collector.newrelic.com"
    {{- end -}}
{{- end -}}
{{- end -}}