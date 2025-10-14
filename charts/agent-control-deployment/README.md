[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

# agent-control-deployment

A Helm chart to install New Relic Agent Control on Kubernetes

# Helm installation

This chart is not intended to be installed on its own. Instead, it is designed to be installed as part of the [agent-control](https://github.com/newrelic/helm-charts/tree/master/charts/agent-control) chart.

## Values

<table >
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>affinity</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Sets pod/node affinities. Can be configured also with `global.affinity`</td>
		</tr>
		<tr>
			<td>agentsConfig</td>
			<td>object</td>
			<td>`{}` (See <a href="values.yaml">values.yaml</a>)</td>
			<td>List of managed agents configs. The key represents the name of the agent that should match the one specified in .config.agents.
In the example below, open-telemetry configuration is specified.

```yaml
agentsConfig:
  open-telemetry:
# -- Version of the newrelic/nr-k8s-otel-collector Helm Chart.
chart_version: "0.8.44"
# -- Values to be passed to the newrelic/nr-k8s-otel-collector Helm Chart.
# By default, the Agent type already has the `licenseKey` and `cluster` values set to the ones provided,
# so it is not necessary to set them here.
chart_values:
  nr-k8s-otel-collector: {}
  global: {}
```
</td>
		</tr>
		<tr>
			<td>cluster</td>
			<td>string</td>
			<td>`""`</td>
			<td>Name of the Kubernetes cluster monitored. Can be configured also with `global.cluster`.</td>
		</tr>
		<tr>
			<td>config</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>AgentControl config options used to generate the configFile passed to the binary. You can overwrite the configFile generated with a raw one via config.override</td>
		</tr>
		<tr>
			<td>config.acRemoteUpdate</td>
			<td>bool</td>
			<td>"true"</td>
			<td>enables or disables remote update from Fleet Control for the agent-control-deployment chart</td>
		</tr>
		<tr>
			<td>config.agents</td>
			<td>string</td>
			<td>`{}` (See <a href="values.yaml">values.yaml</a>)</td>
			<td>List of managed agents that will be deployed. The key represents the name of the agent that should used when defining its configuration.
In the example below, open-telemetry is a managed agent that will be deployed.

```yaml
agents:
  open-telemetry:
# -- Agent type <namespace>/<name>:<version>
agent_type: newrelic/io.opentelemetry.collector:0.1.0
```
</td>
		</tr>
		<tr>
			<td>config.allowedChartRepositoryUrl</td>
			<td>list</td>
			<td>`[]`</td>
			<td>List of allowed chart repository URLs. The Agent Control will only allow to deploy agents from these repositories.  `(Only newrelic chart repositories allowed: ["https://helm-charts.newrelic.com","https://newrelic.github.io/<>"])</td>
		</tr>
		<tr>
			<td>config.cdReleaseName</td>
			<td>string</td>
			<td>agent-control-cd</td>
			<td>The name of the release for the CD chart.</td>
		</tr>
		<tr>
			<td>config.cdRemoteUpdate</td>
			<td>bool</td>
			<td>"true"</td>
			<td>enables or disables remote update from Fleet Control for the agent-control-cd chart</td>
		</tr>
		<tr>
			<td>config.fleet_control.enabled</td>
			<td>bool</td>
			<td>`true`</td>
			<td>Enables or disables the auth against fleet control. It implies to disable any fleet communication and running the agent in stand alone mode where only the agents specified on `.config.subAgents` will be launched.</td>
		</tr>
		<tr>
			<td>config.fleet_control.fleet_id</td>
			<td>string</td>
			<td>`""`</td>
			<td>Specify a fleet_id to automatically connect the Agent Control to an existing fleet.</td>
		</tr>
		<tr>
			<td>config.log</td>
			<td>string</td>
			<td>`{}` (See <a href="values.yaml">values.yaml</a>)</td>
			<td>Log configuration. The log level can be overwritten as well via verboseLog
Example:

```yaml
log:
  format:
formatter: json
  level: debug
  insecure_fine_grained_level: debug
```
</td>
		</tr>
		<tr>
			<td>config.override</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Overrides the configuration that has been created automatically by the chart. This configuration here will be **MERGED** with the configuration specified above.</td>
		</tr>
		<tr>
			<td>config.status_server</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Set the status server port</td>
		</tr>
		<tr>
			<td>containerSecurityContext</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Sets security context (at container level). Can be configured also with `global.containerSecurityContext`</td>
		</tr>
		<tr>
			<td>customSecretLicenseKey</td>
			<td>string</td>
			<td>`""`</td>
			<td>In case you don't want to have the license key in you values, this allows you to point to which secret key is the license key located. Can be configured also with `global.customSecretLicenseKey`</td>
		</tr>
		<tr>
			<td>customSecretName</td>
			<td>string</td>
			<td>`""`</td>
			<td>In case you don't want to have the license key in you values, this allows you to point to a user created secret to get the key from there. Can be configured also with `global.customSecretName`</td>
		</tr>
		<tr>
			<td>dnsConfig</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Sets pod's dnsConfig. Can be configured also with `global.dnsConfig`</td>
		</tr>
		<tr>
			<td>extraEnv</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Add user environment variables to the agent</td>
		</tr>
		<tr>
			<td>extraEnvFrom</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Add user environment from configMaps or secrets as variables to the agent</td>
		</tr>
		<tr>
			<td>extraVolumeMounts</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Defines where to mount volumes specified with `extraVolumes`</td>
		</tr>
		<tr>
			<td>extraVolumes</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Volumes to mount in the containers</td>
		</tr>
		<tr>
			<td>hostNetwork</td>
			<td>bool</td>
			<td>`false`</td>
			<td>Sets pod's hostNetwork. Can be configured also with `global.hostNetwork`</td>
		</tr>
		<tr>
			<td>image</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Image for the New Relic Agent Control</td>
		</tr>
		<tr>
			<td>image.pullSecrets</td>
			<td>list</td>
			<td>`[]`</td>
			<td>The secrets that are needed to pull images from a custom registry.</td>
		</tr>
		<tr>
			<td>labels</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Additional labels for chart objects. Can be configured also with `global.labels`</td>
		</tr>
		<tr>
			<td>licenseKey</td>
			<td>string</td>
			<td>`""`</td>
			<td>This set this license key to use. Can be configured also with `global.licenseKey`</td>
		</tr>
		<tr>
			<td>nameOverride</td>
			<td>string</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Override the name of the chart used to template resource names.</td>
		</tr>
		<tr>
			<td>nodeSelector</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Sets pod's node selector. Can be configured also with `global.nodeSelector`</td>
		</tr>
		<tr>
			<td>nrStaging</td>
			<td>bool</td>
			<td>`false`</td>
			<td>Send the metrics to the staging backend. Requires a valid staging license key. Can be configured also with `global.nrStaging`</td>
		</tr>
		<tr>
			<td>podAnnotations</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Annotations to be added to all pods created by the integration.</td>
		</tr>
		<tr>
			<td>podLabels</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Additional labels for chart pods. Can be configured also with `global.podLabels`</td>
		</tr>
		<tr>
			<td>podSecurityContext</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Sets security context (at pod level). Can be configured also with `global.podSecurityContext`</td>
		</tr>
		<tr>
			<td>priorityClassName</td>
			<td>string</td>
			<td>`""`</td>
			<td>Sets pod's priorityClassName. Can be configured also with `global.priorityClassName`</td>
		</tr>
		<tr>
			<td>proxy</td>
			<td>object</td>
			<td>`nil`</td>
			<td>proxy configuration. It is propagated to both the system identity creation job, and to the agent control instance
If set possible values are:

```yaml
proxy:
  # Proxy URL proxy <protocol>://<host>:<port>
  url:
  # System path with the CA certificates in PEM format. All `.pem` files in the directory are read.
  ca_bundle_dir:
  # System path with the CA certificate in PEM format
  ca_bundle_file:
```
</td>
		</tr>
		<tr>
			<td>rbac.create</td>
			<td>bool</td>
			<td>`true`</td>
			<td>Whether the chart should automatically create the RBAC objects required to run.</td>
		</tr>
		<tr>
			<td>resources</td>
			<td>object</td>
			<td>`{}`</td>
			<td>Resource limits to be added to all pods created by the integration.</td>
		</tr>
		<tr>
			<td>serviceAccount</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Settings controlling ServiceAccount creation.</td>
		</tr>
		<tr>
			<td>serviceAccount.create</td>
			<td>bool</td>
			<td>`true`</td>
			<td>Whether the chart should automatically create the ServiceAccount objects required to run.</td>
		</tr>
		<tr>
			<td>subAgentsNamespace</td>
			<td>string</td>
			<td>"newrelic"</td>
			<td>Namespace where the sub-agents will be deployed.</td>
		</tr>
		<tr>
			<td>systemIdentity</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Configuration for the system identity registration process. These options provides the required data to run the pre-install job that creates the system identitythat is used when communicating via OpAMP. System identity registration is executed only once. Subsequent upgrades will not attempt to create the identity again. Therefore, `Helm Upgrade` works even though the identityClientSecret or the identityClientAuthToken are expired.</td>
		</tr>
		<tr>
			<td>systemIdentity.create</td>
			<td>bool</td>
			<td>`true`</td>
			<td>Set it to false to disable the registration of a new system identity. Set this to `false` to configure a pre-existing system identity via secret. The secret should be already created in the namespace having as keys "CLIENT_ID" and "private_key" of the identity to leverage.</td>
		</tr>
		<tr>
			<td>systemIdentity.extraVolumeMounts</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Defines where, in the systemIdentity job, to mount volumes specified with `extraVolumes`</td>
		</tr>
		<tr>
			<td>systemIdentity.extraVolumes</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Volumes to mount in the systemIdentity job</td>
		</tr>
		<tr>
			<td>systemIdentity.organizationId</td>
			<td>string</td>
			<td>`""`</td>
			<td>Organization ID used to create the system identity.</td>
		</tr>
		<tr>
			<td>systemIdentity.parentIdentity</td>
			<td>object</td>
			<td>See <a href="values.yaml">values.yaml</a></td>
			<td>Configuration for the parent identity You can either authenticate via ClientId/ClientSecret or pass directly an `AuthToken` and manage locally the authentication. The authToken can be retrieve via the cli command "newrelic-auth-cli authenticate ...".</td>
		</tr>
		<tr>
			<td>systemIdentity.parentIdentity.authToken</td>
			<td>string</td>
			<td>`""`</td>
			<td>Identity auth token. This option takes precedence over secret and skips authentication.</td>
		</tr>
		<tr>
			<td>systemIdentity.parentIdentity.clientId</td>
			<td>string</td>
			<td>`""`</td>
			<td>Identity clientId to use.</td>
		</tr>
		<tr>
			<td>systemIdentity.parentIdentity.clientSecret</td>
			<td>string</td>
			<td>`""`</td>
			<td>Identity clientSecret to use.</td>
		</tr>
		<tr>
			<td>systemIdentity.parentIdentity.fromSecret</td>
			<td>string</td>
			<td>`""`</td>
			<td>In case you don't want to have the clientId, the clientSecret and the clientAuthToken in your values, you can point to a secret to get the data from there. The secret data is mounted in the job via environment variables to generate the system identity.</td>
		</tr>
		<tr>
			<td>systemIdentity.secretName</td>
			<td>string</td>
			<td>`nil`</td>
			<td>if create is set to false a secret having this name is expected in the AC namespace</td>
		</tr>
		<tr>
			<td>tolerations</td>
			<td>list</td>
			<td>`[]`</td>
			<td>Sets pod's tolerations to node taints. Can be configured also with `global.tolerations`</td>
		</tr>
		<tr>
			<td>verboseLog</td>
			<td>bool</td>
			<td>`false`</td>
			<td>Sets the debug logs to this integration or all integrations if it is set globally. Can be configured also with `global.verboseLog`. If you need to change the logs to trace or change more complex options, please refer to config.log</td>
		</tr>
	</tbody>
</table>

## Maintainers

* [ac](https://github.com/orgs/newrelic/teams/ac/members)
