{{/*
Expand the name of the chart.
*/}}
{{- define "newrelic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "newrelic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/* Generate mode label */}}
{{- define "newrelic.mode" }}
{{- if .Values.privileged -}}
privileged
{{- else -}}
unprivileged
{{- end }}
{{- end -}}

{{/* Selector labels */}}
{{- define "newrelic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "newrelic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Common labels */}}
{{- define "newrelic.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "newrelic.selectorLabels" . }}
mode: {{ template "newrelic.mode" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/* Create the name of the service account to use */}}
{{- define "newrelic.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "newrelic.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the cluster name
*/}}
{{- define "newrelic.cluster" -}}
{{- if .Values.cluster -}}
  {{- .Values.cluster -}}
{{- else if .Values.global -}}
  {{- if .Values.global.cluster -}}
    {{- .Values.global.cluster -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return local licenseKey if set, global otherwise
*/}}
{{- define "newrelic.licenseKey" -}}
{{- if .Values.licenseKey -}}
  {{- .Values.licenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.licenseKey -}}
    {{- .Values.global.licenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseCustomSecretName" -}}
{{- if .Values.customSecretName -}}
  {{- .Values.customSecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretName -}}
    {{- .Values.global.customSecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseSecretName" -}}
{{ include "newrelic.licenseCustomSecretName" . | default (printf "%s-license" (include "newrelic.fullname" . )) }}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseCustomSecretKey" -}}
{{- if .Values.customSecretLicenseKey -}}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseSecretKey" -}}
{{ include "newrelic.licenseCustomSecretKey" . | default "licenseKey" }}
{{- end -}}

{{/*
Returns nrStaging
*/}}
{{- define "newrelic.nrStaging" -}}
{{- if .Values.nrStaging -}}
  {{- .Values.nrStaging -}}
{{- else if .Values.global -}}
  {{- if .Values.global.nrStaging -}}
    {{- .Values.global.nrStaging -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns fargate
*/}}
{{- define "newrelic.fargate" -}}
{{- if .Values.fargate -}}
  {{- .Values.fargate -}}
{{- else if .Values.global -}}
  {{- if .Values.global.fargate -}}
    {{- .Values.global.fargate -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the list of namespaces where secrets need to be accessed by the controlPlane integration to do mTLS Auth
*/}}
{{- define "newrelic.roleBindingNamespaces" -}}
{{ $namespaceList := list }}
{{- range $components := .Values.controlPlane.config }}
  {{- if $components }}
  {{- if $components.autodiscover }}
    {{- range $autodiscover := $components.autodiscover }}
      {{- if $autodiscover }}
      {{- if $autodiscover.endpoints }}
        {{- range $endpoint := $autodiscover.endpoints }}
            {{- if $endpoint.auth }}
            {{- if $endpoint.auth.mtls }}
            {{- if $endpoint.auth.mtls.secretNamespace }}
            {{- $namespaceList = append $namespaceList $endpoint.auth.mtls.secretNamespace -}}
            {{- end }}
            {{- end }}
            {{- end }}
        {{- end }}
      {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
roleBindingNamespaces: {{- uniq $namespaceList | toYaml | nindent 0 }}
{{- end -}}

{{/*
Returns Custom Attributes even if formatted as a json string
*/}}
{{- define "newrelic.customAttributesWithoutClusterName" -}}
{{- if kindOf .Values.customAttributes | eq "string" -}}
{{  .Values.customAttributes }}
{{- else -}}
{{ .Values.customAttributes | toJson }}
{{- end -}}
{{- end -}}

{{- define "newrelic.customAttributes" -}}
{{- merge (include "newrelic.customAttributesWithoutClusterName" . | fromJson) (dict "clusterName" (include "newrelic.cluster" .)) | toJson }}
{{- end -}}


{{/*
Returns static cp component taking into account deprecated values
*/}}
{{- define "newrelic.compatibility.control-plane" -}}
enabled: true
{{- with .autodiscover }}
autodiscover:
{{ . | toYaml}}
{{- end -}}

{{- if ( or .staticEndpoint .etcdEndpointUrl) }}
staticEndpoint:
    {{- if .staticEndpoint  }}
{{ .staticEndpoint | toYaml | indent 2}}
    {{- else if .etcdEndpointUrl }}
  url: {{ .etcdEndpointUrl }}
  insecureSkipVerify: true
  auth:
    type: bearer
    {{- end -}}
{{- end -}}
{{- end -}}


{{/*
Returns static ksm data taking into account deprecated values
*/}}
{{- define "newrelic.compatibility.ksm" -}}

enabled: true

{{- if ( or .Values.ksm.config.scheme .Values.kubeStateMetricsScheme) }}
scheme: {{  .Values.ksm.config.scheme | default .Values.kubeStateMetricsScheme | quote }}
{{- end -}}

{{- if (or .Values.ksm.config.port .Values.kubeStateMetricsPort) }}
port: {{ .Values.ksm.config.port | default .Values.kubeStateMetricsPort }}
{{- end -}}

{{- if (or .Values.ksm.config.staticUrl .Values.kubeStateMetricsUrl) }}
staticUrl: {{ .Values.ksm.config.staticUrl | default .Values.kubeStateMetricsUrl | quote }}
{{- end -}}

{{- if .Values.ksm.config.selector }}
selector: {{ .Values.ksm.config.selector | quote }}
{{- else if .Values.kubeStateMetricsPodLabel }}
selector: {{ printf "%s=kube-state-metrics" .Values.kubeStateMetricsPodLabel | quote}}
{{- end -}}

{{- if (or .Values.ksm.config.namespace .Values.kubeStateMetricsNamespace) }}
namespace: {{ .Values.ksm.config.namespace | default .Values.kubeStateMetricsNamespace | quote }}
{{- end -}}

{{- if .Values.ksm.config.distributed }}
distributed: {{  .Values.ksm.config.distributed }}
{{- end -}}
{{- end -}}


{{/*
Returns agent config
*/}}
{{- define "newrelic.compatibility.agentConfig" -}}
{{- if .Values.common.agentConfig -}}
{{- toYaml .Values.common.agentConfig -}}
{{- else if .Values.config -}}
{{- toYaml .Values.config -}}
{{- end -}}
{{- end -}}


{{/*
Returns integration config Map
*/}}
{{- define "newrelic.compatibility.integrations" -}}
{{- if .Values.integrations_config -}}
{{- range .Values.integrations_config }}
{{ .name | indent 2 }}: |
{{ toYaml .data | indent  4 }}
{{- end -}}

{{- else if .Values.integrations -}}
{{- range $k, $v := .Values.integrations }}
  {{ $k | trimSuffix ".yaml" | trimSuffix ".yml" }}.yaml: |
    {{- tpl ($v | toYaml) $ | nindent 4 }}
{{- end -}}
{{- end -}}
{{- end -}}
