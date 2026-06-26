{{/*
Return the nrdot collector image reference.
Precedence: local registry (nrdotCollector.image.registry) > global (global.images.registry) > docker.io
*/}}
{{- define "nr-ebpf-agent.nrdot.image" -}}
{{- $registry := .Values.nrdotCollector.image.registry -}}
{{- if not $registry -}}
  {{- if and .Values.global .Values.global.images .Values.global.images.registry -}}
    {{- $registry = .Values.global.images.registry -}}
  {{- else -}}
    {{- $registry = "docker.io" -}}
  {{- end -}}
{{- end -}}
{{- printf "%s/%s:%s" $registry .Values.nrdotCollector.image.repository .Values.nrdotCollector.image.tag -}}
{{- end -}}

{{/*
Return the nrdot collector imagePullPolicy.
Precedence: local (nrdotCollector.image.pullPolicy) > global (global.images.pullPolicy) > IfNotPresent
*/}}
{{- define "nr-ebpf-agent.nrdot.imagePullPolicy" -}}
{{- if .Values.nrdotCollector.image.pullPolicy -}}
  {{- .Values.nrdotCollector.image.pullPolicy -}}
{{- else if and .Values.global (hasKey .Values.global "images") (hasKey .Values.global.images "pullPolicy") .Values.global.images.pullPolicy -}}
  {{- .Values.global.images.pullPolicy -}}
{{- else -}}
  {{- "IfNotPresent" -}}
{{- end -}}
{{- end -}}

{{/*
nrdot pernode config name (DaemonSet sidecar).
*/}}
{{- define "nr-ebpf-agent.nrdot.configName.pernode" -}}
{{- printf "%s-nrdot-pernode" (include "nr-ebpf-agent.fullname" .) -}}
{{- end -}}

{{/*
nrdot cluster config name (Deployment).
*/}}
{{- define "nr-ebpf-agent.nrdot.configName.cluster" -}}
{{- printf "%s-nrdot-cluster" (include "nr-ebpf-agent.fullname" .) -}}
{{- end -}}

{{/*
Cluster name (local `cluster` or `global.cluster`).
*/}}
{{- define "nr-ebpf-agent.nrdot.clusterName" -}}
{{- if .Values.global }}{{ .Values.global.cluster | default .Values.cluster }}{{ else }}{{ .Values.cluster }}{{ end -}}
{{- end -}}

{{/*
Per-account license-key env vars for nrdot direct mode (NR_INGEST_KEY_<i>), sourced
from the chart Secret. Index-aligned (sorted namespaces) with the generated config
and the Secret data keys. Reused by the sidecar and the cluster Deployment.
Emit at column 0; call with `| nindent <n>`.
*/}}
{{- define "nr-ebpf-agent.nrdot.perAccountKeyEnv" -}}
{{- range $i, $ns := (keys .Values.namespaceLicenseKeys | sortAlpha) }}
- name: NR_INGEST_KEY_{{ $i }}
  valueFrom:
    secretKeyRef:
      name: nr-ebpf-agent-secrets
      key: NR_INGEST_KEY_{{ $i }}
{{- end }}
{{- end -}}

{{/*
Mode-aware egress env for an nrdot collector container.
Pass a dict: { "ctx": $, "agentEndpoint": "<host:port>" }.
  agent mode  -> AGENT_OTLP_ENDPOINT=<agentEndpoint>
  direct mode -> NR_OTLP_ENDPOINT + NEW_RELIC_LICENSE_KEY + NR_INGEST_KEY_<i>
Emit at column 0; call with `| nindent <n>`.
*/}}
{{- define "nr-ebpf-agent.nrdot.egressEnv" -}}
{{- $ctx := .ctx -}}
{{- if eq $ctx.Values.nrdotCollector.egressMode "direct" }}
- name: NR_OTLP_ENDPOINT
  value: {{ include "newrelic.common.otlp_endpoint" $ctx }}
- name: NEW_RELIC_LICENSE_KEY
  valueFrom:
    secretKeyRef:
      name: nr-ebpf-agent-secrets
      key: NEW_RELIC_LICENSE_KEY
{{ include "nr-ebpf-agent.nrdot.perAccountKeyEnv" $ctx }}
{{- else }}
- name: AGENT_OTLP_ENDPOINT
  value: {{ .agentEndpoint | quote }}
{{- end }}
{{- end -}}
