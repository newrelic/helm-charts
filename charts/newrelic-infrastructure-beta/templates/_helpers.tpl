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


{{/* Return the licenseKey */}}
{{- define "newrelic.licenseKey" -}}
{{- if .Values.global}}
  {{- if .Values.global.licenseKey }}
      {{- .Values.global.licenseKey -}}
  {{- else -}}
      {{- .Values.licenseKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.licenseKey | default "" -}}
{{- end -}}
{{- end -}}


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
Return the customSecretName
*/}}
{{- define "newrelic.customSecretName" -}}
{{- if .Values.global }}
  {{- if .Values.global.customSecretName }}
      {{- .Values.global.customSecretName -}}
  {{- else -}}
      {{- .Values.customSecretName | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.customSecretName | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretLicenseKey
*/}}
{{- define "newrelic.customSecretLicenseKey" -}}
{{- if .Values.global }}
  {{- if .Values.global.customSecretLicenseKey }}
      {{- .Values.global.customSecretLicenseKey -}}
  {{- else -}}
      {{- .Values.customSecretLicenseKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.customSecretLicenseKey | default "" -}}
{{- end -}}
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
{{- define "newrelic.controlPlane.scraper" -}}
controlPlane:
  enabled: true
{{- if .Values.controlPlane.scraper.config }}
    {{- .Values.controlPlane.scraper.config | toYaml | nindent 2 }}
    {{- range $key, $val := .Values.controlPlane.scraper }}
      {{- if ne $key "config" -}}
      {{- nindent 0 $key }}: {{ $val | quote }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/* kubelet scraper config */}}
{{- define "newrelic.kubelet.scraper" -}}
kubelet:
  enabled: true
{{- if .Values.kubelet.scraper.config }}
    {{- .Values.kubelet.scraper.config | toYaml | nindent 2 }}
    {{- range $key, $val := .Values.kubelet.scraper }}
      {{- if ne $key "config" -}}
      {{- nindent 0 $key }}: {{ $val | quote }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/* ksm scraper config */}}
{{- define "newrelic.ksm.scraper" -}}
ksm:
  enabled: true
{{- if .Values.ksm.scraper.config }}
    {{- .Values.ksm.scraper.config | toYaml | nindent 2 }}
    {{- range $key, $val := .Values.ksm.scraper }}
      {{- if ne $key "config" -}}
      {{- nindent 0 $key }}: {{ $val | quote }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}


{{/*
Returns the list of namespaces where secrets need to be accessed by the controlPlane Scraper to do mTLS Auth
*/}}
{{- define "newrelic.roleBindingNamespaces" -}}
{{ $namespaceList := list }}
{{- range $components := .Values.controlPlane.scraper.config }}
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
