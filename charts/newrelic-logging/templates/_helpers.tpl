{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "newrelic-logging.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic-logging.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if ne $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/* Generate basic labels */}}
{{- define "newrelic-logging.labels" }}
app: {{ template "newrelic-logging.name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{.Release.Service }}
release: {{.Release.Name }}
app.kubernetes.io/name: {{ template "newrelic-logging.name" . }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "newrelic-logging.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create the name of the fluent bit config
*/}}
{{- define "newrelic-logging.fluentBitConfig" -}}
{{ template "newrelic-logging.fullname" . }}-fluent-bit-config
{{- end -}}

{{/*
Return the licenseKey
*/}}
{{- define "newrelic-logging.licenseKey" -}}
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

{{/*
Return the cluster name
*/}}
{{- define "newrelic-logging.cluster" -}}
{{- if .Values.global}}
  {{- if .Values.global.cluster }}
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
{{- define "newrelic-logging.customSecretName" -}}
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
{{- define "newrelic-logging.customSecretKey" -}}
{{- if .Values.global }}
  {{- if .Values.global.customSecretLicenseKey }}
      {{- .Values.global.customSecretLicenseKey -}}
  {{- else -}}
    {{- if .Values.global.customSecretKey }}
        {{- .Values.global.customSecretKey -}}
    {{- else -}}
        {{- .Values.customSecretKey | default "" -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- if .Values.customSecretLicenseKey }}
      {{- .Values.customSecretLicenseKey -}}
  {{- else -}}
      {{- .Values.customSecretKey | default "" -}}
  {{- end -}}
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

{{/*
Returns lowDataMode
*/}}
{{- define "newrelic-logging.lowDataMode" -}}
{{/* `get` will return "" (empty string) if value is not found, and the value otherwise, so we can type-assert with kindIs */}}
{{- if (get .Values "lowDataMode" | kindIs "bool") -}}
  {{- if .Values.lowDataMode -}}
    {{/*
        We want only to return when this is true, returning `false` here will template "false" (string) when doing
        an `(include "newrelic-logging.lowDataMode" .)`, which is not an "empty string" so it is `true` if it is used
        as an evaluation somewhere else.
    */}}
    {{- .Values.lowDataMode -}}
  {{- end -}}
{{- else -}}
{{/* This allows us to use `$global` as an empty dict directly in case `Values.global` does not exists */}}
{{- $global := index .Values "global" | default dict -}}
{{- if get $global "lowDataMode" | kindIs "bool" -}}
  {{- if $global.lowDataMode -}}
    {{- $global.lowDataMode -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns logsEndpoint
*/}}
{{- define "newrelic-logging.logsEndpoint" -}}
{{- if .Values.endpoint -}}
{{ .Values.endpoint -}}
{{- else -}}
{{ (include "newrelic.common.log_api_endpoint" .) | default "https://log-api.newrelic.com" }}/log/v1
{{- end -}}
{{- end -}}

{{/*
Returns the fluentbit YAML pipeline inputs to collect its own metrics
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.inputs" -}}
{{- $fluentBitMetrics := get $.Values.fluentBit "fluentBitMetrics" | default "basic" -}}
{{- if eq $fluentBitMetrics "advanced" }}
- name: prometheus_scrape
  alias: fb-metrics-collector
  host: 127.0.0.1
  port: 2020
  tag: fb_metrics
  metrics_path: /api/v2/metrics/prometheus
  scrape_interval: 60s
{{- end -}}
{{- if eq $fluentBitMetrics "basic" }}
- name: dummy
  tag: buildInfo
  dummy: '{"message":"trigger for basic metric at every 10 minutes scrape_interval"}'
  interval_sec: 600
{{- end -}}
{{- end -}}

{{/*
Returns the fluentbit YAML pipeline filters to collect its own metrics
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.filters" -}}
{{- $fluentBitMetrics := get $.Values.fluentBit "fluentBitMetrics" | default "basic" -}}
{{- if eq $fluentBitMetrics "basic" }}
- name: modify
  match: buildInfo
  add: fluentBitVersion ${FBVERSION}
- name: lua
  match: buildInfo
  script: /fluent-bit/scripts/payload.lua
  call: build_payload
{{- end -}}
{{- end -}}

{{/*
Returns the fluentbit YAML pipeline outputs to forward its metrics to New Relic
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.outputs" -}}
{{- $fluentBitMetrics := get $.Values.fluentBit "fluentBitMetrics" | default "basic" -}}
{{- if eq $fluentBitMetrics "advanced" }}
- name: prometheus_remote_write
  match: fb_metrics
  alias: fb-metrics-forwarder
  host: ${METRICS_HOST}
  port: 443
  uri: /prometheus/v1/write?prometheus_server=${CLUSTER_NAME}
  header: Authorization Bearer ${LICENSE_KEY}
  tls: on
  tls.verify: off
  add_label:
    - app fluent-bit
    - source kubernetes
    - pod_name ${HOSTNAME}
    - node_name ${NODE_NAME}
    - tier advanced
    {{- $clusterName := (include "newrelic-logging.cluster" .) }}
    {{- if $clusterName }}
    - cluster_name {{ $clusterName }}
    {{- else }}
    - cluster_name ""
    {{- end }}
    - namespace {{ .Release.Namespace }}
    - daemonset_name {{ include "newrelic-logging.fullname" . }}
{{- end -}}
{{- if eq $fluentBitMetrics "basic" }}
- name: http
  match: buildInfo
  host: ${METRICS_HOST}
  port: 443
  uri: /metric/v1
  format: json
  tls: on
  header:
    - Api-Key ${LICENSE_KEY}
    - Content-Type application/json
  json_date_key: false
{{- end -}}
{{- end -}}

{{/*
Fails the render if any fluentBit.config value still uses the classic (.conf) format,
which is not supported anymore.
*/}}
{{- define "newrelic-logging.fluentBit.assertYamlConfig" -}}
{{- range $key, $value := .Values.fluentBit.config -}}
  {{- if and (kindIs "string" $value) (regexMatch "(?m)^\\s*(\\[(SERVICE|INPUT|FILTER|OUTPUT|PARSER|MULTILINE_PARSER)\\]|@INCLUDE|@SET)" $value) -}}
    {{- fail (printf "fluentBit.config.%s uses the classic Fluent Bit format, which is not supported anymore. Convert it to YAML (see the chart README)." $key) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns metricsHost
*/}}
{{- define "newrelic-logging.metricsHost" -}}
{{- if .Values.metricsEndpoint -}}
{{ .Values.metricsEndpoint -}}
{{- else -}}
{{- (include "newrelic.common.metric_api_endpoint" .) | default "https://metric-api.newrelic.com" | trimPrefix "https://" | trimPrefix "http://" -}}
{{- end -}}
{{- end -}}

{{/*
Returns if the template should render, it checks if the required values are set.
*/}}
{{- define "newrelic-logging.areValuesValid" -}}
{{- $licenseKey := include "newrelic-logging.licenseKey" . -}}
{{- $customSecretName := include "newrelic-logging.customSecretName" . -}}
{{- $customSecretKey := include "newrelic-logging.customSecretKey" . -}}
{{- and (or $licenseKey (and $customSecretName $customSecretKey))}}
{{- end -}}

{{/*
If additionalEnvVariables is set, renames to extraEnv. Returns extraEnv.
*/}}
{{- define "newrelic-logging.extraEnv" -}}
{{- if .Values.fluentBit }}
  {{- if .Values.fluentBit.additionalEnvVariables }}
    {{- tpl (toYaml .Values.fluentBit.additionalEnvVariables) . -}}
  {{- else if .Values.fluentBit.extraEnv }}
    {{- tpl (toYaml .Values.fluentBit.extraEnv) . -}}
  {{- end -}}
{{- end -}}
{{- end -}}


