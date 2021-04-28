# newrelic-infrastructure

## Chart Details

This chart will deploy the New Relic Infrastructure agent as a Daemonset.

## Configuration

| Parameter                      | Description                                                                                                                                                                                                                                       | Default                         |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------|
| `global.cluster` - `cluster` | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                        |                                 |
| `global.licenseKey` - `licenseKey` | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified.         |                                 |
| `global.customSecretName` - `customSecretName` | Name of the Secret object where the license key is stored                                                                                                                                                                         |                                 |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the Secret object where the license key is stored.                                                                                                                                                             |                                 |
| `global.fargate`               | Must be set to `true` when deploying in an EKS Fargate environment. Prevents DaemonSet pods from being scheduled in Fargate nodes.  |                                 |
| `config`                       | A `newrelic.yml` file if you wish to provide.                                                                                                                                                                                                     |                                 |
| `enableLinux`                  | Deploys the `DaemonSet` on all Linux nodes                                                                                                                                                                                                        | `true`                          |
| `enableWindows`                | Deploys the `DaemonSet` on all Windows nodes (see [Running on Windows](#running-on-windows))                                                                                                                                                      | `false`                         |
| `integrations_config`          | List of Integrations configuration to monitor services running on Kubernetes. More information on can be found [here](https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-apps-services/monitor-services-running-kubernetes). |                                 |
| `disableKubeStateMetrics`      | Disables kube-state-metrics data parsing if the value is `true`.                                                                                                                                                                                 | `false`                         |
| `kubeStateMetricsUrl`          | If provided, the discovery process for kube-state-metrics endpoint won't be triggered. Example: http://172.17.0.3:8080                                                                                                                            |                                 |
| `kubeStateMetricsPodLabel`     | If provided, the kube-state-metrics pod will be discovered using this label. (should be `true` on target pod)                                                                                                                                     |                                 |
| `kubeStateMetricsTimeout`      | Timeout for accessing kube-state-metrics in milliseconds. If not set the newrelic default is 5000                                                                                                                                                 |                                 |
| `kubeStateMetricsScheme`       | If `kubeStateMetricsPodLabel` is present, it changes the scheme used to send to request to the pod.                                                                                                                                               | `http`                          |
| `kubeStateMetricsPort`         | If `kubeStateMetricsPodLabel` is present, it changes the port queried in the pod.                                                                                                                                                                 | 8080                            |
| `rbac.create`                  | Enable Role-based authentication                                                                                                                                                                                                                  | `true`                          |
| `rbac.pspEnabled`              | Enable pod security policy support                                                                                                                                                                                                                | `false`                         |
| `privileged`                   | Enable privileged mode.                                                                                                                                                                                                                           | `true`                          |
| `windowsSecurityContext`       | Set security context values for the Windows daemonset.                                                                                                                                                                                                                           | `{}`                          |
| `image.repository`             | The container to pull.                                                                                                                                                                                                                            | `newrelic/infrastructure-k8s`   |
| `image.pullPolicy`             | The pull policy.                                                                                                                                                                                                                                  | `IfNotPresent`                  |
| `image.pullSecrets`            | Image pull secrets.                                                                                                                                                                                                                               | `nil`                           |
| `image.tag`                    | The version of the container to pull.                                                                                                                                                                                                             | `2.4.0`                       |
| `image.windowsTag`             | (Deprecated) The version of the Windows container to pull.                                                                                                                                                                                                     | `1.21.0-windows-1809-alpha`     |
| `resources`                    | Any resources you wish to assign to the pod.                                                                                                                                                                                                      | See Resources below             |
| `podAnnotations`               | If you wish to provide additional annotations to apply to the pod(s), specify them here.                                                                                                                                                          |                                 |
| `verboseLog`                   | Should the agent log verbosely. (Boolean)                                                                                                                                                                                                         | `false`                         |
| `priorityClassName`            | Scheduling priority of the pod                                                                                                                                                                                                                    | `nil`                           |
| `nodeSelector`                 | Node label to use for scheduling                                                                                                                                                                                                                  | `nil`                           |
| `windowsNodeSelector`          | Node label to use for scheduling on Windows nodes                                                                                                                                                                                                 | `{ kubernetes.io/os: windows }` |
| `tolerations`                  | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                      | See Tolerations below           |
| `updateStrategy`               | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)                                                                                                                                                                                       | `RollingUpdate`                 |
| `serviceAccount.create`        | If true, a service account would be created and assigned to the deployment                                                                                                                                                                        | true                            |
| `serviceAccount.name`          | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                                                                 |                                 |
| `serviceAccount.annotations`   | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                                                                          |                                 |
| `etcdTlsSecretName`            | Name of the secret containing the cacert, cert and key used for setting the mTLS config for retrieving metrics from ETCD.                                                                                                                         |                                 |
| `etcdTlsSecretNamespace`       | Namespace where the secret specified in `etcdTlsSecretName` was created.                                                                                                                                                                          | `default`                       |
| `etcdEndpointUrl`              | Explicitly sets the etcd component url.                                                                                                                                                                                                           |                                 |
| `apiServerSecurePort`          | Set to query the API Server over a secure port.                                                                                                                                                                                                   |                                 |
| `apiServerEndpointUrl`         | Explicitly sets the api server component url.                                                                                                                                                                                                     |                                 |
| `schedulerEndpointUrl`         | Explicitly sets the scheduler component url.                                                                                                                                                                                                      |                                 |
| `controllerManagerEndpointUrl` | Explicitly sets the controller manager component url.                                                                                                                                                                                             |                                 |
| `eventQueueDepth`              | Increases the in-memory cache of the agent to accommodate for more samples at a time. | |
| `enableProcessMetrics`         | Enables the sending of process metrics to New Relic.  | `(empty)` (Account default<sup>1</sup>) |
| `global.nrStaging` - `nrStaging` | Send data to staging (requires a staging license key). | `false` |
| `discoveryCacheTTL`            | Duration since the discovered endpoints are stored in the cache until they expire. Valid time units: 'ns', 'us', 'ms', 's', 'm', 'h' | `1h` |
| `windowsOsList` | List of `windowsOs` to be monitored, for each object specified it will create a different daemonset for the specified Windows version. | [{"version":2004,"imageTag":"2.2.0-windows-2004-alpha","buildNumber":"10.0.19041"}] |
| `windowsOsList[].version` | Windows version monitored. | `2004` |
| `windowsOsList[].imageTag` | Tag for the container image compatible with the specified build version. | `2.2.0-windows-2004-alpha` |
| `windowsOsList[].buildNumber` | Build number associated to the specified Windows version. This value will be used to create a node selector `node.kubernetes.io/windows-build=buildNumber` | `10.0.19041` |
| `openshift.enabled` | Enables OpenShift configuration options. | `false` |
| `openshift.version` | OpenShift version for witch enable specific configuration options. Values supported ["3.x","4.x"]. For 4.x it includes OpenShift specific Control Plane endpoints and CRI-O runtime |  |
| `runAsUser` | Set when running in unprivileged mode or when hitting UID constraints in OpenShift. | `1000` |
| `daemonSet.annotations`   | The annotations to add to the `DaemonSet`.

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

## Running on Windows

When using containers in Windows, the container host version and the container image version must be the same. Our Kubernetes integration support Windows versions 1809 and 1909.

To check your Windows version:

* Open a command windows
* Run the following command:
```powershell
Reg Query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v
ReleaseIdcmd.exe
```

### Example: Get Kubernetes for Windows from a BusyBox container
```bash
$ kubectl exec -it busybox1-766bb4d6cc-rmsnj -- Reg Query
    "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId
```

Output
```bash
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion
	ReleaseId	REG_SZ	1809
```

### Windows Limitations

* The Windows agent only sends the Kubernetes samples (`K8sNodeSample`, `K8sPodSample`, etc.)
    * `SystemSample`, `StorageSample`, `NetworkSample`, and `ProcessSample` are not generated.
* Some [Kubernetes metrics](https://docs.newrelic.com/docs/integrations/kubernetes-integration/understand-use-data/understand-use-data#metrics) are missing because the Windows kubelet doesn’t have them:
    * Node:
        * `fsInodes`: not sent
        * `fsInodesFree`: not sent
        * `fsInodesUsed`: not sent
        * `memoryMajorPageFaultsPerSecond`: always returns zero as a value
        * `memoryPageFaults`: always returns zero as a value
        * `memoryRssBytes`: always returns zero as a value
        * `runtimeInodes`: not sent
        * `runtimeInodesFree`: not sent
        * `runtimeInodesUsed`: not sent
    * Pod:
        * `net.errorsPerSecond`: not sent
        * `net.rxBytesPerSecond`: not sent
        * `net.txBytesPerSecond`: not sent
    * Container:
        * `containerID`: not sent
        * `containerImageID`: not sent
        * `memoryUsedBytes`: in the UI, this is displayed in the pod card that appears when you click on a pod, and will show no data. We will soon fix this by updating our charts to use memoryWorkingSetBytes instead.
    * Volume:
        * `fsUsedBytes`: zero, so fsUsedPercent is zero

#### Multiple Windows node builds running in the same cluster

Multiple windows build for the nodes are supported by this chart. A different daemonSet is generated for each of them as specified by the value object `windowsOsList`.

Accordigly the old value for the Windows image `windowsTag` is deprecated and will be removed in the future. Currently if specified still overwrite the image tag specified by the windowsOsList.

Notice that the [kubernetes standard](https://kubernetes.io/docs/setup/production-environment/windows/user-guide-windows-containers/) for running containers over Windows, requires the presence of the label on the node `node.kubernetes.io/windows-build`. This label is added automatically to each node for versions `>1.17` but should be added manually otherwise.
This helm charts expects the presence of such labels on the different Windows node and schedules through nodeSelectors the daemonSets accordingly.

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
