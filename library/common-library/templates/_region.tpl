{{/*
Return the region that is being used by the user
*/}}
{{- define "newrelic.common.region" -}}
{{- if and (include "newrelic.common.license._usesCustomSecret" .) (not (include "newrelic.common.region._fromValues" .)) -}}
  {{- fail "This Helm Chart is not able to compute the region. You must specify a .global.region or .region if the license is set using a custom secret." -}}
{{- end -}}

{{- /* Defaults */ -}}
{{- $region := "us" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  {{- $region = "stg" -}}
{{- else if include "newrelic.common.fedramp.enabled" . -}}
  {{- $region = "gov" -}}
{{- else if include "newrelic.common.region._isEULicenseKey" . -}}
  {{- $region = "eu" -}}
{{- else if include "newrelic.common.region._isJPLicenseKey" . -}}
  {{- $region = "jp" -}}
{{- end -}}

{{- include "newrelic.common.region.validate" (include "newrelic.common.region._fromValues" . | default $region ) -}}
{{- end -}}



{{/*
Returns the region from the values if valid. This only return the value from the `values.yaml`.
More intelligence should be used to compute the region.

Usage: `include "newrelic.common.region.validate" "us"`
*/}}
{{- define "newrelic.common.region.validate" -}}
{{- /* Ref: https://github.com/newrelic/newrelic-client-go/blob/cbe3e4cf2b95fd37095bf2ffdc5d61cffaec17e2/pkg/region/region_constants.go#L8-L21 */ -}}
{{- $region := . | lower -}}
{{- if eq $region "us" -}}
  US
{{- else if eq $region "eu" -}}
  EU
{{- else if eq $region "jp" -}}
  JP
{{- else if eq $region "stg" -}}
  STG
{{- else if eq $region "gov" -}}
  GOV
{{- else if eq $region "dev" -}}
  DEV
{{- else -}}
  {{- fail (printf "the region provided is not valid: %s not in \"US\" \"EU\" \"JP\" \"GOV\" \"STG\" \"DEV\"" .) -}}
{{- end -}}
{{- end -}}


{{/*
Returns the region from the values. This only return the value from the `values.yaml`.
More intelligence should be used to compute the region.
This helper is for internal use.
*/}}
{{- define "newrelic.common.region._fromValues" -}}
{{- include "newrelic.common.resolve" (dict "ctx" . "key" "region") -}}
{{- end -}}



{{/*
Return empty string (falsehood) or "true" if the license is for EU region.
This helper is for internal use.
*/}}
{{- define "newrelic.common.region._isEULicenseKey" -}}
{{- if not (include "newrelic.common.license._usesCustomSecret" .) -}}
  {{- $license := include "newrelic.common.license._licenseKey" . -}}
  {{- if hasPrefix "eu" $license -}}
    true
  {{- end -}}
{{- end -}}
{{- end -}}


{{/*
Returns "true" if the license key is for Japan region or empty string (falsehood) if not.
This helper is for internal use.
*/}}
{{- define "newrelic.common.region._isJPLicenseKey" -}}
{{- if not (include "newrelic.common.license._usesCustomSecret" .) -}}
  {{- $license := include "newrelic.common.license._licenseKey" . -}}
  {{- if hasPrefix "jpx" $license -}}
    true
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is US or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_us" -}}
{{- if eq (include "newrelic.common.region" .) "US" -}}
true
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is EU or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_eu" -}}
{{- if eq (include "newrelic.common.region" .) "EU" -}}
true
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is Japan or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_jp" -}}
{{- if eq (include "newrelic.common.region" .) "JP" -}}
true
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is GOV (FedRAMP) or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_gov" -}}
{{- if eq (include "newrelic.common.region" .) "GOV" -}}
true
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is STG (staging) or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_stg" -}}
{{- if eq (include "newrelic.common.region" .) "STG" -}}
true
{{- end -}}
{{- end -}}

{{/* Returns "true" if the region is DEV (Development) or empty string (falsehood) if not. */}}
{{- define "newrelic.common.region.is_dev" -}}
{{- if eq (include "newrelic.common.region" .) "DEV" -}}
true
{{- end -}}
{{- end -}}
