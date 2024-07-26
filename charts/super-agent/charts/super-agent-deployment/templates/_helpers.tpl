{{- /*
Return the name of the configMap holding the Super Agent's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-super-agent.config.name" -}}
{{- (include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "local-data" "suffix" "superagent-config" )) -}}
{{- end -}}

{{- /*
Return to which endpoint should the super agent ask to renew its token
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.tokenRenewal" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  https://system-identity-oauth.staging-service.newrelic.com/oauth2/token
{{- else if .Values.euEndpoints -}}
  https://system-identity-oauth.service.eu.newrelic.com/oauth2/token
{{- else -}}
  https://system-identity-oauth.service.newrelic.com/oauth2/token
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent register its system identity
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.systemIdentityRegistration" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  https://staging-api.newrelic.com/graphql
{{- else if .Values.euEndpoints -}}
  https://api.eu.newrelic.com/graphql
{{- else -}}
  https://api.newrelic.com/graphql
{{- end -}}
{{- end -}}



{{- /*
Builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config.content" -}}
{{- /*
This snippet should execute always to block all unsupported features from the common-lirary that are not yet supported
by this chart.

{{- /*
TODO: There are a lot of TODOs to be made in this chart yet and some of them are going to impact the YAML that holds 
the config.

If you need a list of TODOs, just `grep TODO` on the `values.yaml` and look for things that are yet to be implemented.
*/ -}}
{{- $config := .Values.config.superAgent.content | default dict -}}
{{- $config = mustMergeOverwrite (dict "k8s" (dict "cluster_name" (include "newrelic.common.cluster" .))) $config -}}
{{- $config = mustMergeOverwrite (dict "k8s" (dict "namespace" .Release.Namespace)) $config -}}

{{- if .Values.config.superAgent.content -}}
{{- if .Values.config.superAgent.content.opamp -}}
{{- if .Values.config.auth }}
{{- if .Values.config.auth.enabled -}}
{{- $opamp := (dict "opamp" (dict "auth_config" (dict "token_url" (include "newrelic-super-agent.config.endpoints.tokenRenewal" .) "provider" "local" "private_key_path" "/etc/newrelic-super-agent/keys/from-secret.key"))) -}}
{{- $_ := $opamp | mustMergeOverwrite $config -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

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





{{- /*
Return .Values.config.auth.organizationId and fails if it does not exists
*/ -}}
{{- define "newrelic-super-agent.auth.organizationId" -}}
{{- if not ((.Values.config).auth).organizationId -}}
  {{- fail ".Values.config.auth.organizationId is required." -}}
{{- end -}}
{{- .Values.config.auth.organizationId -}}
{{- end -}}



{{- /*
Releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.name" -}}
  {{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "auth") }}
{{- end -}}
