# newrelic-windows-logging

## Chart Details

## Windows Deployment

This project is a New Relic field solution and is provided **AS-IS WITHOUT WARRANTY OR SUPPORT**, although you can report issues and contribute to the project here on GitHub.

Since v1.5.0, Fluent Bit supports deployment to Windows pods. New Relic offers a [Fluent Bit](https://fluentbit.io/) output [plugin](https://github.com/newrelic/newrelic-fluent-bit-output) to easily forward your logs to [New Relic Logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs). This plugin is also provided in a [standalone Docker image](https://github.com/andrew-lozoya/newrelic-fluent-bit-output/blob/master/Dockerfile) that can be installed in a [Kubernetes](https://kubernetes.io/) cluster in the form of a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), which we refer as the Kubernetes plugin.

This document explains how to install it in your cluster, either using a [Helm](https://helm.sh/) chart (recommended). Starting with chart version 2.7.1, chart deploys the daemonset on windows nodes which collects std{out;err} logs of the containers running on windows nodes.

### Understanding the Log files used.

When deploying Fluent Bit to Kubernetes, there are three log files that you need to pay attention to.

`C:\k\kubelet.err.log`

 * This is the error log file from kubelet daemon running on host.
 * You will need to retain this file for future troubleshooting (to debug deployment failures etc.)

`C:\var\log\containers\<pod>_<namespace>_<container>-<docker>.log`

 * This is the main log file you need to watch. Configure Fluent Bit to follow this file.
 * It is actually a symlink to the Docker log file in `C:\ProgramData\`, with some additional metadata on its file name.

`C:\ProgramData\Docker\containers\<docker>\<docker>.log`

 * This is the log file produced by Docker.
 * Normally you don't directly read from this file, but you need to make sure that this file is visible from Fluent Bit.

## Installation

### Install using the Helm chart (recommended)

 1. Install Helm following the [official instructions](https://helm.sh/docs/intro/install/).

 2. Add the New Relic official Helm chart repository following [these instructions](../../README.md#installing-charts)

 3. Run the following command to install the New Relic Logging Kubernetes plugin via Helm, replacing the placeholder value `YOUR_LICENSE_KEY` with your [New Relic license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key):
    * Helm 3
        ```sh
        helm install newrelic-logging newrelic/newrelic-logging --set licenseKey=YOUR_LICENSE_KEY
        ```
    * Helm 2
        ```sh
        helm install newrelic/newrelic-logging --name newrelic-logging --set licenseKey=YOUR_LICENSE_KEY
        ```

> For EU users, add `--set endpoint=https://log-api.eu.newrelic.com/log/v1 to any of the helm install commands above.

> By default, tailing is set to `C:\\var\\log\\containers\\*.log`. To change this setting, provide your preferred path by adding `--set fluentBit.path=DESIRED_PATH` to any of the helm install commands above.

## Configuration

See [values.yaml](values.yaml) for the default values

| Parameter                                      | Description                                                                                                                                                                                                                                       | Default                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `global.licenseKey` - `licenseKey`             | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be the preferred configuration option if both `licenseKey` and `customSecret*` values are specified. |                                      |
| `global.customSecretName` - `customSecretName` | Name of the Secret object where the license key is stored                                                                                                                                                                                         |                                      |
| `global.customSecretLicenseKey` - `customSecretLicenseKey`   | Key in the Secret object where the license key is stored.                                                                                                                                                                                         |                                      |
| `rbac.create`                                  | Enable Role-based authentication                                                                                                                                                                                                                  | `true`                               |
| `image.repository`                             | The container to pull.                                                                                                                                                                                                                            | `newrelic/newrelic-fluentbit-output` |
| `image.pullPolicy`                             | The pull policy.                                                                                                                                                                                                                                  | `IfNotPresent`                       |
| `image.tag`                                    | The version of the container to pull.                                                                                                                                                                                                             | See value in [values.yaml]`          |
| `resources`                                    | Any resources you wish to assign to the pod.                                                                                                                                                                                                      | See Resources below                  |
| `priorityClassName`                            | Scheduling priority of the pod                                                                                                                                                                                                                    | `nil`                                |
| `nodeSelector`                                 | Node label to use for scheduling                                                                                                                                                                                                                  | `nil`                                |
| `tolerations`                                  | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                      | See Tolerations below                |
| `updateStrategy`                               | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)                                                                                                                                                                                       | `RollingUpdate`                      |
| `serviveAccount.create`                        | If true, a service account would be created and assigned to the deployment                                                                                                                                                                        | true                                 |
| `serviveAccount.name`                          | The service account to assign to the deployment. If `serviveAccount.create` is true then this name will be used when creating the service account                                                                                                 |                                      |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key)                                                                                                                                                                                 | false                                  |


## Uninstall the Kubernetes plugin

### Uninstall via Helm (recommended)
Run the following command:
```sh
helm uninstall newrelic-logging
```

## Resources

The default set of resources assigned to the pods is shown below:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 128Mi
  requests:
    cpu: 250m
    memory: 64Mi
```

## Tolerations

The default set of tolerations assigned to our daemonset is shown below:

```yaml
tolerations:
  - operator: "Exists"
    effect: "NoSchedule"
  - operator: "Exists"
    effect: "NoExecute"
  - operator: "Exists"
    effect: "PreferNoSchedule"
  - key: "node.kubernetes.io/os"
    operator: "Equal"
    value: "windows"
    effect: "NoSchedule"
```

## Troubleshooting

Set fluent-bit to debug:

> `--set fluentBit.logLevel=debug` to any of the helm install commands above.


### Mitigate unstable network on Windows pods

Windows pods often lack working DNS immediately after boot ([#78479](https://github.com/kubernetes/kubernetes/issues/78479)). To mitigate this issue, `filter_kubernetes` provides a built-in mechanism to wait until the network starts up:

 * `DNS_Retries` - Retries N times until the network start working (6)
 * `DNS_Wait_Time` - Lookup interval between network status checks (30)

By default, Fluent Bit waits for 3 minutes (30 seconds x 6 times). If it's not enough for you, tweak the configuration as follows.

```
[filter]
    Name kubernetes
    ...
    DNS_Retries 10
    DNS_Wait_Time 30
```
### Known Limitations

Config changes required on EKS due to how AMI Images are configured. Kubelet logs are written to Cloudwatch log sinks so one needs to remove the 

```C:\k\kubelet.err.log hostMounts.```
