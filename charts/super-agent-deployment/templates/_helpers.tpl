{{- /*
Return the name of the configMap holding the Super Agent's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-super-agent.config.name" -}}
{{- .Values.config.superAgent.name | default (include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "superagent-config" )) -}}
{{- end -}}


{{- /*
Return the key name of the configMap holding the Super Agent's config. Defaults to "config.yaml"
*/ -}}
{{- define "newrelic-super-agent.config.key" -}}
{{- .Values.config.superAgent.key | default "config.yaml" -}}
{{- end -}}


{{- /*
Builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config.content" -}}
{{- /*
This snippet should execute always to block all unsupported features from the common-lirary that are not yet supported
by this chart.

TODO: Remove this file when the Super Agent supports licensekey as an envVar.
*/ -}}
{{ $licenseKey := include "newrelic.common.license._licenseKey" . }}
{{- if or (include "newrelic.common.license._customSecretName" .) (include "newrelic.common.license._customSecretKey" .) -}}
    {{- fail "Common library supports setting an external custom secret for the license but the super agent still does not support the license by an env var. You must specify a .licenseKey or .global.licenseKey" -}}
{{- end -}}

{{- /*
TODO: There are a lot of TODOs to be made in this chart yet and some of them are going to impact the YAML that holds 
the config.

If you need a list of TODOs, just `grep TODO` on the `values.yaml` and look for things that are yet to be implemented.
*/ -}}
{{- $config := .Values.config.superAgent.content | default dict -}}
{{- $config = mustMergeOverwrite (dict "k8s" (dict "cluster_name" (include "newrelic.common.cluster" .))) $config -}}
{{- $config = mustMergeOverwrite (dict "k8s" (dict "namespace" .Release.Namespace)) $config -}}
{{- $config | toYaml -}}
{{- end -}}

{{- /* These are the defaults that are used for all the containers in this chart */ -}}
{{- define "newrelic-super-agent.securityContext.containerDefaults" -}}
runAsUser: 1000
runAsGroup: 2000
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
{{- end -}}

{{- /* Allow to change pod defaults dynamically */ -}}
{{- define "newrelic-super-agent.securityContext.container" -}}
{{- $defaults := fromYaml ( include "newrelic-super-agent.securityContext.containerDefaults" . ) -}}
{{- $commonLibrary := include "newrelic.common.securityContext.container" . | fromYaml -}}

{{- if $commonLibrary -}}
    {{- toYaml $commonLibrary -}}
{{- else -}}
    {{- toYaml $defaults -}}
{{- end -}}
{{- end -}}
