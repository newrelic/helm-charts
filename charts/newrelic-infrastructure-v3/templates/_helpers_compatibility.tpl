{{/*
Returns true if .Values.ksm.enabled is true and the legacy disableKubeStateMetrics is not set
*/}}
{{- define "newrelic.compatibility.ksm.enabled" -}}
{{- if and .Values.ksm.enabled (not .Values.disableKubeStateMetrics) -}}
true
{{- end -}}
{{- end -}}

{{/*
Returns legacy ksm values
*/}}
{{- define "newrelic.compatibility.ksm.legacyData" -}}
enabled: true
{{- if .Values.kubeStateMetricsScheme }}
scheme: {{ .Values.kubeStateMetricsScheme }}
{{- end -}}
{{- if .Values.kubeStateMetricsPort }}
port: {{ .Values.kubeStateMetricsPort }}
{{- end -}}
{{- if .Values.kubeStateMetricsUrl }}
staticURL: {{ .Values.kubeStateMetricsUrl }}
{{- end -}}
{{- if .Values.kubeStateMetricsPodLabel }}
selector: {{ printf "%s=kube-state-metrics" .Values.kubeStateMetricsPodLabel }}
{{- end -}}
{{- if  .Values.kubeStateMetricsNamespace }}
namespace: {{ .Values.kubeStateMetricsNamespace}}
{{- end -}}
{{- end -}}

{{/*
Returns the new value if available, otherwise falling back on the legacy one
*/}}
{{- define "newrelic.compatibility.valueWithFallback" -}}
{{- if .supported }}
{{- toYaml .supported}}
{{- else if .legacy -}}
{{- toYaml .legacy}}
{{- end }}
{{- end -}}

{{/*
Returns a dictionary with legacy runAsUser config
*/}}
{{- define "newrelic.compatibility.securityContext" -}}
{{- if  .Values.runAsUser -}}
{{ dict "runAsUser" .Values.runAsUser | toYaml }}
{{- end -}}
{{- end -}}

{{/*
Returns agent configmap merged with legacy config and legacy eventQueueDepth config
*/}}
{{- define "newrelic.compatibility.agentConfig" -}}
{{ $config:= (include "newrelic.compatibility.valueWithFallback" (dict "legacy" .Values.config "supported" .Values.common.agentConfig ) | fromYaml )}}
{{- if .Values.eventQueueDepth -}}
{{- mustMergeOverwrite $config (dict "event_queue_depth" .Values.eventQueueDepth ) | toYaml }}
{{- else -}}
{{- $config | toYaml}}
{{- end -}}
{{- end -}}

{{/*
Returns legacy integrations_config configmap data
*/}}
{{- define "newrelic.compatibility.integrations" -}}
{{- if .Values.integrations_config -}}
{{- range .Values.integrations_config }}
{{ .name -}}: |-
  {{- toYaml .data | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "newrelic.compatibility.message.apiServerSecurePort" -}}
-> WARNING LEGACY CONFIG <-
    The "apiServerSecurePort" value is no longer supported, please specify it in the section "apiServer.autodiscover[].endpoints".
{{- end -}}

{{- define "newrelic.compatibility.message.windows" -}}
-> WARNING LEGACY CONFIG <-
Windows is currently supported by 2.x charts only and therefore "windowsOsList" "windowsSecurityContext" "windowsNodeSelector"
are no longer supported.
{{- end -}}

{{- define "newrelic.compatibility.message.etcdSecrets" -}}
-> WARNING LEGACY CONFIG <-
Values "etcdTlsSecretName" and "etcdTlsSecretNamespace" are no longer supported, please specify them in the config
file. Example:
# - endpoints:
#     - url: https://localhost:9979
#       insecureSkipVerify: true
#       auth:
#         type: mTLS
#         mtls:
#           secretName: secret-name
#           secretNamespace: secret-namespace
{{- end -}}

{{- define "newrelic.compatibility.message.apiURL" -}}
-> WARNING LEGACY CONFIG <-
Values "controllerManagerEndpointUrl", "etcdEndpointUrl", "apiServerEndpointUrl", "schedulerEndpointUrl" are no longer
supported, please specify them in the config file. You can add them in the autodiscovery section. Example for etcdEndpointUrl:

#  autodiscover:
#    - selector: "tier=control-plane,component=etcd"
#      namespace: kube-system
#      matchNode: true
#      endpoints:
#        - url: https://localhost:4001
#          insecureSkipVerify: true
#          auth:
#            type: bearer
{{- end -}}

{{- define "newrelic.compatibility.message.image" -}}
-> WARNING LEGACY CONFIG <-
You have specified into values one of the legacy options "image.*".
The following values are no longer supported and are currently ignored.
 - image.repository
 - image.tag
 - image.pullPolicy
 - image.pullSecrets

Notice that the 3.x version of the integration uses 3 different images.
Please set:
 - images.forwarder.* to configure the image in charge of sending data to newrelic backend
 - images.agent.* to configure the image bundling the agent and onHost integration
 - images.integration.* to configure the image in charge of scraping k8s data
{{- end -}}
