{{/*
This function allows easily to add more labels to the function "common.labels"
*/}}
{{- define "common.labels.overrides.addLabels" -}}
{{- end }}



{{/*
This will render the labels that should be used in all the manifests used by the helm chart.
*/}}
{{- define "common.labels" -}}
{{- $global := index .Values "global" | default dict -}}

{{- $chart := dict "helm.sh/chart" (include "common.naming.chart" . ) -}}
{{- $managedBy := dict "app.kubernetes.io/managed-by" .Release.Service -}}
{{- $selectorLabels := fromYaml (include "common.labels.selectorLabels" . ) -}}

{{- $labels := mustMergeOverwrite $chart $managedBy $selectorLabels -}}
{{- if .Chart.AppVersion -}}
{{- $labels = mustMergeOverwrite $labels (dict "app.kubernetes.io/version" .Chart.AppVersion) -}}
{{- end -}}

{{- $globalUserLabels := $global.labels | default dict -}}
{{- $localUserLabels := .Values.labels | default dict -}}
{{- $addLabelsOverride := fromYaml (include "common.labels.overrides.addLabels" . ) -}}

{{- $labels = mustMergeOverwrite $labels $globalUserLabels $localUserLabels $addLabelsOverride -}}

{{- toYaml $labels -}}
{{- end -}}



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
