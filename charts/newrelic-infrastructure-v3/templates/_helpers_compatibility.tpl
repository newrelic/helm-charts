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

{{- define "newrelic.compatibility.message.logFile" -}}
The `logFile` option is no longer supported and has been replaced by common.agentConfig.log_file.
{{- end -}}

{{- define "newrelic.compatibility.message.resources" -}}
You have specified the legacy `resources` option in your values, which is not fully compatible with the v3 version.
This version deploys three different components and therefore you'll need to specify resources for each of them.
Please use `ksm.resources`, `controlPlane.resources` and `kubelet.resources`.
{{- end -}}

{{- define "newrelic.compatibility.message.tolerations" -}}
You have specified the legacy `tolerations` option in your values, which is not fully compatible with the v3 version.
This version deploys three different components and therefore you'll need to specify tolerations for each of them.
Please use `ksm.tolerations`, `controlPlane.tolerations` and `kubelet.tolerations`.
{{- end -}}

{{- define "newrelic.compatibility.message.apiServerSecurePort" -}}
You have specified the legacy `apiServerSecurePort` option in your values, which is not fully compatible with the v3
version.
Please configure the API Server port as a part of `apiServer.autodiscover[].endpoints`.
{{- end -}}

{{- define "newrelic.compatibility.message.windows" -}}
nri-kubernetes v3 does not support deploying into windows Nodes.
Please use the latest 2.x version of the chart.
{{- end -}}

{{- define "newrelic.compatibility.message.etcdSecrets" -}}
Values "etcdTlsSecretName" and "etcdTlsSecretNamespace" are no longer supported, please specify them as a part of the
`etcd` config in the values, for example:
 - endpoints:
 - url: https://localhost:9979
   insecureSkipVerify: true
   auth:
 type: mTLS
 mtls:
   secretName: {{ .Values.etcdTlsSecretName | default "etcdTlsSecretName"}}
   secretNamespace: {{ .Values.etcdTlsSecretNamespace | default "etcdTlsSecretNamespace"}}
{{- end -}}

{{- define "newrelic.compatibility.message.apiURL" -}}
Values "controllerManagerEndpointUrl", "etcdEndpointUrl", "apiServerEndpointUrl", "schedulerEndpointUrl" are no longer
supported, please specify them as a part of the `controlplane` config in the values, for example
  autodiscover:
- selector: "tier=control-plane,component=etcd"
  namespace: kube-system
  matchNode: true
  endpoints:
- url: https://localhost:4001
  insecureSkipVerify: true
  auth:
type: bearer
{{- end -}}

{{- define "newrelic.compatibility.message.image" -}}
Configuring image repository an tag under `image` is no longer supported.
The following values are no longer supported and are currently ignored:
 - image.repository
 - image.tag
 - image.pullPolicy
 - image.pullSecrets

Notice that the 3.x version of the integration uses 3 different images.
Please set:
 - images.forwarder.* to configure the infrastructure-agent forwarder.
 - images.agent.* to configure the image bundling the infrastructure-agent and on-host integrations.
 - images.integration.* to configure the image in charge of scraping k8s data.
{{- end -}}
