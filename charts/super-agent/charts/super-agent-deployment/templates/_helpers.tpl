{{- /*
Return the name of the configMap holding the Super Agent's config. Defaults to release's fill name suffiexed with "-config"
*/ -}}
{{- define "newrelic-super-agent.config.name" -}}
{{- (include "newrelic.common.naming.truncateToDNSWithSuffix" ( dict "name" "local-data" "suffix" "superagent-config" )) -}}
{{- end -}}



{{- /*
Return the agents part that should go in the super agent config. It is created from `.Values.config.subAgents`.
*/ -}}
{{- define "newrelic-super-agent.config.agents.yaml" -}}
{{- if (.Values.config).subAgents -}}
{{- $agents := dict -}}
{{- range $subAgentName, $subAgentConfig := (.Values.config).subAgents -}}
  {{- if not $subAgentConfig.type -}}
    {{- fail (printf "Agent %s does not have a valid agent type" $subAgentName) -}}
  {{- end -}}
  {{- $_ := dict $subAgentName (dict
      "agent_type" $subAgentConfig.type
      "content" $subAgentConfig.content
    ) | mustMerge $agents -}}
{{- end -}}
{{- $agents | toYaml -}}
{{- else -}}
{{- /* Default agents for Kubernetes */ -}}
open-telemetry:
  type: newrelic/io.opentelemetry.collector:0.2.0
  content:
    chart_values:
      cluster: "{{ include "newrelic.common.cluster" . }}"
{{- /*
      TODO: Remove this file when the Super Agent supports licensekey as an envVar.

      licenseKey: *licensekey
*/ -}}
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent connect to get opamp data
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.opamp" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  https://opamp.staging-service.newrelic.com/v1/opamp
{{- else -}}
  {{- /* TODO: Add more regions like EU. In the future, we can know it from the LicenseKey */ -}}
  https://opamp.service.newrelic.com/v1/opamp
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent ask to renew its token
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.tokenRenewal" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  https://staging-system-identity-oauth.vip.cf.nr-ops.net/oauth2/token
{{- else -}}
  {{- /* TODO: Add more regions like EU. In the future, we can know it from the LicenseKey */ -}}
  https://system-identity-oauth.vip.cf.nr-ops.net/oauth2/token
{{- end -}}
{{- end -}}



{{- /*
Return to which endpoint should the super agent register its system identity
*/ -}}
{{- define "newrelic-super-agent.config.endpoints.systemIdentityRegistration" -}}
{{- if include "newrelic.common.nrStaging" . -}}
  https://staging-api.newrelic.com/graphql
{{- else -}}
  {{- /* TODO: Add more regions like EU. In the future, we can know it from the LicenseKey */ -}}
  https://api.newrelic.com/graphql
{{- end -}}
{{- end -}}



{{- /*
Builds the configuration from config on the values and add more config options like
cluster name, licenses, and custom attributes
*/ -}}
{{- define "newrelic-super-agent.config.content" -}}
{{- /*
This snippet should execute always to block all unsupported features from the common-library that are not yet supported
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

{{- $opamp := (dict
  "endpoint" (include "newrelic-super-agent.config.endpoints.opamp" .)
) -}}
{{- $k8s := (dict
  "cluster_name" (include "newrelic.common.cluster" .)
  "namespace" .Release.Namespace
) -}}

{{- if .Values.config.auth.enabled -}}
  {{- $auth_config := (dict
    "auth_config" (dict
      "token_url" (include "newrelic-super-agent.config.endpoints.tokenRenewal" .)
      "provider" "local"
      "private_key_path" "/etc/newrelic-super-agent/keys/from-secret.key"
    )
  ) -}}
  {{- $_ := mustMerge $opamp $auth_config -}}
{{- end -}}

{{- $config := (dict
  "opamp" $opamp
  "k8s" $k8s
  "agents" (include "newrelic-super-agent.config.agents.yaml" . | fromYaml)
) -}}

{{- $_ := deepCopy (.Values.config.superAgent.content | default dict) | mustMergeOverwrite $config -}}
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
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.name exists and use it to name auth' secret. If it does not exist, fallback to the name
of the releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.name" -}}
{{- $secretName := ((((.Values.config).auth).secret).name) -}}
{{- if $secretName -}}
  {{- $secretName -}}
{{- else -}}
  {{- include "newrelic.common.naming.truncateToDNSWithSuffix" (dict
    "name" (include "newrelic.common.naming.fullname" .)
    "suffix" "auth"
  ) }}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.name exists and use it to name auth' secret. If it does not exist, fallback to the name
of the releases with "-auth" suffix.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.failTemplate" -}}
{{- /* There is not XOR on helm so we have to do it the long way */ -}}
{{- $left := include "newrelic-super-agent.auth.secret.privateKey.data" . -}}
{{- $right := include "newrelic-super-agent.auth.secret.clientId.data" . -}}
{{- $found := "" -}}

{{- if $left -}}
  {{- $found = "found" -}}
{{- end -}}
{{- if $right -}}
  {{- $found = "found" -}}
{{- end -}}
{{- if and $left $right -}}
  {{- $found = "" -}}
{{- end -}}

{{- if $found -}}
  {{- fail "If you provide your own system identity data you have to provide both private key and client id" -}}
{{- end -}}
{{- end -}}



{{- /*
Check if .Values.config.auth.secret.private_key.secret_key exists and use it for the key in the secret contaning the private
key needed for the system identity. Fallbacks to `private_key`.
*/ -}}
{{- define "newrelic-super-agent.auth.secret.privateKey.key" -}}
{{- $key := (((((.Values.config).auth).secret).private_key).secret_key) -}}
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
{{- $plain_pem := (((((.Values.config).auth).secret).private_key).plain_pem) -}}
{{- $base64_pem := (((((.Values.config).auth).secret).private_key).base64_pem) -}}
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
{{- $key := (((((.Values.config).auth).secret).client_id).secret_key) -}}
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
{{- $plain := (((((.Values.config).auth).secret).client_id).plain) -}}
{{- $base64 := (((((.Values.config).auth).secret).client_id).base64) -}}
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
