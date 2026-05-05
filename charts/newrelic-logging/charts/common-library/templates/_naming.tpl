{{/*
This is an function to be called directly with a string just to truncate strings to
63 chars because some Kubernetes name fields are limited to that.
*/}}
{{- define "newrelic.common.naming.truncateToDNS" -}}
{{- . | trunc 63 | trimSuffix "-" }}
{{- end }}



{{- /*
Given a name and a suffix returns a 'DNS Valid' which always include the suffix, truncating the name if needed.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If suffix is too long it gets truncated but it always takes precedence over name, so a 63 chars suffix would suppress the name.
Usage:
{{ include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "<my-name>" "suffix" "my-suffix" ) }}
*/ -}}
{{- define "newrelic.common.naming.truncateToDNSWithSuffix" -}}
{{- $suffix := (include "newrelic.common.naming.truncateToDNS" .suffix) -}}
{{- $maxLen := (max (sub 63 (add1 (len $suffix))) 0) -}} {{- /* We prepend "-" to the suffix so an additional character is needed */ -}}

{{- $newName := .name | trunc ($maxLen | int) | trimSuffix "-"  -}}
{{- if $newName -}}
{{- printf "%s-%s" $newName $suffix -}}
{{- else -}}
{{ $suffix }}
{{- end -}}

{{- end -}}



{{/*
Expand the name of the chart.
Uses the Chart name by default if nameOverride is not set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.name" -}}
{{- $name := .Values.nameOverride | default .Chart.Name -}}
{{- include "newrelic.common.naming.truncateToDNS" $name -}}
{{- end }}



{{/*
Create a default fully qualified app name.
By default the full name will be "<release_name>" just in if it has the chart name included in that, if not
it will be concatenated like "<release_name>-<chart_chart>". This could change if fullnameOverride or
nameOverride are set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.fullname" -}}
{{- $name := include "newrelic.common.naming.name" . -}}

{{- if .Values.fullnameOverride -}}
    {{- $name = .Values.fullnameOverride  -}}
{{- else if not (contains $name .Release.Name) -}}
    {{- $name = printf "%s-%s" .Release.Name $name -}}
{{- end -}}

{{- include "newrelic.common.naming.truncateToDNS" $name -}}

{{- end -}}



{{/*
Create chart name and version as used by the chart label.
This function should not be used for naming objects. Use "common.naming.{name,fullname}" instead.
*/}}
{{- define "newrelic.common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}
