{{/* Build the list of port for the DaemonSet pods */}}
{{- define "nrKubernetesOtel.daemonset.ports" -}}
{{- $ports := deepCopy .Values.daemonset.ports -}}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
{{- end}}
{{- end }}
{{- end }}

{{/* Build the list of port for the Deployment pod */}}
{{- define "nrKubernetesOtel.deployment.ports" -}}
{{- $ports := deepCopy .Values.deployment.ports -}}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
{{- end}}
{{- end }}
{{- end }}