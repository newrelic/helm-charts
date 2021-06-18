# New Relic's StatsD Integration

## Chart Details

This chart will deploy the New Relic's StatsD Integration. Keep in mind that due to limitations in the nri-statsd / gostatsd implementation, the insights API key will be stored as plain text within the gostatsd configmap.

## Configuration

| Parameter  | Description| Default|
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| `global.cluster` - `cluster`   | The cluster name for the Kubernetes cluster.   ||
| `global.insightsKey` - `insightsKey`   | The New Relic Inights API Key. ||
| `accountId`| The New Relic account ID.  ||
| `flushType`| The type of metric being reported. (`metrics`, `insights`, `infra`)|`metrics`   |
| `statsdPort`   | The port statsd pods and the service will listen on.   | `8125` |
| `transport`| GoStatsD New Relic transport type. | `default`  |
| `insightsDomain`   | The New Relic insights domain. | `collector.newrelic.com`   |
| `metricsDomain`| The New Relic metrics domain.  | `metric-api.newrelic.com`  |
| `metricTags.*` | Additional tags to add to all collected metrics.   | `{}`   |
| `additionalConfig.*`   | Additional GoStatsD configuration. Define config parameters as `additionalConfig.key: value`. The provided values are formatted directly into the GoStatsD configmap.  | `See values.yaml`  |
| `additionalNewRelicConfig.*`   | Additional GoStatsD New Relic specific configuration. Define config parameters as `additionalNewRelicConfig.key: value`. The provided values are formatted directly into the GoStatsD configmap.   | `{}`   |
| `nameOverride` | The name that should be used for the deployment.   ||
| `image.repository` | The prometheus openmetrics integration image name. | `newrelic/nri-statsd`  |
| `image.tag`| The prometheus openmetrics integration image tag.  | `2.2.0`|
| `image.pullSecrets`| Image pull secrets.| `nil`  |
| `replicaCount` | The number of replicas in the depoyment.   | `1`|
| `resources`| A yaml defining the resources for the events-router container. | {} |
| `serviceAccount.create`| If true, a service account would be created and assigned to the deployment | true   |
| `serviceAccount.name`  | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account  ||
| `serviceAccount.annotations`   | The annotations to add to the service account if `serviceAccount.create` is set to true.   ||
| `priorityClassName`| Scheduling priority of the pod | `nil`  |
| `nodeSelector` | Node label to use for scheduling   | `{}`   |
| `tolerations`  | List of node taints to tolerate (requires Kubernetes >= 1.6)   | `[]`   |
| `affinity` | Node affinity to use for scheduling| `{}`   |
| `global.nrStaging` - `nrStaging`   | Send data to staging (requires a staging license key)  | false  |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

To install this chart, run the following command:

```sh
helm install newrelic/nri-statsd \
--set insightsKey=<new_relic_insights_api_key> \
--set cluster=my-k8s-cluster
```
