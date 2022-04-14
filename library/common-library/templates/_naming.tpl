{{/*
This is an function to be called directly with a string just to truncate strings to
63 chars because some Kubernetes name fields are limited to that.
*/}}
{{- define "newrelic.common.naming.trucateToDNS" -}}
{{- . | trunc 63 | trimSuffix "-" }}
{{- end }}



{{- /*
Given a name and a suffix returns a 'DNS Valid' which always include the suffix, truncating the name if needed.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
It fails if suffix is too long to fint in the limit set.
Usage:
{{ include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "<my-name>" "suffix" "my-suffix" ) }}
*/ -}}
{{- define "newrelic.common.naming.truncateToDNSWithSuffix" -}}
{{- $maxLen := (sub 63 (len .suffix)) -}}

{{- if (lt $maxLen 1) -}}
    {{ fail (printf "The suffix chosen (%s) is hitting the Kubernetes limit of 63 chars for the object name. We cannot create %s-%s" .suffix .name .suffix) }}
{{- end -}}

{{- $newName := .name | trunc ($maxLen | int) | trimSuffix "-"  -}}
{{- printf "%s-%s" $newName .suffix -}}

{{- end -}}



{{/*
Expand the name of the chart.
Uses the Chart name by default if nameOverride is not set.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "newrelic.common.naming.name" -}}
{{- $name := .Values.nameOverride | default .Chart.Name -}}
{{- include "newrelic.common.naming.trucateToDNS" $name -}}
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

{{- include "newrelic.common.naming.trucateToDNS" $name -}}

{{- end -}}



{{/*
Create chart name and version as used by the chart label.
This function should not be used for naming objects. Use "common.naming.{name,fullname}" instead.
*/}}
{{- define "newrelic.common.naming.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}
