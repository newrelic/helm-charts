{{- /*
Return the name of the configMap holding the Agent Control's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-agent-control.config.name" -}}
{{- include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "local-data" "suffix" "agentcontrol-config" ) -}}
{{- end -}}



{{- /*
Test that the value of `.Values.config.subAgents` exists and its valid. If empty, returns the default.
*/ -}}
{{- define "newrelic-agent-control.config.agents.yaml" -}}
{{- $agents := dict -}}
{{- range $subAgentName, $subAgentConfig := (.Values.config).subAgents -}}
  {{- if not ($subAgentConfig).type -}}
    {{- fail (printf "Agent %s does not have agent type" $subAgentName) -}}
  {{- end -}}
  {{- $agents = mustMerge $agents (dict $subAgentName $subAgentConfig) -}}
{{- end -}}
{{- $agents | toYaml -}}
{{- end -}}



{{- /*
Return to which endpoint should the agent control connect to get fleet_control data
*/ -}}
{{- define "newrelic-agent-control.config.endpoints.fleet_control" -}}
{{- $region := include "newrelic.common.region" . -}}

{{- if eq $region "Staging" -}}
  https://opamp.staging-service.newrelic.com/v1/opamp
{{- else if eq $region "EU" -}}
  https://opamp.service.eu.newrelic.com/v1/opamp
{{- else if eq $region "US" -}}
  https://opamp.service.newrelic.com/v1/opamp
{{- else if eq $region "Local" -}}
  {{- /* Accessing the value directly without protection. A developer should now how to read the error. */ -}}
  {{ .Values.development.backend.fleet_control }}
{{- else -}}
  {{- fail "Unknown/unsupported region set for this chart" -}}
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the agent control ask to renew its token
*/ -}}
{{- define "newrelic-agent-control.config.endpoints.tokenRenewal" -}}
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
Return to which endpoint should the agent control register its system identity
*/ -}}
{{- define "newrelic-agent-control.config.endpoints.systemIdentityRegistration" -}}
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
{{- define "newrelic-agent-control.config.content" -}}

{{- /* config set here so we can populate it as we enable and disable snippets. */ -}}
{{- $statusServerPort := ((.Values.config).status_server).port -}}
{{- $statusServerHost := "0.0.0.0" -}}
{{- $config := dict "server" (dict "enabled" true "port" $statusServerPort "host" $statusServerHost) -}}

{{- /* Add to config k8s cluster and namespace config */ -}}
{{- $k8s := (dict
  "cluster_name" (include "newrelic.common.cluster" .)
  "namespace" .Release.Namespace
  "namespace_agents" ((.Values.config).subAgentsNamespace)
) -}}
{{- $config = mustMerge $config (dict "k8s" $k8s) -}}

{{- /* Add fleet_control if enabled */ -}}
{{- if ((.Values.config).fleet_control).enabled -}}
  {{- $fleet_control := (dict "endpoint" (include "newrelic-agent-control.config.endpoints.fleet_control" .)) -}}

  {{- if ((.Values.config).fleet_control).fleet_id -}}
  {{- $fleet_control = mustMerge $fleet_control (dict "fleet_id" ((.Values.config).fleet_control).fleet_id) -}}
  {{- end -}}

  {{- $auth_config := dict "token_url" (include "newrelic-agent-control.config.endpoints.tokenRenewal" .) "provider" "local" "private_key_path" "/etc/newrelic-agent-control/keys/from-secret.key" -}}
  {{- $fleet_control = mustMerge $fleet_control (dict "auth_config" $auth_config) -}}

  {{- $config = mustMerge $config (dict "fleet_control" $fleet_control) -}}
{{- end -}}

{{- /* Add subagents to the config */ -}}
{{- $agents := dict -}}
{{- range $subagent, $object := (include "newrelic-agent-control.config.agents.yaml" . | fromYaml) -}}
  {{- $agents = mustMerge $agents (dict $subagent (dict "agent_type" $object.type)) -}}
{{- end -}}
{{- $config = mustMerge $config (dict "agents" $agents) -}}

{{- /* Overwrite $config with everything in `config.agentControl.content` if present */ -}}
{{- $config = mustMergeOverwrite $config (deepCopy (((.Values.config).agentControl).content | default dict)) -}}

{{- /* Perform configuration validations */ -}}
{{- if not $config.server.enabled -}}
  {{- fail "The status server cannot be disabled as it is used in the Agent Control container probes" -}}
{{- end -}}
{{- if ne $config.server.host $statusServerHost -}}
  {{- fail "The status server needs to listen on 0.0.0.0 to be used in container probes" -}}
{{- end -}}
{{- if ne (printf "%v" $config.server.port) (printf "%v" $statusServerPort) -}}
  {{- fail "Setting up the status server port in `.Values.config.agentControl.content` is not supported because it would conflict with container probes. Use `.Values.config.status_server.port` instead" -}}
{{- end -}}
{{- if $config.k8s.chart_version -}}
  {{- fail "The chart version is set automatically via environment variable and should not be set manually" -}}
{{- end -}}

{{- $config | toYaml -}}
{{- end -}}

{{- /* These are the defaults that are used for all the containers in this chart */ -}}
{{- define "newrelic-agent-control.securityContext.containerDefaults" -}}
runAsUser: 1000
runAsGroup: 2000
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
{{- end -}}



{{- /* Allow to change pod defaults dynamically */ -}}
{{- define "newrelic-agent-control.securityContext.container" -}}
{{- $defaults := fromYaml ( include "newrelic-agent-control.securityContext.containerDefaults" . ) -}}
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
{{- define "newrelic-agent-control.auth.organizationId" -}}
{{- if (((.Values.config).fleet_control).auth).organizationId -}}
  {{- .Values.config.fleet_control.auth.organizationId -}}
{{- else -}}
  {{- fail ".config.fleet_control.auth.organizationId is required" -}}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.name exists and use it to name auth' secret. If it does not exist, fallback to the name
of the releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-agent-control.auth.secret.name" -}}
{{- $secretName := (((((.Values.config).fleet_control).auth).secret).name) -}}
{{- if $secretName -}}
  {{- $secretName -}}
{{- else -}}
  {{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "auth" ) }}
{{- end -}}
{{- end -}}



{{- /*
Helper to toggle the creation of the job that creates and registers the system identity.
*/ -}}
{{- define "newrelic-agent-control.auth.secret.shouldRunJob" -}}
{{- $privateKey := include "newrelic-agent-control.auth.secret.privateKey.data" . -}}
{{- $clientId := include "newrelic-agent-control.auth.secret.clientId.data" . -}}

{{- if and ((.Values.config).fleet_control).enabled ((((.Values.config).fleet_control).auth).secret).create (not $privateKey) (not $clientId) -}}
  true
{{- end -}}
{{- end -}}



{{- /*
Helper to toggle the creation of the secret that has the system identity as values.
*/ -}}
{{- define "newrelic-agent-control.auth.secret.shouldTemplate" -}}
{{- if and ((.Values.config).fleet_control).enabled ((((.Values.config).fleet_control).auth).secret).create -}}
  {{- $privateKey := include "newrelic-agent-control.auth.secret.privateKey.data" . -}}
  {{- $clientId := include "newrelic-agent-control.auth.secret.clientId.data" . -}}

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
{{- define "newrelic-agent-control.auth.secret.privateKey.key" -}}
{{- $key := ((((((.Values.config).fleet_control).auth).secret).private_key).secret_key) -}}
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
{{- define "newrelic-agent-control.auth.secret.privateKey.data" -}}
{{- $plain_pem := ((((((.Values.config).fleet_control).auth).secret).private_key).plain_pem) -}}
{{- $base64_pem := ((((((.Values.config).fleet_control).auth).secret).private_key).base64_pem) -}}
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
{{- define "newrelic-agent-control.auth.secret.clientId.key" -}}
{{- $key := ((((((.Values.config).fleet_control).auth).secret).client_id).secret_key) -}}
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
{{- define "newrelic-agent-control.auth.secret.clientId.data" -}}
{{- $plain := ((((((.Values.config).fleet_control).auth).secret).client_id).plain) -}}
{{- $base64 := ((((((.Values.config).fleet_control).auth).secret).client_id).base64) -}}
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

{{/* check if both L1 ClientID and ClientSecret are provided */}}
{{- define "newrelic-agent-control.auth.l1Identity" -}}
{{- if and (include "newrelic-agent-control.auth.identityClientId" .) (include "newrelic-agent-control.auth.identityClientSecret" .) -}}
    true
{{- end -}}
{{- end -}}

{{/* return L1 ClientID */}}
{{- define "newrelic-agent-control.auth.identityClientId" -}}
{{- if .Values.identityClientId -}}
  {{- .Values.identityClientId -}}
{{- end -}}
{{- end -}}

{{/* return L1 ClientSecret */}}
{{- define "newrelic-agent-control.auth.identityClientSecret" -}}
{{- if .Values.identityClientSecret -}}
  {{- .Values.identityClientSecret -}}
{{- end -}}
{{- end -}}

{{- /*
Return to which endpoint should the agent control register its system identity
*/ -}}
{{- define "newrelic-agent-control.config.endpoints.systemIdentityCreation" -}}
{{- $region := include "newrelic.common.region" . -}}

{{- if eq $region "Staging" -}}
  https://staging-api.newrelic.com/graphql
{{- else if eq $region "EU" -}}
  https://api.eu.newrelic.com/graphql
{{- else if eq $region "US" -}}
  https://api.newrelic.com/graphql
{{- else if eq $region "Local" -}}
  {{- /* Accessing the value directly without protection. A developer should now how to read the error. */ -}}
  {{ .Values.development.backend.systemIdentityCreation }}
{{- else -}}
  {{- fail "Unknown/unsupported region set for this chart" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the ClientId Key inside the secret.
*/}}
{{- define "newrelic-agent-control.auth.l1IdentityCredentialsKey.clientIdKeyName" -}}
{{- include "newrelic-agent-control.auth.identityCredentialsL1._customClientIdKey" . | default "clientIdKey" -}}
{{- end -}}

{{/*
Return the name key for the ClientSecret Key inside the secret.
*/}}
{{- define "newrelic-agent-control.auth.l1IdentityCredentialsKey.clientSecretKeyName" -}}
{{- include "newrelic-agent-control.auth.identityCredentialsL1._customClientSecretKey" . | default "clientSecretKey" -}}
{{- end -}}

{{/*
Return the name of the secret holding the clientdId and ClientSecret
*/}}
{{- define "newrelic-agent-control.auth.customIdentitySecretName" -}}
{{- if .Values.customIdentitySecretName -}}
  {{- .Values.customIdentitySecretName -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the ClientID inside the secret.
*/}}
{{- define "newrelic-agent-control.auth.identityCredentialsL1._customClientIdKey" -}}
{{- if .Values.customIdentityClientIdSecretKey -}}
  {{- .Values.customIdentityClientIdSecretKey -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the ClientSecret inside the secret.
*/}}
{{- define "newrelic-agent-control.auth.identityCredentialsL1._customClientSecretKey" -}}
{{- if .Values.customIdentityClientSecretSecretKey -}}
  {{- .Values.customIdentityClientSecretSecretKey -}}
{{- end -}}
{{- end -}}

{{/* Return the generated secret name for the CliendId and ClientSecret*/}}
{{- define "newrelic.common.userKey.generatedSecretName" -}}
{{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "preinstall-user-key" ) }}
{{- end -}}

{{/* Return the custom secret name for the CliendId and ClientSecret with fallback to the generated one */}}
{{- define "newrelic-agent-control.auth.identityCredentialsSecretName" -}}
{{- $default := include "newrelic-agent-control.auth.generatedIdentityCredentialsSecretName" . -}}
{{- include "newrelic-agent-control.auth.customIdentitySecretName" . | default $default -}}
{{- end -}}

{{- define "newrelic-agent-control.auth.generatedIdentityCredentialsSecretName" -}}
{{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "preinstall-client-credentials" ) }}
{{- end -}}
