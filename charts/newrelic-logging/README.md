# newrelic-logging

## Chart Details

New Relic offers a [Fluent Bit](https://fluentbit.io/) output [plugin](https://github.com/newrelic/newrelic-fluent-bit-output) to easily forward your logs to [New Relic Logs](https://docs.newrelic.com/docs/logs/new-relic-logs/get-started/introduction-new-relic-logs). This plugin is also provided in a standalone Docker image that can be installed in a [Kubernetes](https://kubernetes.io/) cluster in the form of a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), which we refer as the Kubernetes plugin.

This document explains how to install it in your cluster, either using a [Helm](https://helm.sh/) chart (recommended), or manually by applying Kubernetes manifests.

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

> By default, tailing is set to `/var/log/containers/*.log`. To change this setting, provide your preferred path by adding `--set fluentBit.path=DESIRED_PATH` to any of the helm install commands above.

### Install the Kubernetes manifests manually

 1. Download the following 3 manifest files into your current working directory:
     ```sh
    curl https://raw.githubusercontent.com/newrelic/helm-charts/master/charts/newrelic-logging/k8s/fluent-conf.yml > fluent-conf.yml
    curl https://raw.githubusercontent.com/newrelic/helm-charts/master/charts/newrelic-logging/k8s/new-relic-fluent-plugin.yml > new-relic-fluent-plugin.yml
    curl https://raw.githubusercontent.com/newrelic/helm-charts/master/charts/newrelic-logging/k8s/rbac.yml > rbac.yml 
     ```
    
 2. In the downloaded `new-relic-fluent-plugin.yml` file, replace the placeholder value `LICENSE_KEY` with your [New Relic license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key).
    > For EU users, replace the ENDPOINT environment variable to https://log-api.eu.newrelic.com/log/v1.

 3. Once the License key has been added, run the following command in your terminal or command-line interface:
     ```sh
    kubectl apply -f .
     ```

 4. [OPTIONAL] You can configure how the plugin parses the data by editing the [parsers.conf section in the fluent-conf.yml file](./k8s/fluent-conf.yml#L55-L70). For more information, see Fluent Bit's documentation on [Parsers configuration](https://docs.fluentbit.io/manual/pipeline/parsers).
    > By default, tailing is set to `/var/log/containers/*.log`. To change this setting, replace the default path with your preferred path in the [new-relic-fluent-plugin.yml file](./k8s/new-relic-fluent-plugin.yml#L40).

## Configuration

See [values.yaml](values.yaml) for the default values

| Parameter                                      | Description                                                                                                                                                                                                                                       | Default                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `global.licenseKey` - `licenseKey`             | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be the preferred configuration option if both `licenseKey` and `customSecret*` values are specified. |                                      |
| `global.customSecretName` - `customSecretName` | Name of the Secret object where the license key is stored                                                                                                                                                                                         |                                      |
| `global.customSecretLicenseKey` - `customSecretLicenseKey`   | Key in the Secret object where the license key is stored.                                                                                                                                                                                         |                                      |
| `rbac.create`                                  | Enable Role-based authentication                                                                                                                                                                                                                  | `true`                               |
| `rbac.pspEnabled`              | Enable pod security policy support                                                                                                                                                                                                                | `false`                         | 
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

### Uninstall the Kubernetes manifests manually
Run the following command in the directory where you downloaded the Kubernetes manifests during the installation procedure:
```sh
kubectl delete -f .
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
```

## Troubleshooting

### I am receiving "Invalid pattern for given tag"
If you are receiving the following error:
```sh
[ warn] [filter_kube] invalid pattern for given tag
```
In the [new-relic-fluent-plugin.yml file](./k8s/new-relic-fluent-plugin.yml#L40), replace the default code `/var/log/containers/*.log` with the following:
```sh
/var/log/containers/*.{log}
```