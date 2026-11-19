{{- define "nr-ebpf-agent.service.name" -}}
{{- include "newrelic.common.naming.truncateToDNS" (include "newrelic.common.naming.fullname" .) }}
{{- end }}

