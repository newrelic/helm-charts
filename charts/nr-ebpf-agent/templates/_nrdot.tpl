{{/*
Effective Kubernetes-infrastructure (nrdot collector) enablement.
Returns "true" (truthy) when either the granular `nrdotCollector.enabled` is set
OR the `infra.enabled` UX alias is set; otherwise "" (falsy). Every template that
gates on the collector must go through this so the alias is honored everywhere.
*/}}
{{- define "nr-ebpf-agent.nrdotCollector.enabled" -}}
{{- if or .Values.nrdotCollector.enabled (default dict .Values.infra).enabled -}}true{{- end -}}
{{- end -}}

{{/*
Effective REPORT_INFRA value for the eBPF agent.
An explicit, non-empty `reportInfra` always wins. When it is left empty (default),
derive it from the `infra.enabled` alias: "auto" when infra is enabled (so eBPF host
stats replace the infra agent's HOST entity), "false" otherwise.
*/}}
{{- define "nr-ebpf-agent.reportInfra" -}}
{{- $ri := .Values.reportInfra | toString -}}
{{- if $ri -}}
{{- $ri -}}
{{- else if (default dict .Values.infra).enabled -}}
auto
{{- else -}}
false
{{- end -}}
{{- end -}}

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
Return the kubectl image reference for the nrdot-get-allocatable init container.
Precedence: local (nrdotCollector.kubectlImage.registry) > global > docker.io
*/}}
{{- define "nr-ebpf-agent.nrdot.kubectlImage" -}}
{{- $registry := .Values.nrdotCollector.kubectlImage.registry -}}
{{- if not $registry -}}
  {{- if and .Values.global .Values.global.images .Values.global.images.registry -}}
    {{- $registry = .Values.global.images.registry -}}
  {{- else -}}
    {{- $registry = "docker.io" -}}
  {{- end -}}
{{- end -}}
{{- printf "%s/%s:%s" $registry .Values.nrdotCollector.kubectlImage.repository .Values.nrdotCollector.kubectlImage.tag -}}
{{- end -}}

{{/*
Return the kubectl init-container imagePullPolicy.
Precedence: local > global > IfNotPresent
*/}}
{{- define "nr-ebpf-agent.nrdot.kubectlImagePullPolicy" -}}
{{- if .Values.nrdotCollector.kubectlImage.pullPolicy -}}
  {{- .Values.nrdotCollector.kubectlImage.pullPolicy -}}
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
{{- with $ctx.Values.nrdotCollector.goGC }}
- name: GOGC
  value: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Discovery-portal config injection into the nrdot collector config. `extraConfig`
is a merge-delta spliced into the base config blocks (portal supplies at least
`receivers`+`pipelines`; each pipeline targets `routing` for multi-account, else
`otlphttp/acct-default`). Splices are $direct-gated in the config templates, so
nothing is injected in (unsupported) agent mode.
Helpers take a dict: { "ctx": $, "roleKey": "sidecar" | "clusterCollector" }.
*/}}

{{/*
extraConfig section (receivers|processors|exporters|connectors|pipelines|
extensions) as YAML, or empty string when unset. Call with an extra
"section" key in the dict.
*/}}
{{- define "nr-ebpf-agent.nrdot.extraConfig.section" -}}
{{- $v := dig .roleKey "configMap" "extraConfig" .section dict .ctx.Values.nrdotCollector -}}
{{- if $v }}{{ toYaml $v }}{{ end -}}
{{- end -}}

{{/*
Portal-supplied service::extensions as a leading-comma CSV (", a, b"), for
appending to the base `[health_check]` flow list. Empty string when unset.
*/}}
{{- define "nr-ebpf-agent.nrdot.extraConfig.serviceExtensionsCsv" -}}
{{- $v := dig .roleKey "configMap" "extraConfig" "service" "extensions" list .ctx.Values.nrdotCollector -}}
{{- range $e := $v }}, {{ $e }}{{ end -}}
{{- end -}}

{{/*
Credential env/envFrom for the nrdot collector containers, satisfying `${env:...}`
refs in portal receiver configs. Per-role knobs under nrdotCollector.<role>:
extraEnv (raw env list), extraEnvFrom (raw envFrom), secretEnv (KV map the chart
turns into a Secret + envFrom; plaintext in values, same posture as licenseKey).
*/}}

{{/* Name of the chart-managed credential Secret for a role. */}}
{{- define "nr-ebpf-agent.nrdot.envSecretName" -}}
{{- $suffix := ternary "cluster" "sidecar" (eq .roleKey "clusterCollector") -}}
{{- printf "%s-nrdot-%s-env" (include "nr-ebpf-agent.fullname" .ctx) $suffix -}}
{{- end -}}

{{/* Raw extra env entries (list) for a collector container, YAML or empty. */}}
{{- define "nr-ebpf-agent.nrdot.extraEnv" -}}
{{- $e := dig .roleKey "extraEnv" list .ctx.Values.nrdotCollector -}}
{{- if $e }}{{ toYaml $e }}{{ end -}}
{{- end -}}

{{/*
envFrom entries for a collector container: user `extraEnvFrom` plus a secretRef
to the chart-managed credential Secret when `secretEnv` is non-empty. YAML or empty.
*/}}
{{- define "nr-ebpf-agent.nrdot.envFrom" -}}
{{- $ef := dig .roleKey "extraEnvFrom" list .ctx.Values.nrdotCollector -}}
{{- $se := dig .roleKey "secretEnv" dict .ctx.Values.nrdotCollector -}}
{{- if $se -}}
{{- $ef = append $ef (dict "secretRef" (dict "name" (include "nr-ebpf-agent.nrdot.envSecretName" (dict "ctx" .ctx "roleKey" .roleKey)))) -}}
{{- end -}}
{{- if $ef }}{{ toYaml $ef }}{{ end -}}
{{- end -}}
