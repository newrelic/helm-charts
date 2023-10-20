{{- /*
`newrelic-super-agent.config` builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config" -}}
{{- /*
TODO:

There are a lot of TODOs to be made in this chart yet and some of them are going to impact the YAML that holds the
config.

This is the helper that templates the config. For this iteration we simply copy the `config` object from the values
and template it in the config map.

If you need a list of TODOs, just `grep TODO` on the `values.yaml` and look for things that are yet to be implemented.
*/ -}}

{{- if .Values.config -}}
    {{- .Values.config | toYaml -}}
{{- end -}}

{{- end -}}
