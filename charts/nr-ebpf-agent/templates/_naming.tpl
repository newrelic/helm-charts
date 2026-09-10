{{- define "nr-ebpf-agent.service.name" -}}
{{- include "newrelic.common.naming.truncateToDNS" (include "newrelic.common.naming.fullname" .) }}
{{- end }}

{{- define "otel-collector.service.name" -}}
{{- include "newrelic.common.naming.truncateToDNS" "otel-collector" }}
{{- end }}

{{- define "nr-ebpf-agent.otelconfig.name" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "config") -}}
{{- end -}}

{{- define "nr-ebpf-agent.otelcollector.name" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "otel-collector") -}}
{{- end -}}

{{- define "nr-ebpf-agent.collector.name" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "collector") -}}
{{- end -}}
