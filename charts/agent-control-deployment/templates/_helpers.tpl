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
Builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-agent-control.config.content" -}}

{{- /* config set here so we can populate it as we enable and disable snippets. */ -}}
{{- $statusServerPort := ((.Values.config).status_server).port -}}
{{- $statusServerHost := "0.0.0.0" -}}
{{- $config := dict "server" (dict "enabled" true "port" $statusServerPort "host" $statusServerHost) -}}

{{- /* Add to config k8s cluster and namespace config */ -}}
{{- $k8s := (dict "cluster_name" (include "newrelic.common.cluster" .) "namespace" .Release.Namespace "namespace_agents" .Values.subAgentsNamespace) -}}
{{- /* Add ac_remote_update and cd_remote_update to the config */ -}}
{{- $k8s = mustMerge $k8s (dict "ac_remote_update" .Values.config.acRemoteUpdate "cd_remote_update" .Values.config.cdRemoteUpdate) -}}
{{- $k8s = mustMerge $k8s (dict "ac_release_name" .Release.Name "cd_release_name" .Values.config.cdReleaseName) -}}
{{- $config = mustMerge $config (dict "k8s" $k8s) -}}

{{- with .Values.config.log -}}
{{- $config = mustMerge $config (dict "log" .) -}}
{{- end -}}

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

{{- /* Add Proxy config if url is specified */ -}}
{{- with .Values.proxy -}}
  {{- $config = mustMerge $config (dict "proxy" .) -}}
{{- end -}}

{{- /* Add Chart Repo url list to the allowed variants */ -}}
{{- if (.Values.config.allowedChartRepositoryUrl) -}}
  {{- $allowedVariants := dict "variants" (dict "chart_repository_urls" .Values.config.allowedChartRepositoryUrl) -}}
  {{- $config = mustMerge $config (dict "agent_type_var_constraints" $allowedVariants) -}}
{{- end -}}

{{- $config = mustMerge $config (dict "agents" (.Values.config.agents | default dict)) -}}

{{- /* Overwrite $config with everything in `config.override` if present */ -}}
{{- $config = mustMergeOverwrite $config (deepCopy ((.Values.config).override | default dict)) -}}

{{- /* Perform configuration validations */ -}}
{{- if not $config.server.enabled -}}
  {{- fail "The status server cannot be disabled as it is used in the Agent Control container probes" -}}
{{- end -}}
{{- if ne $config.server.host $statusServerHost -}}
  {{- fail "The status server needs to listen on 0.0.0.0 to be used in container probes" -}}
{{- end -}}
{{- if ne (printf "%v" $config.server.port) (printf "%v" $statusServerPort) -}}
  {{- fail "Setting up the status server port in `.Values.config.override` is not supported because it would conflict with container probes. Use `.Values.config.status_server.port` instead" -}}
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
Check if .Values.systemIdentity.secretName exists and use it to name auth secret. If it does not exist, fallback to the name of the releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-agent-control.auth.secret.name" -}}
{{- $secretName := (.Values.systemIdentity).secretName -}}
{{- if $secretName -}}
  {{- $secretName -}}
{{- else -}}
  {{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "auth" ) }}
{{- end -}}
{{- end -}}

{{- /*
Helper to toggle the creation of the job that creates and registers the system identity.
*/ -}}
{{- define "newrelic-agent-control.check.system.identity.inputs" -}}

{{- if and (include "newrelic-agent-control.auth.identityClientSecret" .) (include "newrelic-agent-control.auth.identityClientAuthToken" .) -}}
  {{- fail "You should not specify in .Values.systemIdentity both a identityClientSecret and a identityClientAuthToken" -}}
{{- end -}}

{{- if and (include "newrelic-agent-control.auth.customIdentitySecretName" .) (include "newrelic-agent-control.auth.parentIdentity" .) -}}
  {{- fail "You should not specify in .Values.systemIdentity both a secretName and identityClientId identityClientSecret/identityClientAuthToken" -}}
{{- end -}}

{{- if and (not (include "newrelic-agent-control.auth.customIdentitySecretName" .)) (not (include "newrelic-agent-control.auth.parentIdentity" .)) -}}
  {{- fail "You must specify in .Values.systemIdentity a secretName or identityClientId identityClientSecret/identityClientAuthToken" -}}
{{- end -}}

{{- if not (.Values.systemIdentity).organizationId -}}
  {{- fail "You should specify .Values.systemIdentity.organizationId" -}}
{{- end -}}

{{- end -}}


{{- /*
Helper to toggle the creation of the job that creates and registers the system identity.
*/ -}}
{{- define "newrelic-agent-control.auth.secret.shouldRunJob" -}}
{{- if and ((.Values.config).fleet_control).enabled (.Values.systemIdentity).create -}}
  true
{{- end -}}
{{- end -}}

{{/* check if both a ClientID and ClientSecret/ClientAuthToken are provided */}}
{{- define "newrelic-agent-control.auth.parentIdentity" -}}
{{- if and (include "newrelic-agent-control.auth.identityClientId" .) (or (include "newrelic-agent-control.auth.identityClientSecret" .) (include "newrelic-agent-control.auth.identityClientAuthToken" .)) -}}
    true
{{- end -}}
{{- end -}}

{{/* return ClientID */}}
{{- define "newrelic-agent-control.auth.identityClientId" -}}
{{- with .Values.systemIdentity.parentIdentity.clientId -}}
  {{- . -}}
{{- end -}}
{{- end -}}

{{/* return AuthToken */}}
{{- define "newrelic-agent-control.auth.identityClientAuthToken" -}}
{{- with .Values.systemIdentity.parentIdentity.authToken -}}
  {{- . -}}
{{- end -}}
{{- end -}}

{{/* return ClientSecret */}}
{{- define "newrelic-agent-control.auth.identityClientSecret" -}}
{{- with .Values.systemIdentity.parentIdentity.clientSecret -}}
  {{- . -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the clientdId and ClientSecret
*/}}
{{- define "newrelic-agent-control.auth.customIdentitySecretName" -}}
{{- with .Values.systemIdentity.parentIdentity.fromSecret -}}
  {{- . -}}
{{- end -}}
{{- end -}}


{{/* Return the custom secret name for the CliendId and ClientSecret with fallback to the generated one */}}
{{- define "newrelic-agent-control.auth.identityCredentialsSecretName" -}}
{{- $default := include "newrelic-agent-control.auth.generatedIdentityCredentialsSecretName" . -}}
{{- include "newrelic-agent-control.auth.customIdentitySecretName" . | default $default -}}
{{- end -}}

{{- define "newrelic-agent-control.auth.generatedIdentityCredentialsSecretName" -}}
{{ include "newrelic.common.naming.truncateToDNSWithSuffix" (dict "name" (include "newrelic.common.naming.fullname" .) "suffix" "preinstall-client-credentials" ) }}
{{- end -}}
