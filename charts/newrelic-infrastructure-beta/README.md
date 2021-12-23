# newrelic-infrastructure

## Chart Details

This chart will deploy the New Relic Infrastructure agent as a Daemonset.

## Configuration

| Parameter                                                  | Description                                                                                                                                                                                                                                       | Default                                                                             |
|------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                      |                                                                                     |
| `global.licenseKey` - `licenseKey`                         | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified.             |                                                                                     |
| `global.customSecretName`       - `customSecretName`       | Name of the Secret object where the license key is stored                                                                                                                                                                                         |                                                                                     |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key  in the Secret object where the license key is stored.                                                                                                                                                                                        |                                                                                     |
| `global.fargate`                                           | Must be set to `true` when deploying in an EKS Fargate environment. Prevents DaemonSet pods from being scheduled in Fargate nodes.                                                                                                                |                                                                                     |
| `config`                                                   | A `newrelic.yml` file if you wish to provide.                                                                                                                                                                                                     |                                                                                     |
| `integrations_config`                                      | List of Integrations configuration to monitor services running on Kubernetes. More information on can be found [here](https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-apps-services/monitor-services-running-kubernetes). |                                                                                     |
| `disableKubeStateMetrics`                                  | Disables kube-state-metrics data parsing if the value is `true`.                                                                                                                                                                                  | `false`                                                                             |
| `kubeStateMetricsUrl`                                      | If provided, the discovery process for kube-state-metrics endpoint won't be triggered. Example: http://172.17.0.3:8080                                                                                                                            |                                                                                     |
| `kubeStateMetricsPodLabel`                                 | If provided, the kube-state-metrics pod will be discovered using this label. (should be `true` on target pod)                                                                                                                                     |                                                                                     |
| `kubeStateMetricsTimeout`                                  | Timeout for accessing kube-state-metrics in milliseconds. If not set the newrelic default is 5000                                                                                                                                                 |                                                                                     |
| `kubeStateMetricsScheme`                                   | If `kubeStateMetricsPodLabel` is present, it changes the scheme used to send to request to the pod.                                                                                                                                               | `http`                                                                              |
| `kubeStateMetricsPort`                                     | If `kubeStateMetricsPodLabel` is present, it changes the port queried in the pod.                                                                                                                                                                 | 8080                                                                                |
| `rbac.create`                                              | Enable Role-based authentication                                                                                                                                                                                                                  | `true`                                                                              |
| `rbac.pspEnabled`                                          | Enable pod security policy support                                                                                                                                                                                                                | `false`                                                                             |
| `privileged`                                               | Enable privileged mode.                                                                                                                                                                                                                           | `true`                                                                              |
| `image.repository`                                         | The container to pull.                                                                                                                                                                                                                            | `newrelic/infrastructure-k8s`                                                       |
| `image.pullPolicy`                                         | The pull policy.                                                                                                                                                                                                                                  | `IfNotPresent`                                                                      |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                                                               | `nil`                                                                               |
| `image.tag`                                                | The version of the container to pull.                                                                                                                                                                                                             | `2.4.0`                                                                             |
| `resources`                                                | Any resources you wish to assign to the pod.                                                                                                                                                                                                      | See Resources below                                                                 |
| `podAnnotations`                                           | If you wish to provide additional annotations to apply to the pod(s), specify them here.                                                                                                                                                          |                                                                                     |
| `verboseLog`                                               | Should the agent log verbosely. (Boolean)                                                                                                                                                                                                         | `false`                                                                             |
| `priorityClassName`                                        | Scheduling priority of the pod                                                                                                                                                                                                                    | `nil`                                                                               |
| `nodeSelector`                                             | Node label to use for scheduling                                                                                                                                                                                                                  | `nil`                                                                               |
| `tolerations`                                              | List of node taints to tolerate                                                                                                                                                                                                                   | See Tolerations below                                                               |
| `updateStrategy`                                           | Update strategy the DaemonSets                                                                                                                                                                                                | `type=RollingUpdate,rollingUpdate.maxUnavailable=1`                                 |
| `serviceAccount.create`                                    | If true, a service account would be created and assigned to the deployment                                                                                                                                                                        | true                                                                                |
| `serviceAccount.name`                                      | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                                                                 |                                                                                     |
| `serviceAccount.annotations`                               | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                                                                          |                                                                                     |
| `etcdTlsSecretName`                                        | Name of the secret containing the cacert, cert and key used for setting the mTLS config for retrieving metrics from ETCD.                                                                                                                         |                                                                                     |
| `etcdTlsSecretNamespace`                                   | Namespace where the secret specified in `etcdTlsSecretName` was created.                                                                                                                                                                          | `default`                                                                           |
| `etcdEndpointUrl`                                          | Explicitly sets the etcd component url.                                                                                                                                                                                                           |                                                                                     |
| `apiServerSecurePort`                                      | Set to query the API Server over a secure port.                                                                                                                                                                                                   |                                                                                     |
| `apiServerEndpointUrl`                                     | Explicitly sets the api server component url.                                                                                                                                                                                                     |                                                                                     |
| `schedulerEndpointUrl`                                     | Explicitly sets the scheduler component url.                                                                                                                                                                                                      |                                                                                     |
| `controllerManagerEndpointUrl`                             | Explicitly sets the controller manager component url.                                                                                                                                                                                             |                                                                                     |
| `eventQueueDepth`                                          | Increases the in-memory cache of the agent to accommodate for more samples at a time.                                                                                                                                                             |                                                                                     |
| `enableProcessMetrics`                                     | Enables the sending of process metrics to New Relic.                                                                                                                                                                                              | `(empty)` (Account default<sup>1</sup>)                                             |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key).                                                                                                                                                                                            | `false`                                                                             |
| `discoveryCacheTTL`                                        | Duration since the discovered endpoints are stored in the cache until they expire. Valid time units: 'ns', 'us', 'ms', 's', 'm', 'h'                                                                                                              | `1h`                                                                                |
| `openshift.enabled`                                        | Enables OpenShift configuration options.                                                                                                                                                                                                          | `false`                                                                             |
| `openshift.version`                                        | OpenShift version for witch enable specific configuration options. Values supported ["3.x","4.x"]. For 4.x it includes OpenShift specific Control Plane endpoints and CRI-O runtime                                                               |                                                                                     |
| `runAsUser`                                                | Set when running in unprivileged mode or when hitting UID constraints in OpenShift.                                                                                                                                                               | `1000`                                                                              |
| `daemonSet.annotations`                                    | The annotations to add to the `DaemonSet`.                                                                                                                                                                                                        |                                                                                     |

> 1: Default value will depend on the creation date of the account owning the specified License Key:
> * Accounts and subaccounts created before July 20, 2020 will report, by default, process metrics unless this config option is explicitly set to `false`. This is done to respect the old default behavior of the Infrastructure Agent.
> * New Relic accounts created after July 20, 2020 will **not** send, by default, any process metrics unless this config option is explicitly set to `true`.
>
> [Additional information](https://docs.newrelic.com/docs/release-notes/infrastructure-release-notes/infrastructure-agent-release-notes/new-relic-infrastructure-agent-1120)
## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-infrastructure \
--set licenseKey=<enter_new_relic_license_key> \
--set cluster=my-k8s-cluster
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

## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    memory: 150M
  requests:
    cpu: 100m
    memory: 30M
```

## Tolerations

The default set of relations assigned to our daemonset is shown below:

```yaml
- operator: "Exists"
  effect: "NoSchedule"
- operator: "Exists"
  effect: "NoExecute"
```

# Config file

If you wish to provide your own `newrelic.yml` you may do so under `config`. There are a few notable exceptions you should be aware of. Some options have been omitted because they are handled either by variables, or a secret. They are `display_name`, `license_key`, `log_file` and `verbose`.


# Past Contributors

This chart started as a community project in the [stable Helm chart repository](github.com/helm/charts/). New Relic is very thankful
for all the 15+ community members that contributed and helped maintain the chart there over the years:

* coreypobrien
* sstarcher
* jmccarty3
* slayerjain
* ryanhope2
* rk295
* michaelajr
* isindir
* idirouhab
* ismferd
* enver
* diclophis
* jeffdesc
* costimuraru
* verwilst
* ezelenka
