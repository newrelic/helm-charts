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

#### Proxy support

Since Fluent Bit Kubernetes plugin is using [newrelic-fluent-bit-output](https://github.com/newrelic/newrelic-fluent-bit-output) we can configure the [proxy support](https://github.com/newrelic/newrelic-fluent-bit-output#proxy-support) in order to set up the proxy configuration.

##### As environment variables

 1. Complete the step 1 in [Install the Kubernetes manifests manually](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging#install-the-kubernetes-manifests-manually)
 2. Modify the `new-relic-fluent-plugin.yml` file. Add `HTTP_PROXY` or `HTTPS_PROXY` as environment variables:
     ```yaml
        ...
         containers:
           - name: newrelic-logging
             env:
               - name: ENDPOINT
                 value : "https://log-api.newrelic.com/log/v1"
               - name: HTTP_PROXY
                 value : "http://http-proxy-hostname:PORT" # We must always specify the protocol (either http:// or https://)
        ...
     ```
 3. Continue to the next steps

 ##### Custom proxy

 If you want to set up a custom proxy (eg. using self-signed certificate):

  1. Complete the step 1 in [Install the Kubernetes manifests manually](https://github.com/newrelic/helm-charts/tree/master/charts/newrelic-logging#install-the-kubernetes-manifests-manually)
  2. Modify the `fluent-conf.yml` and define in the ConfigMap a `caBundle.pem` file with the self-signed certificate:
      ```yaml
           ...
            [OUTPUT]
                Name  newrelic
                Match *
                licenseKey ${LICENSE_KEY}
                endpoint ${ENDPOINT}
                proxy https://https-proxy-hostname:PORT
                caBundleFile ${CA_BUNDLE_FILE}

            caBundle.pem: |
                -----BEGIN CERTIFICATE-----
                MIIB+zCCAWSgAwIBAgIQTiHC/d/NhpHFptZCIoCbNzANBgkrhtiG9w0BAQsFADAS
                MBAwDgYDVQQKEwdBY23lIENvMCAXDTcwMDEwMTYwMDBwMFoYDzIwODQwMTI5MTYw
                ...
                ekFR5glcUVWoFru+EMj4WKmbRATUe3cYQRCThzO2hQ==
                -----END CERTIFICATE-----
           ...
      ```
  3. Modify `new-relic-fluent-plugin.yml` and define the `CA_BUNDLE_FILE` environment variable pointing to the created ConfigMap file:
       ```yaml
          ...
           containers:
             - name: newrelic-logging
               env:
                 - name: ENDPOINT
                   value : "https://log-api.newrelic.com/log/v1"
                 - name: CA_BUNDLE_FILE
                   value: /fluent-bit/etc/caBundle.pem
          ...
       ```
  4. Continue to the next steps

## Configuration

See [values.yaml](values.yaml) for the default values

| Parameter                                                  | Description                                                                                                                                                                                                                                                                  | Default                                                                         |
|------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                                                 |                                                                                 |
| `global.licenseKey` - `licenseKey`                         | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be the preferred configuration option if both `licenseKey` and `customSecret*` values are specified.                            |                                                                                 |
| `global.customSecretName` - `customSecretName`             | Name of the Secret object where the license key is stored                                                                                                                                                                                                                    |                                                                                 |
| `global.customSecretLicenseKey` - `customSecretLicenseKey` | Key in the Secret object where the license key is stored.                                                                                                                                                                                                                    |                                                                                 |
| `global.fargate`                                           | Must be set to `true` when deploying in an EKS Fargate environment. Prevents DaemonSet pods from being scheduled in Fargate nodes.                                                                                                                                           |                                                                                 |
| `global.lowDataMode` - `lowDataMode`                       | If `true`, send minimal attributes on Kubernetes logs. Labels and annotations are not sent when lowDataMode is enabled.                                                                                                                                                      | `false`                                                                         |
| `rbac.create`                                              | Enable Role-based authentication                                                                                                                                                                                                                                             | `true`                                                                          |
| `rbac.pspEnabled`                                          | Enable pod security policy support                                                                                                                                                                                                                                           | `false`                                                                         |
| `image.repository`                                         | The container to pull.                                                                                                                                                                                                                                                       | `newrelic/newrelic-fluentbit-output`                                            |
| `image.pullPolicy`                                         | The pull policy.                                                                                                                                                                                                                                                             | `IfNotPresent`                                                                  |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                                                                                          | `nil`                                                                           |
| `image.tag`                                                | The version of the container to pull.                                                                                                                                                                                                                                        | See value in [values.yaml]`                                                     |
| `exposedPorts`                                             | Any ports you wish to expose from the pod.  Ex. 2020 for metrics                                                                                                                                                                                                             | `[]`                                                                            |
| `resources`                                                | Any resources you wish to assign to the pod.                                                                                                                                                                                                                                 | See Resources below                                                             |
| `priorityClassName`                                        | Scheduling priority of the pod                                                                                                                                                                                                                                               | `nil`                                                                           |
| `nodeSelector`                                             | Node label to use for scheduling on Linux nodes                                                                                                                                                                                                                              | `{ kubernetes.io/os: linux }`                                                   |
| `windowsNodeSelector`                                      | Node label to use for scheduling on Windows nodes                                                                                                                                                                                                                            | `{ kubernetes.io/os: windows, node.kubernetes.io/windows-build: BUILD_NUMBER }` |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                                                 | See Tolerations below                                                           |
| `updateStrategy`                                           | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)                                                                                                                                                                                                                  | `RollingUpdate`                                                                 |
| `extraVolumeMounts`                                        | Additional DaemonSet volume mounts	                                                                                                                                                                                                                     | `[]`                                                                 |
| `extraVolumes`                                             | Additional DaemonSet volumes 	                                                                                                                                                   | `[]`                                                                 |
| `initContainers`                                             | [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that will be executed before the actual container in charge of shipping logs to New Relic is initialized. Use this if you are using a custom Fluent Bit configuration that requires downloading certain files inside the volumes being accessed by the log-shipping pod.	                                                                                                                                                   | `[]`                                                                 |
| `windows.initContainers`                                             | [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that will be executed before the actual container in charge of shipping logs to New Relic is initialized. Use this if you are using a custom Fluent Bit configuration that requires downloading certain files inside the volumes being accessed by the log-shipping pod.	                                                                                                                                                   | `[]`                                                                 |
| `serviceAccount.create`                                    | If true, a service account would be created and assigned to the deployment                                                                                                                                                                                                   | `true`                                                                          |
| `serviceAccount.name`                                      | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                                                                                            |                                                                                 |
| `serviceAccount.annotations`                               | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                                                                                                     |                                                                                 |
| `global.nrStaging` - `nrStaging`                           | Send data to staging (requires a staging license key)                                                                                                                                                                                                                        | `false`                                                                         |
| `fluentBit.criEnabled`                                     | We assume that `kubelet`directly communicates with the Docker container engine. Set this to `true` if your K8s installation uses [CRI](https://kubernetes.io/blog/2016/12/container-runtime-interface-cri-in-kubernetes/) instead, in order to get the logs properly parsed. | `false`                                                                         |
| `fluentBit.k8sBufferSize`                                  | Set the buffer size for HTTP client when reading responses from Kubernetes API server. A value of 0 results in no limit and the buffer will expand as needed.                                                                                                                | `32k`                                                                           |
| `fluentBit.k8sLoggingExclude`                              | Set to "On" to allow excluding pods by adding the annotation `fluentbit.io/exclude: "true"` to pods you wish to exclude.                                                                                                                                                     | `Off`                                                                           |
| `fluentBit.additionalEnvVariables`                         | Additional environmental variables for fluentbit pods                                                                                                                                                                                                                        | `[]]`                                                                           |
| `daemonSet.annotations`                                    | The annotations to add to the `DaemonSet`.                                                                                                                                                                                                                                   |                                                                                 |
| `podAnnotations`                                           | The annotations to add to the `DaemonSet` created `Pod`s.                                                                                                                                                                                                                    |                                                                                 |
| `enableLinux`                                              | Enable log collection from Linux containers. This is the default behavior. In case you are only interested of collecting logs from Windows containers, set this to `false`.                                                                                                  | `true`                                                                          |
| `enableWindows`                                            | Enable log collection from Windows containers. Please refer to the [Windows support](#windows-support) section for more details.                                                                                                                                             | `false`                                                                         |
| `fluentBit.config.service`                                 | Contains fluent-bit.conf Service config                                                                                                                                                                                                                                      |                                                                                 |
| `fluentBit.config.inputs`                                  | Contains fluent-bit.conf Inputs config                                                                                                                                                                                                                                       |                                                                                 |
| `fluentBit.config.extraInputs`                             | Contains extra fluent-bit.conf Inputs config                                                                                                                                                                                                                                  |                                                                                 |
| `fluentBit.config.filters`                                 | Contains fluent-bit.conf Filters config                                                                                                                                                                                                                                      |                                                                                 |
| `fluentBit.config.extraFilters`                            | Contains extra fluent-bit.conf Filters config                                                                                                                                                                                                                                |                                                                                 |
| `fluentBit.config.lowDataModeFilters`                      | Contains fluent-bit.conf Filters config for lowDataMode                                                                                                                                                                                                                      |                                                                                 |
| `fluentBit.config.outputs`                                 | Contains fluent-bit.conf Outputs config                                                                                                                                                                                                                                      |                                                                                 |
| `fluentBit.config.extraOutputs`                            | Contains extra fluent-bit.conf Outputs config                                                                                                                                                                                                                                |                                                                                 |
| `fluentBit.config.parsers`                                 | Contains parsers.conf Parsers config                                                                                                                                                                                                                                         |                                                                                 |
| `fluentBit.retryLimit`                                     | Amount of times to retry sending a given batch of logs to New Relic. This prevents data loss if there is a temporary network disruption, if a request to the Logs API is lost or when receiving a recoverable HTTP response. Set it to "False" for unlimited retries.        | 5                                                                               |


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


## Windows support

Since version `1.7.0`, this Helm chart supports shipping logs from Windows containers. To this end, you need to set the `enableWindows` configuration parameter to `true`.

Windows containers have some constraints regarding Linux containers. The main one being that they can only be executed on _hosts_ using the exact same Windows version and build number. On the other hand, Kubernetes nodes only supports the Windows versions listed [here](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/#windows-os-version-support).

This Helm chart deploys one `DaemonSet` for each of the Windows versions it supports, while ensuring that only containers matching the host operating system will be deployed in each host.

This Helm chart currently supports the following Windows versions:
-  Windows Server LTSC 2019, build 10.0.17763
-  Windows Server LTSC 2022, build 10.0.20348

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
