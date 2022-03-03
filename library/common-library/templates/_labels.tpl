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
