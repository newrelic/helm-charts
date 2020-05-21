# newrelic-logging

## Chart Details

This chart will deploy the Fluentbit with the New Relic output plugin as a Daemonset.

## Configuration

See [values.yaml](values.yaml) for the default values

| Parameter  | Description   | Default  |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `global.licenseKey` - `licenseKey` | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be the preferred configuration option if both `licenseKey` and `customSecret*` values are specified. |  |
| `global.customSecretName` - `customSecretName` | Name of the Secret object where the license key is stored |  |
| `global.customSecretKey` - `customSecretKey`   | Key in the Secret object where the license key is stored. |  |
| `rbac.create`  | Enable Role-based authentication  | `true`   |
| `image.repository` | The container to pull.| `newrelic/newrelic-fluentbit-output` |
| `image.pullPolicy` | The pull policy.  | `IfNotPresent`   |
| `image.tag`| The version of the container to pull. | See value in [values.yaml]`  |
| `resources`| Any resources you wish to assign to the pod.  | See Resources below  |
| `priorityClassName`| Scheduling priority of the pod| `nil`|
| `nodeSelector` | Node label to use for scheduling  | `nil`|
| `tolerations`  | List of node taints to tolerate (requires Kubernetes >= 1.6)  | See Tolerations below|
| `updateStrategy`   | Strategy for DaemonSet updates (requires Kubernetes >= 1.6)   | `RollingUpdate`  |
| `serviveAccount.create`| If true, a service account would be created and assigned to the deployment| true |
| `serviveAccount.name`  | The service account to assign to the deployment. If `serviveAccount.create` is true then this name will be used when creating the service account |  |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-logging \
--set licenseKey=(your-license-key)
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
