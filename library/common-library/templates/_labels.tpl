{{/*
Override common labels
*/}}
{{- define "common.labels.overrideLabels" -}}
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
{{- if include "common.labels.overrideLabels" . }}
{{ include "common.labels.overrideLabels" . }}
{{- end }}
{{- end }}



{{/*
Override selector labels
*/}}
{{- define "common.labels.overrideSelectorLabels" -}}
{{- end }}



{{/*
Selector labels
*/}}
{{- define "common.labels.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.naming.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if include "common.labels.overrideSelectorLabels" . }}
{{ include "common.labels.overrideSelectorLabels" . }}
{{- end }}
{{- end }}
