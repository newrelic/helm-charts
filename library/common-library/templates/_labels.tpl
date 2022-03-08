{{/*
This function allows easily to add more labels to the function "common.labels"
*/}}
{{- define "common.labels.overrides.addLabels" -}}
{{- end }}



{{/*
This will render the labels that should be used in all the manifests used by the helm chart.
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.naming.chart" . }}
{{ include "common.labels.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}

{{- $global := index .Values "global" | default dict -}}

{{- with $global.labels }}
{{ toYaml . }}
{{- end }}

{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}

{{- if include "common.labels.overrides.addLabels" . }}
{{ include "common.labels.overrides.addLabels" . }}
{{- end }}
{{- end }}



{{/*
This function allows easily to add more labels to the function "common.labels.selectorLabels"
*/}}
{{- define "common.labels.overrides.addSelectorLabels" -}}
{{- end }}



{{/*
This will render the labels that should be used in deployments/daemonsets template pods as a selector.
*/}}
{{- define "common.labels.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.naming.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if include "common.labels.overrides.addSelectorLabels" . }}
{{ include "common.labels.overrides.addSelectorLabels" . }}
{{- end }}
{{- end }}



{{/*
This function allows easily to add more labels to the function "common.labels.podLabels"
*/}}
{{- define "common.labels.overrides.addPodLabels" -}}
{{- end }}



{{/*
Pod labels
*/}}
{{- define "common.labels.podLabels" -}}
{{- $global := index .Values "global" | default dict -}}

{{- with $global.podLabels }}
{{ toYaml . }}
{{- end }}

{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}

{{- with include "common.labels.overrides.addPodLabels" . }}
{{ . }}
{{- end }}
{{- end }}
