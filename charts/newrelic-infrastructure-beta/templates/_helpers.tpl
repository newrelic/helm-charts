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

{{/* Common labels */}}
{{- define "newrelic.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "newrelic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
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

{{/* Return the cluster */}}
{{- define "newrelic.cluster" -}}
{{- if .Values.global -}}
  {{- if .Values.global.cluster -}}
      {{- .Values.global.cluster -}}
  {{- else -}}
      {{- .Values.cluster | default "" -}}
  {{- end -}}
{{- else -}}
  {{- .Values.cluster | default "" -}}
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
{{- else if and .Values.global -}}
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
{{- if .Values.global }}
  {{- if .Values.global.nrStaging }}
    {{- .Values.global.nrStaging -}}
  {{- end -}}
{{- else if .Values.nrStaging }}
  {{- .Values.nrStaging -}}
{{- end -}}
{{- end -}}

{{/*
Returns fargate
*/}}
{{- define "newrelic.fargate" -}}
{{- if .Values.global }}
  {{- if .Values.global.fargate }}
    {{- .Values.global.fargate -}}
  {{- end -}}
{{- else if .Values.fargate }}
  {{- .Values.fargate -}}
{{- end -}}
{{- end -}}

{{/* controlPlane scraper config */}}
{{- define "newrelic.controlPlane.scraperConfig" -}}
controlPlane:
  enabled: true
  {{- if .Values.controlPlane.scraperConfig.controlPlane }}
    {{- .Values.controlPlane.scraperConfig.controlPlane | toYaml | nindent 2 }}
  {{- end }}
  {{- range $key, $val := .Values.controlPlane.scraperConfig }}
    {{- if ne $key "controlPlane" -}}
    {{- nindent 0 $key }}: {{ $val | quote }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* kubelet scraper config */}}
{{- define "newrelic.kubelet.scraperConfig" -}}
kubelet:
  enabled: true
  {{- if .Values.kubelet.scraperConfig.kubelet }}
    {{- .Values.kubelet.scraperConfig.kubelet | toYaml | nindent 2 }}
  {{- end }}
  {{- range $key, $val := .Values.kubelet.scraperConfig }}
    {{- if ne $key "kubelet" -}}
    {{- nindent 0 $key }}: {{ $val | quote }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* ksm scraper config */}}
{{- define "newrelic.ksm.scraperConfig" -}}
ksm:
  enabled: true
  {{- if .Values.ksm.scraperConfig.ksm }}
    {{- .Values.ksm.scraperConfig.ksm | toYaml | nindent 2 }}
  {{- end }}
  {{- range $key, $val := .Values.ksm.scraperConfig }}
    {{- if ne $key "ksm" -}}
    {{- nindent 0 $key }}: {{ $val | quote }}
    {{- end }}
  {{- end }}
{{- end }}


{{/*
Returns the list of namespaces where secrets need to be accessed by the controlPlane Scraper to do mTLS Auth
*/}}
{{- define "newrelic.roleBindingNamespaces" -}}
{{ $namespaceList := list }}
{{- range $components := .Values.controlPlane.scraperConfig.controlPlane }}
    {{- range $autodiscover := $components.autodiscover }}
        {{- range $endpoint := $autodiscover.endpoints }}
            {{- if and ($endpoint.auth) }}
            {{- if $endpoint.auth.mtls }}
            {{- if $endpoint.auth.mtls.secretName }}
            {{- $namespace := $endpoint.auth.mtls.secretNamespace | default "default" -}}
            {{- $namespaceList = append $namespaceList $namespace -}}
            {{- end }}
            {{- end }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
roleBindingNamespaces: {{- uniq $namespaceList | toYaml | nindent 0 }}
{{- end -}}

{{/*
Returns Custom Attributes as a yaml even if formatted as a json string
*/}}
{{- define "newrelic.customAttributes" -}}
{{- if kindOf .Values.customAttributes | eq "string" -}}
{{  .Values.customAttributes }}
{{- else -}}
{{ .Values.customAttributes | toJson | quote  }}
{{- end -}}
{{- end -}}

{{- define "newrelic.deprecatedKubeStateMetrics" -}}
ksm:
  discovery:
      scheme: {{  $.Values.kubeStateMetricsScheme | quote }}
      port: {{  $.Values.kubeStateMetricsPort | quote }}
      static:
        url: {{  $.Values.kubeStateMetricsUrl | quote }}
      endpoints:
          label_selector: {{  $.Values.kubeStateMetricsPodLabel | quote }}
          namespace: {{  $.Values.kubeStateMetricsNamespace | quote }}
{{- end -}}

{{- define "config" -}}
{{ toYaml (merge (include "newrelic.deprecatedKubeStateMetrics" . | fromYaml) .Values.config) }}
{{- end }}
