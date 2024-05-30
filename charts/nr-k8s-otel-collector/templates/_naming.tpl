{{- /* Naming helpers*/ -}}
{{- define "nrKubernetesOtel.deployment.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "deployment") -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "daemonset") -}}
{{- end -}}

{{- define "nrKubernetesOtel.deployment.configmap.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "deployment-config") -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.configmap.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "daemonset-config") -}}
{{- end -}}