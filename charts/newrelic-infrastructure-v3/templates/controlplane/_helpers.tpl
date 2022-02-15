{{/* Returns whether the controlPlane scraper should run with hostNetwork: true based on the user configuration. */}}
{{- define "newrelic.controlPlane.hostNetwork" -}}
{{- if (get .Values.controlPlane. "hostNetwork" | kindIs "bool") -}}
    {{- if .Values.controlPlane.hostNetwork -}}
        {{/*
            We want only to return when this is true, returning `false` here will template "false" (string) when doing
            an `(include "newrelic-logging.lowDataMode" .)`, which is not an "empty string" so it is `true` if it is used
            as an evaluation somewhere else.
        */}}
        {{- .Values.controlPlane.hostNetwork -}}
    {{- end -}}
{{- else if eq .Values.controlPlane.kind "DaemonSet" -}}
    {{- if .Values.privileged -}}
        true
    {{- end -}}
{{- end -}}
{{- end -}}

{{- define "newrelic.controlPlane.computedAffinity" -}}
{{- if and (not .Values.controlPlane.affinity) (eq .Values.controlPlane.kind "DaemonSet") -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          - key: node-role.kubernetes.io/control-plane
            operator: Exists
      - matchExpressions:
          - key: node-role.kubernetes.io/controlplane
            operator: Exists
      - matchExpressions:
          - key: node-role.kubernetes.io/etcd
            operator: Exists
      - matchExpressions:
          - key: node-role.kubernetes.io/master
            operator: Exists
{{- else -}}
{{- .Values.controlPlane.affinity | toYaml -}}
{{- end -}}
{{- end -}}
