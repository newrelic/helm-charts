# newrelic-k8s-metrics-adapter

## Chart Details

This chart will deploy the [New Relic Metrics Adapter](https://github.com/newrelic/newrelic-k8s-metrics-adapter), which implements the `external.metrics.k8s.io` API to support the use of external metrics based New Relic NRQL queries.

## Configuration


| Parameter                                                                       | Description                                                                                                                                                                                                                                                                                                                                 | Default                                                                                              |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `global.cluster` - `cluster`                                                    | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                                                                                                                |                                                                                                      |
| `global.licenseKey` - `licenseKey`                                              | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account.                                                                                                                                                                                                          |                                                                                                      |
| `image.repository`                                                              | The container to pull.                                                                                                                                                                                                                                                                                                                      | `newrelic/newrelic-k8s-metrics-adapter`                                                              |
| `image.pullPolicy`                                                              | The pull policy.                                                                                                                                                                                                                                                                                                                            | `IfNotPresent`                                                                                       |
| `image.tag`                                                                     | The version of the image to pull.                                                                                                                                                                                                                                                                                                           | `appVersion`                                                                                         |
| `image.pullSecrets`                                                             | The image pull secrets.                                                                                                                                                                                                                                                                                                                     | `nil`                                                                                                |
| `apiServicePatchJob.image.repository`                                           | The job container to pull.                                                                                                                                                                                                                                                                                                                  | `k8s.gcr.io/ingress-nginx/kube-webhook-certgen`                                                      |
| `apiServicePatchJob.image.pullPolicy`                                           | The job pull policy.                                                                                                                                                                                                                                                                                                                        | `IfNotPresent`                                                                                       |
| `apiServicePatchJob.image.pullSecrets`                                          | Image pull secrets.                                                                                                                                                                                                                                                                                                                         | `nil`                                                                                                |
| `apiServicePatchJob.image.tag`                                                  | The job version of the container to pull.                                                                                                                                                                                                                                                                                                   | `v1.1.1`                                                                                             |
| `apiServicePatchJob.volumeMounts`                                               | Additional Volume mounts for Cert Job.                                                                                                                                                                                                                                                                                                      | `[]`                                                                                                 |
| `apiServicePatchJob.volumes`                                                    | Additional Volumes for Cert Job.                                                                                                                                                                                                                                                                                                            | `[]`                                                                                                 |
| `certManager.enabled`                                                           | Use cert-manager to provision the APIService certs.                                                                                                                                                                                                                                                                                         | `false`                                                                                              |
| `replicas`                                                                      | Number of replicas in the deployment.                                                                                                                                                                                                                                                                                                       | `1`                                                                                                  |
| `resources`                                                                     | Resources you wish to assign to the pod.                                                                                                                                                                                                                                                                                                    | See Resources below                                                                                  |
| `serviceAccount.create`                                                         | If true a service account would be created and assigned for the metrics adapter.                                                                                                                                                                                                                                                            | `true`                                                                                               |
| `serviceAccount.name`                                                           | If `serviceAccount.create` is true then this name will be used when creating the service account; if this value is not set or it evaluates to false, then when creating the account the returned value from the template `newrelic-k8s-metrics-adapter.fullname` will be used as name.                                                      |                                                                                                      |
| `affinity`                                                                      | Node affinity to use for scheduling.                                                                                                                                                                                                                                                                                                        | `{}`                                                                                                 |
| `podSecurityContext.enabled`                                                    | Enable custom Pod Security Context.                                                                                                                                                                                                                                                                                                         | `false`                                                                                              |
| `podSecurityContext.fsGroup`                                                    | fsGroup for Pod Security Context.                                                                                                                                                                                                                                                                                                           | `1001`                                                                                               |
| `podSecurityContext.runAsUser`                                                  | runAsUser UID for Pod Security Context.                                                                                                                                                                                                                                                                                                     | `1001`                                                                                               |
| `podSecurityContext.runAsGroup`                                                 | runAsGroup GID for Pod Security Context.                                                                                                                                                                                                                                                                                                    | `1001`                                                                                               |
| `podAnnotations`                                                                | If you wish to provide additional annotations to apply to the pod(s), specify them here.                                                                                                                                                                                                                                                    |                                                                                                      |
| `priorityClassName`                                                             | Scheduling priority of the pod.                                                                                                                                                                                                                                                                                                             | `nil`                                                                                                |
| `nodeSelector`                                                                  | Node label to use for scheduling.                                                                                                                                                                                                                                                                                                           | `{}`                                                                                                 |
| `tolerations`                                                                   | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                                                                                                                | `[]`
| `hostNetwork`                                                                   | Enable hostNetwork                                                                                                                                                                                                                                                                                                                           |                                                                                                 |
| `verboseLog`                                                                    | Enable metrics adapter verbose logs.                                                                                                                                                                                                                                                                                                        | `false`                                                                                              |
| `personalAPIKey`                                                                | New Relic [Personal API Key](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/#user-api-key) (stored in a secret). Used to connect to NerdGraph in order to fetch the configured metrics.                                                                                                                                  |                                                                                                      |
| `config.accountID`                                                              | New Relic [Account ID](https://docs.newrelic.com/docs/accounts/accounts-billing/account-structure/account-id/) where the configured metrics are stored.                                                                                                                                                                                     |                                                                                                      |
| `config.region`                                                                 | New Relic account region. If not set, it will be automatically derived from global.licenseKey                                                                                                                                                                                                                                               | `US`                                                                                                 |
| `config.cacheTTLSeconds`                                                        | Period of time in seconds in which a cached value of a metric is consider valid.                                                                                                                                                                                                                                                            | `0` (disabled)                                                                                       |
| `config.externalMetrics{}`                                                      | ExternalMetrics contains all the external metrics definition of the adapter. Each key of the externalMetric entry represents the metric name and contains the parameters that defines it.                                                                                                                                                   | See External metric below                                                                            |
| `config.externalMetrics{}.query`                                                | NRQL query that will executed to obtain the metric value. The query must return just one value so is recommended to use aggregator functions like average or latest.                                                                                                                                                                        |                                                                                                      |
| `config.externalMetrics{}.removeClusterFilter`                                  | Disable the cluster filter added to the query by default. Use when metrics doesn't below to the cluster and doesn't have the clusterName attribute.                                                                                                                                                                                         | `false`                                                                                              |



## Example

Make sure you have [added the New Relic chart repository.](../../README.md#install)

Because of metrics configuration we recommend to use an external values file to deploy the chart. An example with the required parameters looks like:

```yaml
cluster: ClusterName
personalAPIKey: <Personal API Key>
config:
  accountID: <Account ID>
  externalMetrics:
    nginx_average_requests:
      query: "FROM Metric SELECT average(nginx.server.net.requestsPerSecond) SINCE 2 MINUTES AGO"
```

Then, to install this chart, run the following command:

```sh
helm upgrade --install [release-name] newrelic/newrelic-k8s-metrics-adapter --values [values file path]
```

Once deployed the metric `nginx_average_requests` will be available to use by any HPA. This is and example of an HPA yaml using this metric:

```yaml
kind: HorizontalPodAutoscaler
apiVersion: autoscaling/v2beta2
metadata:
  name: nginx-scaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: External
      external:
        metric:
          name: nginx_average_requests
          selector:
            matchLabels: 
              k8s.namespaceName: nginx
        target:
          type: Value 
          value: 10000
```

The NRQL query that will be run to get the `nginx_average_requests` value will be:

```sql
FROM Metric SELECT average(nginx.server.net.requestsPerSecond) WHERE clusterName='ClusterName' AND `k8s.namespaceName`='nginx' SINCE 2 MINUTES AGO
```

## External Metrics

An example of multiple external metrics defined:

```yaml
externalMetrics:
    nginx_average_requests:
      query: "FROM Metric SELECT average(nginx.server.net.requestsPerSecond) SINCE 2 MINUTES AGO"
    container_average_cores_utilization:
      query: "FROM Metric SELECT average(`k8s.container.cpuCoresUtilization`) SINCE 2 MINUTES AGO"
```

## Resources

The default set of resources assigned to the newrelic-k8s-metrics-adapter pods is shown below:

```yaml
resources:
  limits:
    memory: 80M
  requests:
    cpu: 100m
    memory: 30M
```
