{{- /* Naming helpers - simplified suffix naming convention */ -}}
{{- define "nrKubernetesOtel.deployment.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ss") -}}
{{- end -}}

{{- /* Alias for backward compatibility */ -}}
{{- define "nrKubernetesOtel.statefulset.fullname" -}}
{{- include "nrKubernetesOtel.deployment.fullname" . -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ds") -}}
{{- end -}}

{{- define "nrKubernetesOtel.deployment.configMap.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ss-cfg") -}}
{{- end -}}

{{- /* Alias for backward compatibility */ -}}
{{- define "nrKubernetesOtel.statefulset.configMap.fullname" -}}
{{- include "nrKubernetesOtel.deployment.configMap.fullname" . -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.configMap.fullname" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ds-cfg") -}}
{{- end -}}

{{- /* ServiceAccount helpers - separate serviceAccounts for deployment and daemonset (least privilege) */ -}}
{{- define "nrKubernetesOtel.deployment.serviceAccountName" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ss") -}}
{{- end -}}

{{- define "nrKubernetesOtel.daemonset.serviceAccountName" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "ds") -}}
{{- end -}}
