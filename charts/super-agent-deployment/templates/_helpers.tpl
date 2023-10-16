{{- /*
`newrelic-super-agent.config` builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config" -}}
{{- /*
TODO:
    * `licenseKey`: comes from the common library but it would not be needed as it is an ingestion API Key, not a REST one.
    * `rbac`: the is a placeholder for RBAC that simply list pods. this has to be narrowed to the use case of this agent.
    * `customAttributes`: decorate everything with this custom attributes, maybe as they come from opamp.
    * `proxy`, `nrStaging` and `fedramp` support on the meta agent. This could be made from the chart itself changing the opamp endpoint.
    * `verboseLog`: legacy toggle to enable verbosity.

For this iteration, the chart has no way to template tehe license. You might reuse the common-library secret creation helpers:
{{- include "newrelic.common.license.secret" . -}}

*/ -}}

{{ if .Values.config }}
    {{- .Values.config | toYaml -}}
{{- end -}}

{{- end -}}
