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
Fails when the region cannot be computed (license set through a custom secret and no region provided).
nrStaging and fedramp.enabled already decide the region, so the check is skipped for them.
*/}}
{{- define "newrelic-logging.failIfRegionUnresolvable" -}}
{{- if not (or (include "newrelic.common.nrStaging" .) (include "newrelic.common.fedramp.enabled" .)) -}}
{{- include "newrelic.common.region.fail_if_unresolvable" . -}}
{{- end -}}
{{- end -}}

{{/*
Returns logsEndpoint
*/}}
{{- define "newrelic-logging.logsEndpoint" -}}
{{- if .Values.endpoint -}}
{{ .Values.endpoint -}}
{{- else -}}
{{- include "newrelic-logging.failIfRegionUnresolvable" . -}}
{{ (include "newrelic.common.log_api_endpoint" .) | default "https://log-api.newrelic.com" }}/log/v1
{{- end -}}
{{- end -}}

{{/*
Returns fluentbit config to collect and forward its metrics to New Relic
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.config" -}}
{{- $fluentBitMetrics := get $.Values.fluentBit "fluentBitMetrics" | default "basic" -}}
{{- if eq $fluentBitMetrics "advanced" }}
[INPUT]
    name prometheus_scrape
    Alias fb-metrics-collector
    host 127.0.0.1
    port 2020
    tag fb_metrics
    metrics_path /api/v2/metrics/prometheus
    scrape_interval 60s

[OUTPUT]
    Name                 prometheus_remote_write
    Match                fb_metrics
    Alias                fb-metrics-forwarder
    Host                 ${METRICS_HOST}
    Port                 443
    Uri                  /prometheus/v1/write?prometheus_server=${CLUSTER_NAME}
    Header               Authorization Bearer ${LICENSE_KEY}
    Tls                  On
    Tls.verify           Off
    add_label            app fluent-bit
    add_label            source kubernetes
    add_label            pod_name ${HOSTNAME}
    add_label            node_name ${NODE_NAME}
    add_label            tier  advanced
    {{- $clusterName := (include "newrelic-logging.cluster" .) -}}
    {{- if $clusterName -}}
    {{- printf "add_label            cluster_name %s" $clusterName | nindent 4 -}}
    {{- else -}}
    {{- printf "add_label            cluster_name \"%s\"" $clusterName | nindent 4 -}}
    {{- end -}}
    {{- printf "add_label            namespace %s" .Release.Namespace | nindent 4 -}}
    {{- printf "add_label            daemonset_name %s" (include "newrelic-logging.fullname" .) | nindent 4 -}}
{{- end -}}
{{- if eq $fluentBitMetrics "basic" }}
[INPUT]
    Name   dummy
    Tag    buildInfo
    Dummy  {"message":"trigger for basic metric at every 10 minutes scrape_interval"}
    Interval_Sec 600
[FILTER]
    Name    modify
    Match   buildInfo
    Add     fluentBitVersion  ${FBVERSION}
[FILTER]
    Name    lua
    Match   buildInfo
    script  /fluent-bit/scripts/payload.lua
    call    build_payload
[OUTPUT]
    Name    http
    Match   buildInfo
    Host    ${METRICS_HOST}
    Port    443
    URI     /metric/v1
    Format  json
    tls     On
    Header  Api-Key ${LICENSE_KEY}
    Header  Content-Type application/json
    json_date_key false    
{{- end -}}
{{- end -}}

{{/*
Fluent Bit config keys a customer can override in fluentBit.config.
*/}}
{{- define "newrelic-logging.fluentBit.configKeys" -}}
service inputs extraInputs filters lowDataModeFilters extraFilters outputs extraOutputs parsers
{{- end -}}

{{/*
Returns true when the given text is written in the classic Fluent Bit format.
*/}}
{{- define "newrelic-logging.fluentBit.isClassic" -}}
{{- if and (kindIs "string" .) (regexMatch "(?m)^\\s*(\\[(SERVICE|INPUT|FILTER|OUTPUT|PARSER|MULTILINE_PARSER|CUSTOM)\\]|@INCLUDE|@SET)" .) -}}
true
{{- end -}}
{{- end -}}

{{/*
Returns the fluentBit.config keys the customer set, separated by spaces.
*/}}
{{- define "newrelic-logging.fluentBit.overrideKeys" -}}
{{- $keys := list -}}
{{- range $key := splitList " " (include "newrelic-logging.fluentBit.configKeys" .) -}}
  {{- if get $.Values.fluentBit.config $key -}}
    {{- $keys = append $keys $key -}}
  {{- end -}}
{{- end -}}
{{- join " " $keys -}}
{{- end -}}

{{/*
Returns the fluentBit.config keys the customer wrote in the classic format, separated by spaces.
*/}}
{{- define "newrelic-logging.fluentBit.classicKeys" -}}
{{- $keys := list -}}
{{- range $key := splitList " " (include "newrelic-logging.fluentBit.configKeys" .) -}}
  {{- if include "newrelic-logging.fluentBit.isClassic" (get $.Values.fluentBit.config $key) -}}
    {{- $keys = append $keys $key -}}
  {{- end -}}
{{- end -}}
{{- join " " $keys -}}
{{- end -}}

{{/*
Returns the format of the Fluent Bit config: "yaml" or "classic".
The customer's fluentBit.config overrides decide, whatever fluentBit.configFormat says:
- any classic override: "classic"
- YAML overrides only: "yaml"
- no overrides: fluentBit.configFormat picks the chart defaults, "classic" for "conf" and "yaml" otherwise.
*/}}
{{- define "newrelic-logging.fluentBit.format" -}}
{{- if include "newrelic-logging.fluentBit.classicKeys" . -}}
classic
{{- else if and (eq (.Values.fluentBit.configFormat | default "" | toString) "conf") (not (include "newrelic-logging.fluentBit.overrideKeys" .)) -}}
classic
{{- else -}}
yaml
{{- end -}}
{{- end -}}

{{/*
Returns the name of the main Fluent Bit config file for the chosen format.
*/}}
{{- define "newrelic-logging.fluentBit.configFile" -}}
{{- if eq (include "newrelic-logging.fluentBit.format" .) "classic" -}}fluent-bit.conf{{- else -}}fluent-bit.yaml{{- end -}}
{{- end -}}

{{/*
Fails the render when classic and YAML overrides are mixed: both formats cannot be in the same file,
and the chart would otherwise drop the YAML override silently.
*/}}
{{- define "newrelic-logging.fluentBit.assertSingleFormat" -}}
{{- $configFormat := .Values.fluentBit.configFormat | default "" | toString -}}
{{- if not (has $configFormat (list "" "yaml" "conf")) -}}
  {{- fail (printf "fluentBit.configFormat must be \"yaml\" or \"conf\", got %q." $configFormat) -}}
{{- end -}}
{{- if eq (include "newrelic-logging.fluentBit.format" .) "classic" -}}
{{- range $key := splitList " " (include "newrelic-logging.fluentBit.configKeys" $) -}}
  {{- $value := get $.Values.fluentBit.config $key -}}
  {{- if and $value (kindIs "string" $value) (not (include "newrelic-logging.fluentBit.isClassic" $value)) -}}
    {{- fail (printf "fluentBit.config.%s is not in the classic Fluent Bit format, but fluentBit.config.%s is. Fluent Bit cannot mix both formats in one config. Write all your overrides in YAML (recommended) or all in the classic format." $key (include "newrelic-logging.fluentBit.classicKeys" $ | splitList " " | first)) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns a block of the Fluent Bit config: the customer override when set, otherwise the chart default
for the chosen format. Usage: include "newrelic-logging.fluentBit.block" (dict "root" . "key" "inputs")
*/}}
{{- define "newrelic-logging.fluentBit.block" -}}
{{- $format := include "newrelic-logging.fluentBit.format" .root -}}
{{- $value := get .root.Values.fluentBit.config .key -}}
{{- if $value -}}
{{- $value | trimAll "\n" -}}
{{- else -}}
{{- $ext := ternary "conf" "yaml" (eq $format "classic") -}}
{{- (.root.Files.Get (printf "files/fluentbit/%s/%s.%s" $format .key $ext)) | trimAll "\n" -}}
{{- end -}}
{{- end -}}

{{/*
Returns classic Fluent Bit config that logs a one-off deprecation warning when the classic format is in use.
The record goes to the pod log (stdout) and, through the New Relic output (Match *), to New Relic Logs.
*/}}
{{- define "newrelic-logging.fluentBit.classicDeprecation.config" -}}
[INPUT]
    Name          dummy
    Tag           nr.config.deprecation
    Dummy         {"level":"warn","message":"WARN: Fluent Bit classic (.conf) configuration is in use because of the fluentBit.config overrides in the newrelic-logging chart. Fluent Bit deprecates the classic format at the end of 2026. Migrate the overrides to YAML: https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging#fluent-bit-configuration-format"}
    Interval_Sec  1
    Samples       1
[OUTPUT]
    Name    stdout
    Match   nr.config.deprecation
    Format  json_lines
{{- end -}}

{{/*
Returns the fluentbit YAML pipeline inputs to collect its own metrics
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.yaml.inputs" -}}
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
{{- define "newrelic-logging.fluentBit.monitoring.yaml.filters" -}}
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
Returns the fluentbit YAML pipeline outputs to forward its own metrics to New Relic
*/}}
{{- define "newrelic-logging.fluentBit.monitoring.yaml.outputs" -}}
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
    - {{ printf "cluster_name %s" $clusterName | quote }}
    {{- else }}
    - 'cluster_name ""'
    {{- end }}
    - {{ printf "namespace %s" .Release.Namespace | quote }}
    - {{ printf "daemonset_name %s" (include "newrelic-logging.fullname" .) | quote }}
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
Returns metricsHost
*/}}
{{- define "newrelic-logging.metricsHost" -}}
{{- if .Values.metricsEndpoint -}}
{{ .Values.metricsEndpoint -}}
{{- else -}}
{{- include "newrelic-logging.failIfRegionUnresolvable" . -}}
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


