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
| `config`                       | A `newrelic.yml` file if you wish to provide.                                                                                                                                                                                                     |                                 |
| `enableLinux`                  | Deploys the `DaemonSet` on all Linux nodes                                                                                                                                                                                                        | `true`                          |
| `enableWindows`                | Deploys the `DaemonSet` on all Windows nodes (see [Running on Windows](#running-on-windows))                                                                                                                                                      | `false`                         |
| `integrations_config`          | List of Integrations configuration to monitor services running on Kubernetes. More information on can be found [here](https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-apps-services/monitor-services-running-kubernetes). |                                 |
| `disableKubeStateMetrics`      | Disables kube-state-metrics data parsing if the value is ` true`.                                                                                                                                                                                 | `false`                         |
| `kubeStateMetricsUrl`          | If provided, the discovery process for kube-state-metrics endpoint won't be triggered. Example: http://172.17.0.3:8080                                                                                                                            |                                 |
| `kubeStateMetricsPodLabel`     | If provided, the kube-state-metrics pod will be discovered using this label. (should be `true` on target pod)                                                                                                                                     |                                 |
| `kubeStateMetricsTimeout`      | Timeout for accessing kube-state-metrics in milliseconds. If not set the newrelic default is 5000                                                                                                                                                 |                                 |
| `kubeStateMetricsScheme`       | If `kubeStateMetricsPodLabel` is present, it changes the scheme used to send to request to the pod.                                                                                                                                               | `http`                          |
| `kubeStateMetricsPort`         | If `kubeStateMetricsPodLabel` is present, it changes the port queried in the pod.                                                                                                                                                                 | 8080                            |
| `rbac.create`                  | Enable Role-based authentication                                                                                                                                                                                                                  | `true`                          |
| `rbac.pspEnabled`              | Enable pod security policy support                                                                                                                                                                                                                | `false`                         | 
| `privileged`                   | Enable privileged mode.                                                                                                                                                                                                                           | `true`                          |
| `image.repository`             | The container to pull.                                                                                                                                                                                                                            | `newrelic/infrastructure-k8s`   |
| `image.pullPolicy`             | The pull policy.                                                                                                                                                                                                                                  | `IfNotPresent`                  |
| `image.tag`                    | The version of the container to pull.                                                                                                                                                                                                             | `1.26.1`                        |
| `image.windowsTag`             | The version of the Windows container to pull.                                                                                                                                                                                                     | `1.21.0-windows-1809-alpha`     |
| `resources`                    | Any resources you wish to assign to the pod.                                                                                                                                                                                                      | See Resources below             |
| `verboseLog`                   | Should the agent log verbosely. (Boolean)                                                                                                                                                                                                         | `false`                         |
| `priorityClassName`            | Scheduling priority of the pod                                                                                                                                                                                                                    | `nil`                           |
| `nodeSelector`                 | Node label to use for scheduling                                                                                                                                                                                                                  | `nil`                           |
| `windowsNodeSelector`          | Node label to use for scheduling on Windows nodes                                                                                                                                                                                                 | `{ kubernetes.io/os: windows }` |
| `tolerations`                  | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                      | See Tolerations below           |
| `updateStrategy`               | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)                                                                                                                                                                                       | `RollingUpdate`                 |
| `serviveAccount.create`        | If true, a service account would be created and assigned to the deployment                                                                                                                                                                        | true                            |
| `serviveAccount.name`          | The service account to assign to the deployment. If `serviveAccount.create` is true then this name will be used when creating the service account                                                                                                 |                                 |
| `etcdTlsSecretName`            | Name of the secret containing the cacert, cert and key used for setting the mTLS config for retrieving metrics from ETCD.                                                                                                                         |                                 |
| `etcdTlsSecretNamespace`       | Namespace where the secret specified in `etcdTlsSecretName` was created.                                                                                                                                                                          | `default`                       |
| `etcdEndpointUrl`              | Explicitly sets the etcd component url.                                                                                                                                                                                                           |                                 |
| `apiServerSecurePort`          | Set to query the API Server over a secure port.                                                                                                                                                                                                   |                                 |
| `apiServerEndpointUrl`         | Explicitly sets the api server componenturl.                                                                                                                                                                                                      |                                 |
| `schedulerEndpointUrl`         | Explicitly sets the scheduler component url.                                                                                                                                                                                                      |                                 |
| `controllerManagerEndpointUrl` | Explicitly sets the controller manager component url.                                                                                                                                                                                             |                                 |
| `eventQueueDepth`              | Increases the in-memory cache of the agent to accommodate for more samples at a time. | |
| `global.nrStaging` - `nrStaging` | Send data to staging (requires a staging license key). | `false` |

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
