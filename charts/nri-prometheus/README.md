# New Relic's Prometheus OpenMetrics Integration

## Chart Details

This chart will deploy the New Relic's Prometheus OpenMetrics Integration.

## Configuration

| Parameter                                                  | Description                                                                                                                                                                                                                           | Default                                |
|------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster.                                                                                                                                                                                          |                                        |
| `global.licenseKey` - `licenseKey`                         | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified. |                                        |
| `global.customSecretName` - `customSecretName`             | Name of the Secret object where the license key is stored                                                                                                                                                                             |                                        |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the Secret object where the license key is stored.                                                                                                                                                                             |                                        |
| `nameOverride`                                             | The name that should be used for the deployment.                                                                                                                                                                                      |                                        |
| `image.repository`                                         | The prometheus openmetrics integration image name.                                                                                                                                                                                    | `newrelic/nri-prometheus`              |
| `image.tag`                                                | The prometheus openmetrics integration image tag.                                                                                                                                                                                     | `2.2.0`                                |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                                                   | `nil`                                  |
| `resources`                                                | A yaml defining the resources for the events-router container.                                                                                                                                                                        | {}                                     |
| `rbac.create`                                              | Enable Role-based authentication                                                                                                                                                                                                      | `true`                                 |
| `serviceAccount.create`                                    | If true, a service account would be created and assigned to the deployment                                                                                                                                                            | true                                   |
| `serviceAccount.name`                                      | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                                                     |                                        |
| `serviceAccount.annotations`                               | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                                                              |                                        |
| `podAnnotations`                                           | If you wish to provide additional annotations to apply to the pod(s), specify them here.                                                                                                                                              |                                        |
| `priorityClassName`                                        | Scheduling priority of the pod                                                                                                                                                                                                        | `nil`                         |
| `nodeSelector`                                             | Node label to use for scheduling                                                                                                                                                                                                      | `{}`                                   |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                          | `[]`                                   |
| `affinity`                                                 | Node affinity to use for scheduling                                                                                                                                                                                                   | `{}`                                   |
| `prometheusScrape`                                         | Value for `prometheus.io/scrape` label                                                                                                                                                                                                | true                                   |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key)                                                                                                                                                                                 | false                                  |
| `config.*`                           | Set values used in the configMap                                                                                                                                                                             |                                   |
## Example


Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/nri-prometheus \
--set licenseKey=<enter_new_relic_license_key> \
--set cluster=my-k8s-cluster
```
