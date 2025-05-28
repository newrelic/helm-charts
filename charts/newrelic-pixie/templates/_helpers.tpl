{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "newrelic-pixie.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "newrelic-pixie.namespace" -}}
{{- if .Values.namespace -}}
    {{- .Values.namespace -}}
{{- else -}}
    {{- .Release.Namespace | default "pl" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic-pixie.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if ne $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Generate basic labels */}}
{{- define "newrelic-pixie.labels" }}
app: {{ template "newrelic-pixie.name" . }}
app.kubernetes.io/name: {{ include "newrelic-pixie.name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{.Release.Service }}
release: {{.Release.Name }}
{{- end }}

{{- define "newrelic-pixie.cluster" -}}
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

{{- define "newrelic-pixie.nrStaging" -}}
{{- if .Values.global }}
  {{- if .Values.global.nrStaging }}
    {{- .Values.global.nrStaging -}}
  {{- end -}}
{{- else if .Values.nrStaging }}
  {{- .Values.nrStaging -}}
{{- end -}}
{{- end -}}

{{- define "newrelic-pixie.licenseKey" -}}
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

{{- define "newrelic-pixie.apiKey" -}}
{{- if .Values.global}}
  {{- if .Values.global.apiKey }}
      {{- .Values.global.apiKey -}}
  {{- else -}}
      {{- .Values.apiKey | default "" -}}
  {{- end -}}
{{- else -}}
    {{- .Values.apiKey | default "" -}}
{{- end -}}
{{- end -}}

{{- /*
adapted from https://github.com/newrelic/helm-charts/blob/af747af93fb5b912374196adc59b552965b6e133/library/common-library/templates/_low-data-mode.tpl
TODO: actually use common-library chart dep
*/ -}}
{{- /*
Abstraction of the lowDataMode toggle.
This helper allows to override the global `.global.lowDataMode` with the value of `.lowDataMode`.
Returns "true" if `lowDataMode` is enabled, otherwise "" (empty string)
*/ -}}
{{- define "newrelic-pixie.lowDataMode" -}}
{{- /* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */ -}}
{{- if (get .Values "lowDataMode" | kindIs "bool") -}}
    {{- if .Values.lowDataMode -}}
        {{- /*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "newrelic.common.lowDataMode" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */ -}}
        {{- .Values.lowDataMode -}}
    {{- end -}}
{{- else -}}
{{- /* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */ -}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "lowDataMode" | kindIs "bool" -}}
    {{- if $global.lowDataMode -}}
        {{- $global.lowDataMode -}}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretName where the New Relic license is being stored.
*/}}
{{- define "newrelic-pixie.customSecretName" -}}
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
Return the customSecretApiKeyName where the Pixie API key is being stored.
*/}}
{{- define "newrelic-pixie.customSecretApiKeyName" -}}
    {{- .Values.customSecretApiKeyName | default "" -}}
{{- end -}}

{{/*
Return the customSecretLicenseKey
*/}}
{{- define "newrelic-pixie.customSecretLicenseKey" -}}
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
Return the customSecretApiKeyKey
*/}}
{{- define "newrelic-pixie.customSecretApiKeyKey" -}}
    {{- .Values.customSecretApiKeyKey | default "" -}}
{{- end -}}

{{/*
Returns if the template should render, it checks if the required values
licenseKey and cluster are set.
*/}}
{{- define "newrelic-pixie.areValuesValid" -}}
{{- $cluster := include "newrelic-pixie.cluster" . -}}
{{- $licenseKey := include "newrelic-pixie.licenseKey" . -}}
{{- $apiKey := include "newrelic-pixie.apiKey" . -}}
{{- $customSecretName := include "newrelic-pixie.customSecretName" . -}}
{{- $customSecretLicenseKey := include "newrelic-pixie.customSecretLicenseKey" . -}}
{{- $customSecretApiKeyKey := include "newrelic-pixie.customSecretApiKeyKey" . -}}
{{- and (or (and $licenseKey $apiKey) (and $customSecretName $customSecretLicenseKey $customSecretApiKeyKey)) $cluster}}
{{- end -}}
