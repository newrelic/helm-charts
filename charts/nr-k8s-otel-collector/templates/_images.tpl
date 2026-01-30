{{- /*
Temporary image helper to transition from old image config structure to new structure.
Supports ATP-specific image when atp.enabled=true.
*/ -}}
{{- define "nrKubernetesOtel.images.collector.image" }}
{{- if or (.Values.image).repository (.Values.image).tag }}
   {{- (.Values.image).repository | default .Values.images.collector.repository }}:{{- (.Values.image).tag | default .Chart.AppVersion }}
{{- else if .Values.atp.enabled }}
   {{- include "newrelic.common.images.image" ( dict "imageRoot" .Values.atp.image "context" .) }}
{{- else }}
   {{- include "newrelic.common.images.image" ( dict "imageRoot" .Values.images.collector "context" .) }}
{{- end }}
{{- end }}

{{- /*
Temporary imagePullPolicy helper to transition from old image config structure to new structure.
Supports ATP-specific image pull policy when atp.enabled=true.
*/ -}}
{{- define "nrKubernetesOtel.images.collector.imagePullPolicy" }}
{{- if (.Values.image).pullPolicy }}
   {{- .Values.image.pullPolicy }}
{{- else if .Values.atp.enabled }}
   {{- .Values.atp.image.pullPolicy }}
{{- else }}
   {{- .Values.images.collector.pullPolicy }}
{{- end }}
{{- end }}