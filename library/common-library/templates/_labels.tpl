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

{{- $labels = mustMergeOverwrite $labels $globalUserLabels $localUserLabels -}}

{{- toYaml $labels -}}
{{- end -}}



{{/*
This will render the labels that should be used in deployments/daemonsets template pods as a selector.
*/}}
{{- define "common.labels.selectorLabels" -}}
{{- $name := dict "app.kubernetes.io/name" ( include "common.naming.name" . ) -}}
{{- $instance := dict "app.kubernetes.io/instance" .Release.Name -}}

{{- $selectorLabels := mustMergeOverwrite $name $instance -}}

{{- toYaml $selectorLabels -}}
{{- end }}



{{/*
Pod labels
*/}}
{{- define "common.labels.podLabels" -}}
{{- $selectorLabels := fromYaml (include "common.labels.selectorLabels" . ) -}}

{{- $global := index .Values "global" | default dict -}}
{{- $globalPodLabels := $global.podLabels | default dict }}

{{- $localPodLabels := .Values.podLabels | default dict }}

{{- $podLabels := mustMergeOverwrite $selectorLabels $globalPodLabels $localPodLabels -}}

{{- toYaml $podLabels -}}
{{- end }}
