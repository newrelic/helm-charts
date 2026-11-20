{{/*
Protected values: keys the chart manages itself inside user-editable maps.

Users may add their own entries to the component env maps (`ebpfAgent.env`,
`nrdotCollector.env`, `obi.env`, `profiler.env`). Some of those keys are set by the chart (OTLP endpoint and headers, license key, cluster
name, ...) and must never be replaced. If a user sets one, the chart drops the user's
value, keeps its own, and prints a WARNING in the install/upgrade notes (NOTES.txt).

This registry lives in a template, not in values, so users can't override it.

To protect a new field:
  - New chart-managed key in an existing map: add it to `keys`, or add a regex to
    `patterns` if the chart generates the name.
  - New user-editable map (any component, e.g. `foo.env`): add an entry keyed
    by its values path, then read the map in the template through
    "nr-ebpf-agent.protected.userMap" instead of `.Values.<path>`:
      {{- $env := dict }}
      {{- include "nr-ebpf-agent.protected.userMap" (dict "context" . "path" "foo.env" "into" $env) }}
      {{- range $name, $value := $env }} ... {{- end }}
    NOTES.txt picks up every entry automatically.

Component defaults (components/*.yaml) must not contain protected keys; the
"NOTES is empty by default" unit test catches that.
*/}}
{{- define "nr-ebpf-agent.protectedValues" -}}
# OBI container (templates/nr-ebpf-agent-obi-daemonset.yaml).
obi.env:
  keys:
    - OTEL_EXPORTER_OTLP_ENDPOINT
    - OTEL_EXPORTER_OTLP_HTTP_ENDPOINT
    - OTEL_EXPORTER_OTLP_PROTOCOL
    - OTEL_EXPORTER_OTLP_HEADERS
    - NEW_RELIC_LICENSE_KEY
    - OTEL_EBPF_KUBE_CLUSTER_NAME

# eBPF agent container (templates/nr-ebpf-agent-daemonset.yaml). Nothing protected:
# every ebpfAgent.env entry is applied (OTLP_ENDPOINT, METADATA_ENDPOINT and TLS_ENABLED
# replace the chart's values). Add keys here if that changes.
ebpfAgent.env:
  keys: []

# nrdot collector containers: per-node DaemonSet and cluster Deployment
# (templates/nr-ebpf-agent-nrdot-pernode-daemonset.yaml, nr-ebpf-agent-nrdot-deployment.yaml,
# egress env from "nr-ebpf-agent.nrdot.egressEnv" in _nrdot.tpl).
nrdotCollector.env:
  keys:
    - K8S_NODE_NAME
    - CLUSTER_NAME
    - NR_OTLP_ENDPOINT
    - NEW_RELIC_LICENSE_KEY
    # Set from nrdotCollector.goGC.
    - GOGC
  patterns:
    # Per-account keys from namespaceLicenseKeys (NR_INGEST_KEY_<i>).
    - '^NR_INGEST_KEY_'

# Profiler container (templates/nr-ebpf-agent-profiler-daemonset.yaml).
profiler.env:
  keys:
    - PROFILER_OTLP_ENDPOINT
{{- end -}}

{{/*
Returns "true" if (dict "rule" <registry entry> "key" <key>) names a protected key.
*/}}
{{- define "nr-ebpf-agent.protected.isProtected" -}}
{{- if has .key (.rule.keys | default list) -}}
  true
{{- else -}}
  {{- range (.rule.patterns | default list) -}}
    {{- if regexMatch . $.key -}}true{{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Splits the user's map at a values path into its allowed and protected keys.
Args (dict): context (root), path (e.g. "obi.env"), allowed (dict to fill),
dropped (dict to fill). Fills the dicts in place, so value types are preserved.
*/}}
{{- define "nr-ebpf-agent.protected.split" -}}
{{- $rule := get (include "nr-ebpf-agent.protectedValues" . | fromYaml) .path | default dict -}}
{{- $node := .context.Values -}}
{{- range $segment := splitList "." .path -}}
  {{- if kindIs "map" $node -}}
    {{- $node = get $node $segment -}}
  {{- end -}}
{{- end -}}
{{- if kindIs "map" $node -}}
  {{- range $key, $value := $node -}}
    {{- if include "nr-ebpf-agent.protected.isProtected" (dict "rule" $rule "key" $key) -}}
      {{- $_ := set $.dropped $key $value -}}
    {{- else -}}
      {{- $_ := set $.allowed $key $value -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Fills (dict "into") with the user's map at (dict "path"), minus the keys the
chart manages. Use this instead of reading the map from .Values directly.
*/}}
{{- define "nr-ebpf-agent.protected.userMap" -}}
{{- include "nr-ebpf-agent.protected.split" (dict "context" .context "path" .path "allowed" .into "dropped" dict) -}}
{{- end -}}

{{/*
One WARNING line per protected key the user set, across every registry entry,
sorted. Empty when nothing was ignored. Rendered by NOTES.txt.
*/}}
{{- define "nr-ebpf-agent.protected.warnings" -}}
{{- $root := . -}}
{{- range $path := include "nr-ebpf-agent.protectedValues" . | fromYaml | keys | sortAlpha -}}
  {{- $dropped := dict -}}
  {{- include "nr-ebpf-agent.protected.split" (dict "context" $root "path" $path "allowed" dict "dropped" $dropped) -}}
  {{- range $key := keys $dropped | sortAlpha }}
WARNING: '{{ $path }}.{{ $key }}' is managed by the chart and was ignored; your value was not applied. Configure it through the chart's settings instead.
  {{- end -}}
{{- end -}}
{{- end -}}
