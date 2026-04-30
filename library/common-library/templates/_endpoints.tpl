{{/*Endpoint Lookup
This function provides a region awear lookup for new relic endpoints.
It first checks for an endpoint override in the following order:
1. .Values.<key>
2. .Values.global.<key>
If no override is found, it will attempt to resolve the endpoint based on the region value.
If no endpoint override is found and the region is not supported, an error will be thrown.

All endpoints exposed to customers though NR helm charts should be defined in a dictionary in this file and wrapped with a convenience function.
See below.
*/}}

{{- define "newrelic.common.endpoints.resolve" -}}                                                                                                                                                                                    
  {{- $region := include "newrelic.common.region" .ctx -}}                                                                                                                                                                            
  {{- $endpoint := include "newrelic.common.resolve" (dict "ctx" .ctx "key" .key "default" (get .endpoints $region)) -}}
  {{- required (printf "This chart does not have support for the region provided '%s'. Please either supply an override URL via .Values.%s or .Values.global.%s, or set a different region." $region .key .key) $endpoint -}}
{{- end -}}    


{{/*-----------------------------ENDPOINTS-----------------------------*/}}

{{/* Returns the New Relic collector endpoint for this region */}}
{{- define "newrelic.common.collector_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://collector.newrelic.com"
      "EU"      "https://collector.eu.newrelic.com"
      "STG"     "https://staging-collector.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "collectorEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic infra API endpoint for this region */}}
{{- define "newrelic.common.infra_api_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://infra-api.newrelic.com"
      "EU"      "https://infra-api.eu.newrelic.com"
      "STG"     "https://staging-infra-api.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "infraApiEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic insights collector endpoint for this region */}}
{{- define "newrelic.common.insights_collector_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://insights-collector.newrelic.com"
      "EU"      "https://insights-collector.eu01.nr-data.net"
      "JP"      "https://insights-collector.jp.nr-data.net"
      "STG"     "https://staging-insights-collector.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "insightsCollectorEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic Log Api endpoint for this region */}}
{{- define "newrelic.common.log_api_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://log-api.newrelic.com"
      "EU"      "https://log-api.eu.newrelic.com"
      "STG"     "https://staging-log-api.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "logApiEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic metric API endpoint for this region */}}
{{- define "newrelic.common.metric_api_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://metric-api.newrelic.com"
      "EU"      "https://metric-api.eu.newrelic.com"
      "JP"      "https://metric-api.jp.newrelic.com"
      "STG"     "https://staging-metric-api.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "metricApiEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic OpAmp endpoint for this region */}}
{{- define "newrelic.common.opamp_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://opamp.service.newrelic.com"
      "EU"      "https://opamp.service.eu.newrelic.com"
      "STG"     "https://opamp.staging-service.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "opampEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic Otel endpoint for this region */}}
{{- define "newrelic.common.otlp_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://otlp.nr-data.net"
      "EU"      "https://otlp.eu01.nr-data.net"
      "JP"      "https://otlp.jp.nr-data.net"
      "STG"     "https://staging-otlp.nr-data.net"
      "GOV"     "https://gov-otlp.nr-data.net"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "otlpEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic public keys endpoint for this region */}}
{{- define "newrelic.common.public_keys_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://publickeys.newrelic.com"
      "EU"      "https://publickeys.eu.newrelic.com"
      "STG"     "https://staging-publickeys.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "publicKeysEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic system identity OAuth endpoint for this region */}}
{{- define "newrelic.common.system_identity_oauth_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://system-identity-oauth.service.newrelic.com"
      "EU"      "https://system-identity-oauth.service.newrelic.com"
      "JP"      "https://system-identity-oauth.service.newrelic.com"
      "STG"     "https://system-identity-oauth.staging-service.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "systemIdentityOauthEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic Synthetics Horde endpoint for this region */}}
{{- define "newrelic.common.synthetics_horde_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://synthetics-horde.nr-data.net"
      "EU"      "https://synthetics-horde.eu01.nr-data.net"
      "JP"      "https://synthetics-horde.jp.nr-data.net"
      "STG"     "https://staging-synthetics-horde.nr-data.net"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "syntheticsHordeEndpoint" "endpoints" $endpoints) -}}
{{- end -}}

{{/* Returns the New Relic trace API endpoint for this region */}}
{{- define "newrelic.common.trace_api_endpoint" -}}
  {{- $endpoints := dict
      "US"      "https://trace-api.newrelic.com"
      "EU"      "https://trace-api.eu.newrelic.com"
      "STG"     "https://staging-trace-api.newrelic.com"
  -}}
  {{- include "newrelic.common.endpoints.resolve" (dict "ctx" . "key" "traceApiEndpoint" "endpoints" $endpoints) -}}
{{- end -}}