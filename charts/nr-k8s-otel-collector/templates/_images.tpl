{{- /*
Temporary image helper to transition from old image config structure to new structure.
*/ -}}
{{- define "nrKubernetesOtel.images.collector.image" }}
{{- if or (.Values.image).repository (.Values.image).tag }}
   {{- (.Values.image).repository | default .Values.images.collector.repository }}:{{- (.Values.image).tag | default .Chart.AppVersion }}
{{- else }}
   {{- if .Values.nrdot_plus.enabled }}
   {{- include "newrelic.common.images.image" ( dict "imageRoot" .Values.nrdot_plus.image "context" .) }}
   {{- else }}
   {{- include "newrelic.common.images.image" ( dict "imageRoot" .Values.images.collector "context" .) }}
   {{- end }}
{{- end }}
{{- end }}

{{- /*
Temporary imagePullPolicy helper to transition from old image config structure to new structure.
*/ -}}
{{- define "nrKubernetesOtel.images.collector.imagePullPolicy" }}
{{- if (.Values.image).pullPolicy }}
   {{- .Values.image.pullPolicy }}
{{- else }}
   {{- .Values.images.collector.pullPolicy }}
{{- end }}
{{- end }}