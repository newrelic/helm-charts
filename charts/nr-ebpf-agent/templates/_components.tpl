{{/*
Per-component default values.

Helm only auto-loads values.yaml, which holds the settings shared by all
components. Each component keeps its defaults in its own file under
components/ (ebpf-agent.yaml, nrdot.yaml, obi.yaml, profiler.yaml, ...).
"nr-ebpf-agent.loadComponentDefaults" merges those files UNDER .Values, so
anything the user sets (values.yaml overrides, -f, --set, parent charts such as
nri-bundle, Agent Control) always takes precedence. Component files only fill
the keys the user didn't set.

Every template that reads .Values must start with:
  {{- include "nr-ebpf-agent.loadComponentDefaults" . -}}
The merge only fills missing keys, so it is idempotent: calling it from every
template is cheap and means template render order doesn't matter.

Adding a component: create components/<name>.yaml with a single top-level
key (e.g. `foo:`). Two component files may not define the same top-level key.
Shared, cross-component settings belong in values.yaml.
*/}}
{{- define "nr-ebpf-agent.loadComponentDefaults" -}}
{{- $owners := dict -}}
{{- range $path, $_ := .Files.Glob "components/*.yaml" -}}
  {{- $defaults := $.Files.Get $path | fromYaml -}}
  {{- if hasKey $defaults "Error" -}}
    {{- fail (printf "nr-ebpf-agent: cannot parse %s: %s" $path $defaults.Error) -}}
  {{- end -}}
  {{- range $key, $_ := $defaults -}}
    {{- if hasKey $owners $key -}}
      {{- fail (printf "nr-ebpf-agent: key %q is defined in both %s and %s; each top-level key must belong to one component file" $key (get $owners $key) $path) -}}
    {{- end -}}
    {{- $_ := set $owners $key $path -}}
  {{- end -}}
  {{- include "nr-ebpf-agent.mergeDefaults" (dict "dst" $.Values "src" $defaults) -}}
{{- end -}}
{{- end -}}

{{/*
Deep-merge "src" (defaults) into "dst" (user values), in place. A key is
copied only when dst doesn't have it, and maps are merged recursively. dst
values always win, including false, 0 and "". That's why this doesn't use
sprig merge/mergeOverwrite: those treat such values as empty, so e.g. a user's
`obi.enabled: false` would be replaced by a default of true.
*/}}
{{- define "nr-ebpf-agent.mergeDefaults" -}}
{{- $dst := .dst -}}
{{- range $key, $default := .src -}}
  {{- if and (not (hasKey $dst $key)) (kindIs "invalid" $default) -}}
    {{- /* null default, e.g. `nrdotCollector.lowDataMode:` (deepCopy panics on nil) */ -}}
    {{- $_ := set $dst $key $default -}}
  {{- else if not (hasKey $dst $key) -}}
    {{- $_ := set $dst $key (deepCopy $default) -}}
  {{- else if and (kindIs "map" $default) (kindIs "map" (get $dst $key)) -}}
    {{- include "nr-ebpf-agent.mergeDefaults" (dict "dst" (get $dst $key) "src" $default) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
