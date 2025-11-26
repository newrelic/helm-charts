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
{{- if .Values.cluster -}}
  {{- .Values.cluster -}}
{{- else if .Values.global -}}
  {{- if .Values.global.cluster -}}
    {{- .Values.global.cluster -}}
  {{- end -}}
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
{{- if .Values.licenseKey }}
  {{- .Values.licenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.licenseKey }}
    {{- .Values.global.licenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "newrelic-pixie.apiKey" -}}
{{- if .Values.apiKey }}
  {{- .Values.apiKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.apiKey }}
    {{- .Values.global.apiKey -}}
  {{- end -}}
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
{{- if .Values.customSecretName }}
  {{- .Values.customSecretName -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretName }}
    {{- .Values.global.customSecretName -}}
  {{- end -}}
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
{{- if .Values.customSecretLicenseKey }}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the customSecretApiKeyKey
*/}}
{{- define "newrelic-pixie.customSecretApiKeyKey" -}}
    {{- .Values.customSecretApiKeyKey | default "" -}}
{{- end -}}

{{/*
Return proxy configuration from global or local values
*/}}
{{- define "newrelic-pixie.proxy" -}}
{{- if .Values.proxy }}
  {{- .Values.proxy -}}
{{- else if .Values.global }}
  {{- if .Values.global.proxy }}
    {{- .Values.global.proxy -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return image registry from global or local values
*/}}
{{- define "newrelic-pixie.image.registry" -}}
{{- if .Values.image.registry }}
  {{- .Values.image.registry -}}
{{- else if .Values.global -}}
  {{- if .Values.global.images -}}
    {{- if .Values.global.images.registry -}}
      {{- .Values.global.images.registry -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return image pull policy from global or local values
*/}}
{{- define "newrelic-pixie.image.pullPolicy" -}}
{{- if .Values.image.pullPolicy }}
  {{- .Values.image.pullPolicy -}}
{{- else if .Values.global -}}
  {{- if .Values.global.images -}}
    {{- if .Values.global.images.pullPolicy -}}
      {{- .Values.global.images.pullPolicy -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return image pull secrets from global or local values, merging both
*/}}
{{- define "newrelic-pixie.image.pullSecrets" -}}
{{- $localPullSecrets := .Values.image.pullSecrets | default list -}}
{{- $globalPullSecrets := list -}}
{{- if .Values.global -}}
  {{- if .Values.global.images -}}
    {{- $globalPullSecrets = .Values.global.images.pullSecrets | default list -}}
  {{- end -}}
{{- end -}}
{{- $merged := concat $globalPullSecrets $localPullSecrets -}}
{{- if $merged }}
{{- toJson $merged -}}
{{- end -}}
{{- end -}}

{{/*
Return nodeSelector from global or local values
*/}}
{{- define "newrelic-pixie.nodeSelector" -}}
{{- if .Values.nodeSelector }}
  {{- toJson .Values.nodeSelector -}}
{{- else if .Values.global }}
  {{- if .Values.global.nodeSelector }}
    {{- toJson .Values.global.nodeSelector -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return tolerations from global or local values
*/}}
{{- define "newrelic-pixie.tolerations" -}}
{{- if .Values.tolerations }}
  {{- toJson .Values.tolerations -}}
{{- else if .Values.global }}
  {{- if .Values.global.tolerations }}
    {{- toJson .Values.global.tolerations -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return affinity from global or local values
*/}}
{{- define "newrelic-pixie.affinity" -}}
{{- if .Values.affinity }}
  {{- toJson .Values.affinity -}}
{{- else if .Values.global }}
  {{- if .Values.global.affinity }}
    {{- toJson .Values.global.affinity -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return priorityClassName from global or local values
*/}}
{{- define "newrelic-pixie.priorityClassName" -}}
{{- if .Values.priorityClassName }}
  {{- .Values.priorityClassName -}}
{{- else if .Values.global }}
  {{- if .Values.global.priorityClassName }}
    {{- .Values.global.priorityClassName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return podSecurityContext from global or local values
*/}}
{{- define "newrelic-pixie.podSecurityContext" -}}
{{- if .Values.podSecurityContext }}
  {{- toJson .Values.podSecurityContext -}}
{{- else if .Values.global }}
  {{- if .Values.global.podSecurityContext }}
    {{- toJson .Values.global.podSecurityContext -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return containerSecurityContext from global or local values
*/}}
{{- define "newrelic-pixie.containerSecurityContext" -}}
{{- if .Values.containerSecurityContext }}
  {{- toJson .Values.containerSecurityContext -}}
{{- else if .Values.global }}
  {{- if .Values.global.containerSecurityContext }}
    {{- toJson .Values.global.containerSecurityContext -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return dnsConfig from global or local values
*/}}
{{- define "newrelic-pixie.dnsConfig" -}}
{{- if .Values.dnsConfig }}
  {{- toJson .Values.dnsConfig -}}
{{- else if .Values.global }}
  {{- if .Values.global.dnsConfig }}
    {{- toJson .Values.global.dnsConfig -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return hostNetwork from global or local values
*/}}
{{- define "newrelic-pixie.hostNetwork" -}}
{{- if kindIs "bool" .Values.hostNetwork }}
  {{- .Values.hostNetwork -}}
{{- else if .Values.global }}
  {{- if kindIs "bool" .Values.global.hostNetwork }}
    {{- .Values.global.hostNetwork -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return labels merged from global and local values
*/}}
{{- define "newrelic-pixie.labels.merged" -}}
{{- $globalLabels := dict -}}
{{- if .Values.global -}}
  {{- $globalLabels = .Values.global.labels | default dict -}}
{{- end -}}
{{- $localLabels := .Values.labels | default dict -}}
{{- $merged := merge $localLabels $globalLabels -}}
{{- if $merged }}
{{- toJson $merged -}}
{{- end -}}
{{- end -}}

{{/*
Return podLabels merged from global and local values
*/}}
{{- define "newrelic-pixie.podLabels.merged" -}}
{{- $globalLabels := dict -}}
{{- if .Values.global -}}
  {{- $globalLabels = .Values.global.podLabels | default dict -}}
{{- end -}}
{{- $localLabels := .Values.podLabels | default dict -}}
{{- $merged := merge $localLabels $globalLabels -}}
{{- if $merged }}
{{- toJson $merged -}}
{{- end -}}
{{- end -}}

{{/*
Return verboseLog from global or local values
*/}}
{{- define "newrelic-pixie.verboseLog" -}}
{{- if .Values.verboseLog }}
  {{- .Values.verboseLog -}}
{{- else if .Values.global }}
  {{- if .Values.global.verboseLog }}
    {{- .Values.global.verboseLog -}}
  {{- end -}}
{{- end -}}
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
