{{- /* Naming helpers*/ -}}
{{- define "nrKubernetesOtel.deployment.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "deployment") -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "daemonset") -}}
{{- end -}}

{{- define "nrKubernetesOtel.deployment.configMap.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "config") -}}
{{- end -}}

{{- define "nrKubernetesOtel.hpa.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "hpa") -}}
{{- end -}}

{{- define "nrKubernetesOtel.service.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "service") -}}
{{- end -}}

