{{- /*
Return the name of the configMap holding the Super Agent's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-super-agent.config.name" -}}
{{- .Values.config.name | default (include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "config" )) -}}
{{- end -}}


{{- /*
Return the key name of the configMap holding the Super Agent's config. Defaults to "config.yaml"
*/ -}}
{{- define "newrelic-super-agent.config.key" -}}
{{- .Values.config.key | default "config.yaml" -}}
{{- end -}}


{{- /*
This function simply templates the default configuration for the agent.
*/ -}}
{{- define "newrelic-super-agent.config.defaultConfig" -}}
opamp:
  endpoint: COMPLETE-ME
  headers:
    api-key: COMPLETE-ME
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
{{- if not $licenseKey -}}
    {{- fail "You must specify .licenseKey or .global.licenseKey" -}}
{{- end -}}

{{- /*
TODO: There are a lot of TODOs to be made in this chart yet and some of them are going to impact the YAML that holds 
the config.

If you need a list of TODOs, just `grep TODO` on the `values.yaml` and look for things that are yet to be implemented.
*/ -}}
{{- $config := fromYaml (include "newrelic-super-agent.config.defaultConfig" .) -}}
{{- if .Values.config.content -}}
  {{- $_ := deepCopy .Values.config.content | mustMergeOverwrite $config -}}
{{- end -}}

{{- if include "newrelic.common.fedramp.enabled" . -}}
    {{- fail "FedRAMP is not supported yet" -}}{{- /* TODO: Add FedRamp support */ -}}
{{- else if include "newrelic.common.nrStaging" .  -}}
    {{- $_ := set $config.opamp "endpoint" "https://opamp.staging-service.newrelic.com/v1/opamp" -}}
{{- else -}}
    {{- /* TODO: Is this the prod URL?  */ -}}
    {{- $_ := set $config.opamp "endpoint" "https://opamp.service.newrelic.com/v1/opamp" -}}
{{- end -}}

{{- /* We have to use common library internals because the agent does not support envvars yet */ -}}
{{- /* TODO: Remove this when the sa supports licenseKeys from envVars */ -}}
{{- $_ := set $config.opamp.headers "api-key" $licenseKey -}}

{{- $config | toYaml -}}
{{- end -}}
