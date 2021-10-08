{{/*
Return the name key for the License Key inside the secret
*/}}
{{/*# TODO: Investigate if more characters commonly found in labels are not allowed in prometheus job names */}}
{{- define "toPrometheus" -}}
{{ . | replace "." "_" | replace "/" "_" | replace "-" "_" }}
{{- end -}}

{{- define "newrelic.prometheusOtelRelabel" -}}
# Multiple instances of `relabel_configs` are applied sequentially. If with action:keep does not match
# a target, it will be dropped immediately and subsequent configs will be noop.
- source_labels:
    # Multiple source_labels are concatenated together with `;` before checking if regex matches
    # By specifying a permissive regex we achieve a hacky OR, matching e.g `;;true;`
    {{- range .annotations }}
    - __meta_kubernetes_pod_annotation_{{ include "toPrometheus" . }}
    - __meta_kubernetes_service_annotation_{{ include "toPrometheus" . }}
    {{- end }}
    {{- range .labels }}
    - __meta_kubernetes_pod_label_{{ include "toPrometheus" . }}
    - __meta_kubernetes_service_label_{{ include "toPrometheus" . }}
    {{- end }}
  # We need to add .* in both ends to get the hacky ORing because prometheus wraps this regex
  # with ^ $ automatically. With this, it will result in ^.*true.*$
  regex: ".*true.*"
  separator: ";"
  action: keep
{{/*# TODO: Honor path and port labels somehow */}}
{{/*# read the port from "prometheus.io/port: <port>" annotation and update scraping address accordingly*/}}
{{/*# TODO: Do the same with /scheme and /path?*/}}
{{/*- source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]*/}}
{{/*  action: replace*/}}
{{/*  target_label: __address__*/}}
{{/*  regex: ([^:]+)(?::\d+)?;(\d+)*/}}
{{/*  # escaped $1:$2*/}}
{{/*  replacement: $$1:$$2*/}}
# Keep meta labels regarding k8s objects
- source_labels: [__meta_kubernetes_namespace]
  action: replace
  target_label: kubernetes_namespace

- source_labels: [__meta_kubernetes_pod_name]
  action: replace
  target_label: kubernetes_pod_name

- source_labels: [__meta_kubernetes_pod_container_name]
  action: replace
  target_label: kubernetes_pod_container_name

- source_labels: [__meta_kubernetes_pod_node_name]
  action: replace
  target_label: kubernetes_pod_node_name

- source_labels: [__meta_kubernetes_service_name]
  action: replace
  target_label: kubernetes_service_name
{{- end -}}
