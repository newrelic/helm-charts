{{- /*
Return the name of the configMap holding the Super Agent's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-super-agent.config.name" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "local-data" "suffix" "superagent-config" ) -}}
{{- end -}}



{{- /*
Test that the value of `.Values.config.subAgents` exists and its valid. If empty, returns the default.
*/ -}}
{{- define "newrelic-super-agent.config.agents.yaml" -}}
{{- if (.Values.config).subAgents -}}
{{- $agents := dict -}}
{{- range $subAgentName, $subAgentConfig := (.Values.config).subAgents -}}
  {{- if not ($subAgentConfig).type -}}
    {{- fail (printf "Agent %s does not have agent type" $subAgentName) -}}
  {{- end -}}
  {{- $agents = mustMerge $agents (dict $subAgentName $subAgentConfig) -}}
{{- end -}}
{{- $agents | toYaml -}}
{{- else -}}
{{- /* Default agents for Kubernetes */ -}}
open-telemetry:
  type: newrelic/io.opentelemetry.collector:0.2.0
  content:
    chart_values:
      global:
        licenseKey: ${nr-env:NR_LICENSE_KEY}
        cluster: ${nr-env:NR_CLUSTER_NAME}
        nrStaging: ${nr-env:NR_STAGING}
        verboseLog: ${nr-env:NR_VERBOSE}
        region: ${nr-env:NR_REGION}
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent connect to get opamp data
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.opamp" -}}
{{- $region := include "newrelic.common.region" . -}}

{{- if eq $region "Staging" -}}
  https://opamp.staging-service.newrelic.com/v1/opamp
{{- else if eq $region "EU" -}}
  https://opamp.service.eu.newrelic.com/v1/opamp
{{- else if eq $region "US" -}}
  https://opamp.service.newrelic.com/v1/opamp
{{- else if eq $region "Local" -}}
  {{- /* Accessing the value directly without protection. A developer should now how to read the error. */ -}}
  {{ .Values.development.backend.opamp }}
{{- else -}}
  {{- fail "Unknown/unsupported region set for this chart" -}}
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent ask to renew its token
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.tokenRenewal" -}}
{{- $region := include "newrelic.common.region" . -}}

{{- if eq $region "Staging" -}}
  https://system-identity-oauth.staging-service.newrelic.com/oauth2/token
{{- else if eq $region "EU" -}}
  https://system-identity-oauth.service.newrelic.com/oauth2/token
{{- else if eq $region "US" -}}
  https://system-identity-oauth.service.newrelic.com/oauth2/token
{{- else if eq $region "Local" -}}
  {{- /* Accessing the value directly without protection. A developer should now how to read the error. */ -}}
  {{ .Values.development.backend.tokenRenewal }}
{{- else -}}
  {{- fail "Unknown/unsupported region set for this chart" -}}
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent register its system identity
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.systemIdentityRegistration" -}}
{{- $region := include "newrelic.common.region" . -}}

{{- if eq $region "Staging" -}}
  https://staging-api.newrelic.com/graphql
{{- else if eq $region "EU" -}}
  https://api.eu.newrelic.com/graphql
{{- else if eq $region "US" -}}
  https://api.newrelic.com/graphql
{{- else if eq $region "Local" -}}
  {{- /* Accessing the value directly without protection. A developer should now how to read the error. */ -}}
  {{ .Values.development.backend.systemIdentityRegistration }}
{{- else -}}
  {{- fail "Unknown/unsupported region set for this chart" -}}
{{- end -}}
{{- end -}}



{{- /*
Builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config.content" -}}
{{- /*
TODO: There are a lot of TODOs to be made in this chart yet and some of them are going to impact the YAML that holds
the config.

If you need a list of TODOs, just `grep TODO` on the `values.yaml` and look for things that are yet to be implemented.
*/ -}}

{{- /* config set here so we can populate it as we enable and disable snippets. */ -}}
{{- $config := dict "server" (dict "enabled" true) -}}

{{- /* Add to config k8s cluster and namespace config */ -}}
{{- $k8s := (dict "cluster_name" (include "newrelic.common.cluster" .) "namespace" .Release.Namespace) -}}
{{- $config = mustMerge $config (dict "k8s" $k8s) -}}

{{- /* Add opamp if enabled */ -}}
{{- if ((.Values.config).opamp).enabled -}}
  {{- $opamp := (dict "endpoint" (include "newrelic-super-agent.config.endpoints.opamp" .)) -}}

  {{- $auth_config := dict "token_url" (include "newrelic-super-agent.config.endpoints.tokenRenewal" .) "provider" "local" "private_key_path" "/etc/newrelic-super-agent/keys/from-secret.key" -}}
  {{- $opamp = mustMerge $opamp (dict "auth_config" $auth_config) -}}

  {{- $config = mustMerge $config (dict "opamp" $opamp) -}}
{{- end -}}

{{- /* Add subagents to the config */ -}}
{{- $agents := dict -}}
{{- range $subagent, $object := (include "newrelic-super-agent.config.agents.yaml" . | fromYaml) -}}
  {{- $agents = mustMerge $agents (dict $subagent (dict "agent_type" $object.type)) -}}
{{- end -}}
{{- $config = mustMerge $config (dict "agents" $agents) -}}

{{- /* Overwrite $config with everything in `config.superAgent.content` if present */ -}}
{{- $config = mustMergeOverwrite $config (deepCopy (((.Values.config).superAgent).content | default dict)) -}}
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
{{- if (((.Values.config).opamp).auth).organizationId -}}
  {{- .Values.config.auth.organizationId -}}
{{- else -}}
  {{- fail ".config.auth.organizationId is required." -}}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.name exists and use it to name auth' secret. If it does not exist, fallback to the name
of the releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.name" -}}
{{- $secretName := (((((.Values.config).opamp).auth).secret).name) -}}
{{- if $secretName -}}
  {{- $secretName -}}
{{- else -}}
  {{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "auth" ) }}
{{- end -}}
{{- end -}}



{{- /*
Helper to toggle the creation of the job that creates and registers the system identity.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.shouldRunJob" -}}
{{- $privateKey := include "newrelic-super-agent.auth.secret.privateKey.data" . -}}
{{- $clientId := include "newrelic-super-agent.auth.secret.clientId.data" . -}}

{{- if and ((.Values.config).opamp).enabled ((((.Values.config).opamp).auth).secret).create (not $privateKey) (not $clientId) -}}
  true
{{- end -}}
{{- end -}}



{{- /*
Helper to toggle the creation of the secret that has the system identity as values.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.shouldTemplate" -}}
{{- if and ((.Values.config).opamp).enabled ((((.Values.config).opamp).auth).secret).create -}}
  {{- $privateKey := include "newrelic-super-agent.auth.secret.privateKey.data" . -}}
  {{- $clientId := include "newrelic-super-agent.auth.secret.clientId.data" . -}}

  {{- if and $privateKey $clientId -}}
    true
  {{- else if or $privateKey $clientId -}}
    {{- fail "If you provide your own system identity data you have to provide both private key and client id" -}}
  {{- end -}}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.private_key.secret_key exists and use it for the key in the secret containing the private
key needed for the system identity. Fallbacks to `private_key`.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.privateKey.key" -}}
{{- $key := ((((((.Values.config).opamp).auth).secret).private_key).secret_key) -}}
{{- if $key -}}
  {{- $key -}}
{{- else -}}
  private_key
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.private_key.(plain_pem or base64_pem) exists and use it for as the private certificate for
auth. If no ceritifcate is provided, it defaults to `""` (empty string) so this helper can be used directly as a test.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.privateKey.data" -}}
{{- $plain_pem := ((((((.Values.config).opamp).auth).secret).private_key).plain_pem) -}}
{{- $base64_pem := ((((((.Values.config).opamp).auth).secret).private_key).base64_pem) -}}
{{- if and $plain_pem $base64_pem -}}
  {{- fail "Only one of base64_pem or plain_pem should be provided it you want to provide your own certificate." -}}
{{- else if $base64_pem -}}
  {{- $base64_pem }}
{{- else if $plain_pem -}}
  {{- $plain_pem | b64enc -}}
{{- else -}}
  {{- /* Empty string */ -}}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.client_id.secret_key exists and use it for the key in the secret containing the client id
needed for the system identity. Fallbacks to `client_id`.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.clientId.key" -}}
{{- $key := ((((((.Values.config).opamp).auth).secret).client_id).secret_key) -}}
{{- if $key -}}
  {{- $key -}}
{{- else -}}
  CLIENT_ID
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.client_id.(plain or base64) exists and use it for as the client id for auth. If no
value is provided, it defaults to `""` (empty string) so this helper can be used directly as a test.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.clientId.data" -}}
{{- $plain := ((((((.Values.config).opamp).auth).secret).client_id).plain) -}}
{{- $base64 := ((((((.Values.config).opamp).auth).secret).client_id).base64) -}}
{{- if and $plain $base64 -}}
  {{- fail "Only one of base64 or plain should be provided it you want to provide your own client id." -}}
{{- else if $base64 -}}
  {{- $base64 }}
{{- else if $plain -}}
  {{- $plain | b64enc -}}
{{- else -}}
  {{- /* Empty string */ -}}
{{- end -}}
{{- end -}}
