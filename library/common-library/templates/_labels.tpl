{{/*
Override common labels
*/}}
{{- define "common.labels.overrides.addLabels" -}}
{{- end }}



{{/*
Common labels
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
Override selector labels
*/}}
{{- define "common.labels.overrides.addSelectorLabels" -}}
{{- end }}



{{/*
Selector labels
*/}}
{{- define "common.labels.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.naming.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if include "common.labels.overrides.addSelectorLabels" . }}
{{ include "common.labels.overrides.addSelectorLabels" . }}
{{- end }}
{{- end }}


{{/*
Override pod labels
*/}}
{{- define "common.labels.overrides.addPodLabels" -}}
{{- end }}


{{/*
Pod labels
*/}}
{{- define "common.labels.podLabels" -}}
{{- if .Values.global }}
    {{- with .Values.global.podLabels }}
{{ toYaml . }}
    {{- end -}}
{{- end -}}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end -}}
{{- with include "common.labels.overrides.addPodLabels" . }}
{{ . }}
{{- end }}
{{- end }}
