# newrelic-logging


## Chart Details
New Relic offers a [Fluent Bit](https://fluentbit.io/) output [plugin](https://github.com/newrelic/newrelic-fluent-bit-output) to easily forward your logs to [New Relic Logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs). This plugin is also provided in a standalone Docker image that can be installed in a [Kubernetes](https://kubernetes.io/) cluster in the form of a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), which we refer as the Kubernetes plugin.

This document explains how to install it in your cluster, either using a [Helm](https://helm.sh/) chart (recommended), or manually by applying Kubernetes manifests.


## Install / Uninstall instructions
Despite the `newrelic-logging` chart being able to work standalone, we recommend installing it as part of the [`nri-bundle`](https://github.com/newrelic/helm-charts/tree/master/charts/nri-bundle) chart. The best way of doing so is through the guided installation process documented [here](https://docs.newrelic.com//docs/kubernetes-pixie/kubernetes-integration/installation/kubernetes-integration-install-configure/). This guided install can generate the Helm 3 commands required to install it (select "Helm 3" in Step 3 from the previous documentation link). You can also opt to install it manually using Helm by following [these steps](https://docs.newrelic.com//docs/kubernetes-pixie/kubernetes-integration/installation/install-kubernetes-integration-using-helm/#install-k8-helm). To uninstall it, refer to the steps outlined in [this page](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/uninstall-kubernetes/).


## Configuration


### How to configure the chart
The `newrelic-logging` chart can be installed either alone or as part of the [`nri-bundle`](https://github.com/newrelic/helm-charts/tree/master/charts/nri-bundle) chart (recommended). The chart default settings should be suitable for most users. Nevertheless, you may be interested in overriding the defaults, either by passing them through a `values-newrelic.yaml` file or via the command line when installing the chart. Depending on how you installed it, you'll need to specify the `newrelic-logging`-specific configuration values using the chart name (`newrelic-logging`) as a prefix. In the table below, you can find a quick reference of how to configure the chart in these scenarios. The example depicts how you'd specify the mandatory `licenseKey` and `cluster` settings and how you'd override the `fluentBit.retryLimit` setting to `10`.

<table>
    <tr>
        <td><b>Installation method</b></td>
        <td><b>Configuration via <i>values.yaml</i></b></td>
        <td><b>Configuration via command line</b></td>
    </tr>
    <tr>
        <td>Standalone <i>newrelic-logging</i></td>
        <td>


```
# values-newrelic.yaml configuration contents

licenseKey: _YOUR_NEW_RELIC_LICENSE_KEY_
cluster: _K8S_CLUSTER_NAME_

fluentBit:
  retryLimit: 10
```

```
# Installation command

helm upgrade --install newrelic-logging newrelic/newrelic-logging \
--namespace newrelic \
--create-namespace \
-f values-newrelic.yaml
```
</td>
        <td>

```
# Installation/configuration command

helm upgrade --install newrelic-logging newrelic/newrelic-logging \
--namespace=newrelic \
--set licenseKey=_YOUR_NEW_RELIC_LICENSE_KEY_ \
--set cluster=_K8S_CLUSTER_NAME_ \
--set fluentBit.retryLimit=10
```
</td>
    </tr>
    <tr>
        <td>As part of <i>nri-bundle</i></td>
        <td>

```
# values-newrelic.yaml configuration contents

# General settings that apply to all the child charts
global:
  licenseKey: _YOUR_NEW_RELIC_LICENSE_KEY_
  cluster: _K8S_CLUSTER_NAME_

# Specific configuration for the newrelic-logging child chart
newrelic-logging:
  fluentBit:
    retryLimit: 10
```

```
# Installation command

helm upgrade --install newrelic-bundle newrelic/nri-bundle \
  --namespace newrelic \
  --create-namespace \
  -f values-newrelic.yaml \
```
</td>
        <td>

```
# Installation/configuration command

helm upgrade --install newrelic-bundle newrelic/nri-bundle \
--namespace=newrelic \
--set global.licenseKey=_YOUR_NEW_RELIC_LICENSE_KEY_ \
--set global.cluster=_K8S_CLUSTER_NAME_ \
--set newrelic-logging.fluentBit.retryLimit=10
```
</td>
    </tr>
</table>


### Supported configuration parameters
See [values.yaml](values.yaml) for the default values

| Parameter                                                  | Description                                                                                                                                                                                                                                                                                                                                                    | Default                                                                         |
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                                                                                                                                   |                                                                                 |
| `global.licenseKey` - `licenseKey`                         | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be the preferred configuration option if both `licenseKey` and `customSecret*` values are specified.                                                                                                              |                                                                                 |
| `global.customSecretName` - `customSecretName`             | Name of the Secret object where the license key is stored                                                                                                                                                                                                                                                                                                      |                                                                                 |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the Secret object where the license key is stored.                                                                                                                                                                                                                                                                                                      |                                                                                 |
| `global.fargate`                                           | Must be set to `true` when deploying in an EKS Fargate environment. Prevents DaemonSet pods from being scheduled in Fargate nodes.                                                                                                                                                                                                                             |                                                                                 |
| `global.lowDataMode` - `lowDataMode`                       | If `true`, send minimal attributes on Kubernetes logs. Labels and annotations are not sent when lowDataMode is enabled.                                                                                                                                                                                                                                        | `false`                                                                         |
| `rbac.create`                                              | Enable Role-based authentication                                                                                                                                                                                                                                                                                                                               | `true`                                                                          |
| `rbac.pspEnabled`                                          | Enable pod security policy support                                                                                                                                                                                                                                                                                                                             | `false`                                                                         |
| `image.repository`                                         | The container to pull.                                                                                                                                                                                                                                                                                                                                         | `newrelic/newrelic-fluentbit-output`                                            |
| `image.pullPolicy`                                         | The pull policy.                                                                                                                                                                                                                                                                                                                                               | `IfNotPresent`                                                                  |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                                                                                                                                                                            | `nil`                                                                           |
| `image.tag`                                                | The version of the container to pull.                                                                                                                                                                                                                                                                                                                          | See value in [values.yaml]`                                                     |
| `exposedPorts`                                             | Any ports you wish to expose from the pod.  Ex. 2020 for metrics                                                                                                                                                                                                                                                                                               | `[]`                                                                            |
| `resources`                                                | Any resources you wish to assign to the pod.                                                                                                                                                                                                                                                                                                                   | See Resources below                                                             |
| `priorityClassName`                                        | Scheduling priority of the pod                                                                                                                                                                                                                                                                                                                                 | `nil`                                                                           |
| `nodeSelector`                                             | Node label to use for scheduling on Linux nodes                                                                                                                                                                                                                                                                                                                | `{ kubernetes.io/os: linux }`                                                   |
| `windowsNodeSelector`                                      | Node label to use for scheduling on Windows nodes                                                                                                                                                                                                                                                                                                              | `{ kubernetes.io/os: windows, node.kubernetes.io/windows-build: BUILD_NUMBER }` |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                                                                                                                                   | See Tolerations below                                                           |
| `updateStrategy`                                           | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)                                                                                                                                                                                                                                                                                                    | `RollingUpdate`                                                                 |
| `extraVolumeMounts`                                        | Additional DaemonSet volume mounts	                                                                                                                                                                                                                                                                                                                            | `[]`                                                                            |
| `extraVolumes`                                             | Additional DaemonSet volumes                                                                                                                                                                                                                                                                                                                                   | `[]`                                                                            |
| `initContainers`                                           | [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that will be executed before the actual container in charge of shipping logs to New Relic is initialized. Use this if you are using a custom Fluent Bit configuration that requires downloading certain files inside the volumes being accessed by the log-shipping pod. | `[]`                                                                            |
| `windows.initContainers`                                   | [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that will be executed before the actual container in charge of shipping logs to New Relic is initialized. Use this if you are using a custom Fluent Bit configuration that requires downloading certain files inside the volumes being accessed by the log-shipping pod. | `[]`                                                                            |
| `serviceAccount.create`                                    | If true, a service account would be created and assigned to the deployment                                                                                                                                                                                                                                                                                     | `true`                                                                          |
| `serviceAccount.name`                                      | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                                                                                                                                                                              |                                                                                 |
| `serviceAccount.annotations`                               | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                                                                                                                                                                                       |                                                                                 |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key)                                                                                                                                                                                                                                                                                                          | `false`                                                                         |
| `fluentBit.path`                                           | Node path logs are forwarded from. Patterns are supported, as well as specifying multiple paths/patterns separated by commas.                                                                                                                                                                                                                                  | `/var/log/containers/*.log`                                                     |
| `fluentBit.db`                                             | Node path used by Fluent Bit to store a database file to keep track of monitored files and offsets.                                                                                                                                                                                                                                                                          | `/var/log/containers/*.log`                                                     |
| `fluentBit.criEnabled`                                     | We assume that `kubelet`directly communicates with the Docker container engine. Set this to `true` if your K8s installation uses [CRI](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/) instead, in order to get the logs properly parsed.                                                                                   | `false`                                                                         |
| `fluentBit.k8sBufferSize`                                  | Set the buffer size for HTTP client when reading responses from Kubernetes API server. A value of 0 results in no limit and the buffer will expand as needed.                                                                                                                                                                                                  | `32k`                                                                           |
| `fluentBit.k8sLoggingExclude`                              | Set to "On" to allow excluding pods by adding the annotation `fluentbit.io/exclude: "true"` to pods you wish to exclude.                                                                                                                                                                                                                                       | `Off`                                                                           |
| `fluentBit.additionalEnvVariables`                         | Additional environmental variables for fluentbit pods                                                                                                                                                                                                                                                                                                          | `[]]`                                                                           |
| `daemonSet.annotations`                                    | The annotations to add to the `DaemonSet`.                                                                                                                                                                                                                                                                                                                     |                                                                                 |
| `podAnnotations`                                           | The annotations to add to the `DaemonSet` created `Pod`s.                                                                                                                                                                                                                                                                                                      |                                                                                 |
| `enableLinux`                                              | Enable log collection from Linux containers. This is the default behavior. In case you are only interested of collecting logs from Windows containers, set this to `false`.                                                                                                                                                                                    | `true`                                                                          |
| `enableWindows`                                            | Enable log collection from Windows containers. Please refer to the [Windows support](#windows-support) section for more details.                                                                                                                                                                                                                               | `false`                                                                         |
| `fluentBit.config.service`                                 | Contains fluent-bit.conf Service config                                                                                                                                                                                                                                                                                                                        |                                                                                 |
| `fluentBit.config.inputs`                                  | Contains fluent-bit.conf Inputs config                                                                                                                                                                                                                                                                                                                         |                                                                                 |
| `fluentBit.config.extraInputs`                             | Contains extra fluent-bit.conf Inputs config                                                                                                                                                                                                                                                                                                                   |                                                                                 |
| `fluentBit.config.filters`                                 | Contains fluent-bit.conf Filters config                                                                                                                                                                                                                                                                                                                        |                                                                                 |
| `fluentBit.config.extraFilters`                            | Contains extra fluent-bit.conf Filters config                                                                                                                                                                                                                                                                                                                  |                                                                                 |
| `fluentBit.config.lowDataModeFilters`                      | Contains fluent-bit.conf Filters config for lowDataMode                                                                                                                                                                                                                                                                                                        |                                                                                 |
| `fluentBit.config.outputs`                                 | Contains fluent-bit.conf Outputs config                                                                                                                                                                                                                                                                                                                        |                                                                                 |
| `fluentBit.config.extraOutputs`                            | Contains extra fluent-bit.conf Outputs config                                                                                                                                                                                                                                                                                                                  |                                                                                 |
| `fluentBit.config.parsers`                                 | Contains parsers.conf Parsers config                                                                                                                                                                                                                                                                                                                           |                                                                                 |
| `fluentBit.retryLimit`                                     | Amount of times to retry sending a given batch of logs to New Relic. This prevents data loss if there is a temporary network disruption, if a request to the Logs API is lost or when receiving a recoverable HTTP response. Set it to "False" for unlimited retries.                                                                                          | 5                                                                               |


### Proxy support

Since Fluent Bit Kubernetes plugin is using [newrelic-fluent-bit-output](https://github.com/newrelic/newrelic-fluent-bit-output) we can configure the [proxy support](https://github.com/newrelic/newrelic-fluent-bit-output#proxy-support) in order to set up the proxy configuration.


#### As environment variables

The easiest way to configure the proxy is by means of specifying the `HTTP_PROXY` or `HTTPS_PROXY` variables as follows:

```
# values-newrelic.yml

fluentBit:
   additionalEnvVariables:
     - name: HTTPS_PROXY
       value: https://your-https-proxy-hostname:3129
```


#### Custom proxy configuration (for proxies using self-signed certificates)

If you need to use a proxy using self-signed certificates, you'll need to mount a volume with the Certificate Authority 
bundle file and reference it from the Fluent Bit configuration as follows:

```
# values-newrelic.yaml
extraVolumes: []
 - name: proxyConfig
   # Example using hostPath. You can also place the caBundleFile.pem contents in a ConfigMap and reference it here instead,
   # as explained here: https://kubernetes.io/docs/concepts/storage/volumes/#configmap
   hostPath:
     path: /path/in/node/to/your/caBundleFile.pem

extraVolumeMounts: []
 - name: proxyConfig
   mountPath: /proxyConfig/caBundleFile.pem

fluentBit:
   config:
     outputs: |
       [OUTPUT]
           Name           newrelic
           Match          *
           licenseKey     ${LICENSE_KEY}
           endpoint       ${ENDPOINT}
           lowDataMode    ${LOW_DATA_MODE}
           Retry_Limit    ${RETRY_LIMIT}
           proxy          https://your-https-proxy-hostname:3129
           caBundleFile   /proxyConfig/caBundleFile.pem
```


## Windows support

Since version `1.7.0`, this Helm chart supports shipping logs from Windows containers. To this end, you need to set the `enableWindows` configuration parameter to `true`.

Windows containers have some constraints regarding Linux containers. The main one being that they can only be executed on _hosts_ using the exact same Windows version and build number. On the other hand, Kubernetes nodes only supports the Windows versions listed [here](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/#windows-os-version-support).

This Helm chart deploys one `DaemonSet` for each of the Windows versions it supports, while ensuring that only containers matching the host operating system will be deployed in each host.

This Helm chart currently supports the following Windows versions:
-  Windows Server LTSC 2019, build 10.0.17763
-  Windows Server LTSC 2022, build 10.0.20348