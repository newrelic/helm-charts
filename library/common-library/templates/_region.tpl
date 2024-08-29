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
  {{- $region = "staging" -}}
{{- else if include "newrelic.common.region._isEULicenseKey" . -}}
  {{- $region = "eu" -}}
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
{{- else if eq $region "staging" -}}
  Staging
{{- else if eq $region "local" -}}
  Local
{{- else -}}
  {{- fail (printf "the region provided is not valid: %s not in \"US\" \"EU\" \"Staging\" \"Local\"" .) -}}
{{- end -}}
{{- end -}}



{{/*
Returns the region from the values. This only return the value from the `values.yaml`.
More intelligence should be used to compute the region.
This helper is for internal use.
*/}}
{{- define "newrelic.common.region._fromValues" -}}
{{- if .Values.region -}}
  {{- .Values.region -}}
{{- else if .Values.global -}}
  {{- if .Values.global.region -}}
    {{- .Values.global.region -}}
  {{- end -}}
{{- end -}}
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
