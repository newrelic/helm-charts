# newrelic-pixie

## Chart Details

This chart will deploy the New Relic Pixie Integration.

IMPORTANT: In order to retrieve the Pixie cluster id from the `pl-cluster-secrets` the integration needs to be deployed in the same namespace as Pixie. By default, Pixie is installed in the `pl` namespace. Alternatively the `clusterId` can be configured manually when installing the chart. In this case the integration can be deployed to any namespace.

## Configuration

| Parameter                                                  | Description                                                                                                                                                                                        | Default               |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster. Required.                                                                                                                                             |                       |
| `global.licenseKey` - `licenseKey`                         | The New Relic license key (stored in a secret). Required.                                                                                                                                          |                       |
| `global.lowDataMode` - `lowDataMode`                       | If `true`, the integration performs heavier sampling on the Pixie span data and sets the collect interval to 15 seconds instead of 10 seconds.                                                     | false                 |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key).                                                                                                                                             | false                 |
| `apiKey`                                                   | The Pixie API key (stored in a secret). Required.                                                                                                                                                  |                       |
| `clusterId`                                                | The Pixie cluster id. Optional. Read from the `pl-cluster-secrets` secret if empty.                                                                                                                |                       |
| `endpoint`                                                 | The Pixie endpoint. Required when using Pixie Open Source.                                                                                                                                         |                       |
| `verbose`                                                  | Whether the integration should run in verbose mode or not.                                                                                                                                         | false                 |
| `global.customSecretName` - `customSecretName`             | Name of an existing Secret object, not created by this chart, where the New Relic license is stored                                                                                                |                       |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the existing Secret object, indicated by `customSecretName`, where the New Relic license key is stored.                                                                                     |                       |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                | `nil`                 |
| `customSecretApiKeyName`                                   | Name of an existing Secret object, not created by this chart, where the Pixie API key is stored.                                                                                                   |                       |
| `customSecretApiKeyKey`                                    | Key in the existing Secret object, indicated by `customSecretApiKeyName`, where the Pixie API key is stored.                                                                                       |                       |
| `podLabels`                                             | Labels added to each Job pod                                                                                                              | `{}`                  |
| `podAnnotations`                                             | Annotations added to each Job pod                                                                                                              | `{}`                  |
| `job.annotations`                                             | Annotations added to the `newrelic-pixie` Job resource                                                                                                              | `{}`                  |
| `job.labels`                                             | Annotations added to the `newrelic-pixie` Job resource                                                                                                              | `{}`                  |
| `nodeSelector`                                             | Node label to use for scheduling.                                                                                                                                                                  | `{}`                  |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6).                                                                                                                                      | `[]`                  |
| `affinity`                                                 | Node affinity to use for scheduling.                                                                                                                                                               | `{}`                  |
| `proxy`                                                    | Set proxy to connect to Pixie Cloud and New Relic.                                                                                                                                                 |                       |
| `customScripts`                                            | YAML containing custom scripts for long-term data retention. The results of the custom scripts will be stored in New Relic. See [custom scripts](#custom-scripts) for YAML format.                 | `{}`                  |
| `customScriptsConfigMap`                                   | Name of an existing ConfigMap object containing custom script for long-term data retention. This configuration takes precedence over `customScripts`.                                              |                       |
| `excludeNamespacesRegex`                                   | Observability data for namespaces matching this RE2 regex is not sent to New Relic. If empty, observability data for all namespaces is sent to New Relic.                                          |                       |
| `excludePodsRegex`                                         | Observability data for pods (across all namespaces) matching this RE2 regex is not sent to New Relic. If empty, observability data for all pods (in non-excluded namespaces) is sent to New Relic. |                       |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-pixie \
  --set cluster=<Kubernetes cluster name> \
  --set licenseKey=<Your New Relic license key> \
  --set apiKey=<Your Pixie API key> \ 
  --namespace pl \
  --generate-name
```

## Globals

**Important:** global parameters have higher precedence than locals with the same name.

These are meant to be used when you are writing a chart with subcharts. It helps to avoid
setting values multiple times on different subcharts.

More information on globals and subcharts can be found at [Helm's official documentation](https://helm.sh/docs/topics/chart_template_guide/subcharts_and_globals/).

| Parameter                       |
| ------------------------------- |
| `global.cluster`                |
| `global.licenseKey`             |
| `global.customSecretName`       |
| `global.customSecretLicenseKey` |
| `global.lowDataMode`            |
| `global.nrStaging`              |

## Custom scripts

Custom scripts can either be configured directly in `customScripts` or be provided through an existing ConfigMap `customScriptsConfigMap`.

The entries in the ConfigMap should contain file-like keys with the `.yaml` extension. Each file in the ConfigMap should be valid YAML and contain the following keys:

 * name (string): the name of the script
 * description (string): description of the script
 * frequencyS (int): frequency to execute the script in seconds
 * scripts (string): the actual PXL script to execute
 * addExcludes (optional boolean, `false` by default): add pod and namespace excludes to the custom script

For more detailed information about the custom scripts see [the New Relic Pixie integration repo](https://github.com/newrelic/newrelic-pixie-integration/).

```yaml
customScripts:
  custom1.yaml: |
    name: "custom1"
    description: "Custom script 1"
    frequencyS: 60
    script: |
      import px

      df = px.DataFrame(table='http_events', start_time=px.plugin.start_time)

      ns_prefix = df.ctx['namespace'] + '/'
      df.container = df.ctx['container_name']
      df.pod = px.strip_prefix(ns_prefix, df.ctx['pod'])
      df.service = px.strip_prefix(ns_prefix, df.ctx['service'])
      df.namespace = df.ctx['namespace']

      df.status_code = df.resp_status

      df = df.groupby(['status_code', 'pod', 'container','service', 'namespace']).agg(
          latency_min=('latency', px.min),
          latency_max=('latency', px.max),
          latency_sum=('latency', px.sum),
          latency_count=('latency', px.count),
          time_=('time_', px.max),
      )

      df.latency_min = df.latency_min / 1000000
      df.latency_max = df.latency_max / 1000000
      df.latency_sum = df.latency_sum / 1000000

      df.cluster_name = px.vizier_name()
      df.cluster_id = px.vizier_id()
      df.pixie = 'pixie'

      px.export(
        df, px.otel.Data(
          resource={
            'service.name': df.service,
            'k8s.container.name': df.container,
            'service.instance.id': df.pod,
            'k8s.pod.name': df.pod,
            'k8s.namespace.name': df.namespace,
            'px.cluster.id': df.cluster_id,
            'k8s.cluster.name': df.cluster_name,
            'instrumentation.provider': df.pixie,
          },
          data=[
            px.otel.metric.Summary(
              name='http.server.duration',
              description='measures the duration of the inbound HTTP request',
              # Unit is not supported yet
              # unit='ms',
              count=df.latency_count,
              sum=df.latency_sum,
              quantile_values={
                0.0: df.latency_min,
                1.0: df.latency_max,
              },
              attributes={
                'http.status_code': df.status_code,
              },
          )],
        ),
      )
```


## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    memory: 250M
  requests:
    cpu: 100m
    memory: 250M
```

