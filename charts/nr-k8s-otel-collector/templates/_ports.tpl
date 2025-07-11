{{/* Build the list of port for the DaemonSet pods */}}
{{- define "nrKubernetesOtel.daemonset.ports" -}}
{{- if get .Values.daemonset "ports" | kindIs "map" -}}
{{- $ports := deepCopy .Values.daemonset.ports -}}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Build the list of port for the Deployment pod */}}
{{- define "nrKubernetesOtel.deployment.ports" -}}
{{- if get .Values.deployment "ports" | kindIs "map" -}}
{{- $ports := deepCopy .Values.deployment.ports -}}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}