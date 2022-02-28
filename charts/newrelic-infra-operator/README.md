# newrelic-infra-operator

## Chart Details

This chart will deploy the [New Relic Infrastructure Operator][1], which injects the New Relic Infrastructure solution
as a sidecar to specific pods.
This is typically used in environments where DaemonSets are not available, such as EKS Fargate.

## Configuration


| Parameter                                                                       | Description                                                                                                                                                                                                                                                                                                                                 | Default                                                                                              |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `global.cluster` - `cluster`                                                    | The cluster name for the Kubernetes cluster.                                                                                                                                                                                                                                                                                                |                                                                                                      |
| `global.licenseKey` - `licenseKey`                                              | The [license key](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/license-key) for your New Relic Account. This will be preferred configuration option if both `licenseKey` and `customSecret` are specified.                                                                                                       |                                                                                                      |
| `global.fargate` - `fargate`                                                    | Must be set to `true` when deploying in an EKS Fargate environment. Adds the default policies and customAttributes to inject on fargate                                                                                                                                                                                                     |                                                                                                      |
| `image.repository`                                                              | The container to pull.                                                                                                                                                                                                                                                                                                                      | `newrelic/newrelic-infra-operator`                                                                   |
| `image.pullPolicy`                                                              | The pull policy.                                                                                                                                                                                                                                                                                                                            | `IfNotPresent`                                                                                       |
| `image.tag`                                                                     | The version of the image to pull.                                                                                                                                                                                                                                                                                                           | `appVersion`                                                                                         |
| `image.pullSecrets`                                                             | The image pull secrets.                                                                                                                                                                                                                                                                                                                     | `nil`                                                                                                |
| `admissionWebhooksPatchJob.image.repository`                                    | The job container to pull.                                                                                                                                                                                                                                                                                                                  | `k8s.gcr.io/ingress-nginx/kube-webhook-certgen`                                                                          |
| `admissionWebhooksPatchJob.image.pullPolicy`                                    | The job pull policy.                                                                                                                                                                                                                                                                                                                        | `IfNotPresent`                                                                                       |
| `admissionWebhooksPatchJob.image.pullSecrets`                                   | Image pull secrets.                                                                                                                                                                                                                                                                                                                         | `nil`                                                                                       |
| `admissionWebhooksPatchJob.image.tag`                                           | The job version of the container to pull.                                                                                                                                                                                                                                                                                                   | `v1.1.1`                                                                                              |
| `admissionWebhooksPatchJob.volumeMounts`                                        | Additional Volume mounts for Cert Job.                                                                                                                                                                                                                                                                                                      | `[]`                                                                                                 |
| `admissionWebhooksPatchJob.volumes`                                             | Additional Volumes for Cert Job.                                                                                                                                                                                                                                                                                                            | `[]`                                                                                                 |
| `replicas`                                                                      | Number of replicas in the deployment.                                                                                                                                                                                                                                                                                                       | `1`                                                                                                  |
| `resources`                                                                     | Resources you wish to assign to the pod.                                                                                                                                                                                                                                                                                                    | See Resources below                                                                                  |
| `serviceAccount.create`                                                         | If true a service account would be created and assigned for the webhook and the job.                                                                                                                                                                                                                                                        | `true`                                                                                               |
| `serviceAccount.name`                                                           | The service account to assign to the webhook and the job. If `serviceAccount.create` is true then this name will be used when creating the service account; if this value is not set or it evaluates to false, then when creating the account the returned value from the template `newrelic-infra-operator.fullname` will be used as name. |                                                                                                      |
| `certManager.enabled`                                                           | Use cert-manager to provision the MutatingWebhookConfiguration certs.                                                                                                                                                                                                                                                                       | `false`                                                                                              |
| `podSecurityContext.enabled`                                                    | Enable custom Pod Security Context.                                                                                                                                                                                                                                                                                                         | `false`                                                                                              |
| `podSecurityContext.fsGroup`                                                    | fsGroup for Pod Security Context.                                                                                                                                                                                                                                                                                                           | `1001`                                                                                               |
| `podSecurityContext.runAsUser`                                                  | runAsUser UID for Pod Security Context.                                                                                                                                                                                                                                                                                                     | `1001`                                                                                               |
| `podSecurityContext.runAsGroup`                                                 | runAsGroup GID for Pod Security Context.                                                                                                                                                                                                                                                                                                    | `1001`                                                                                               |
| `podAnnotations`                                                                | If you wish to provide additional annotations to apply to the pod(s), specify them here.                                                                                                                                                                                                                                                    |                                                                                                      |
| `priorityClassName`                                                             | Scheduling priority of the pod.                                                                                                                                                                                                                                                                                                             | `nil`                                                                                                |
| `nodeSelector`                                                                  | Node label to use for scheduling.                                                                                                                                                                                                                                                                                                           | `{}`                                                                                                 |
| `timeoutSeconds`                                                                | Seconds to wait for a webhook to respond. The timeout value must be between 1 and 30 seconds.                                                                                                                                                                                                                                               | `30`                                                                                                 |
| `tolerations`                                                                   | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                                                                                                                                                                | `[]`                                                                                                 |
| `affinity`                                                                      | Node affinity to use for scheduling.                                                                                                                                                                                                                                                                                                        | `{}`                                                                                                 |
| `config.ignoreMutationErrors`                                                   | If true it instruments the operator to ignore injection error instead of failing.                                                                                                                                                                                                                                                           | `true`                                                                                               |
| `config.infraAgentInjection.policies[]`                                         | All policies are ORed, if one policy matches the sidecar is injected. Within a policy PodSelectors, NamespaceSelector and NamespaceName are ANDed, any of these, if not specified, is ignored.                                                                                                                                              | `[podSelector{matchExpressions[{key:"label.eks.amazonaws.com/fargate-profile",operator:"Exists"}]}]` |
| `config.infraAgentInjection.policies[].podSelector`                             | Selector on Pod Labels.                                                                                                                                                                                                                                                                                                                     |                                                                                                      |
| `config.infraAgentInjection.policies[].namespaceSelector`                       | Selector on Namespace labels.                                                                                                                                                                                                                                                                                                               |                                                                                                      |
| `config.infraAgentInjection.policies[].namespaceName`                           | If set only pods belonging to such namespace matches the policy.                                                                                                                                                                                                                                                                            |                                                                                                      |
| `config.infraAgentInjection.agentConfig.customAttributes[]`                     | CustomAttributes added to each sidecar                                                                                                                                                                                                                                                                                                      |                                                                                                      |
| `config.infraAgentInjection.agentConfig.customAttributes[].name`                | Name of custom attribute to include.                                                                                                                                                                                                                                                                                                        |                                                                                                      |
| `config.infraAgentInjection.agentConfig.customAttributes[].defaultValue`        | Default value for custom attribute to include.                                                                                                                                                                                                                                                                                              |                                                                                                      |
| `config.infraAgentInjection.agentConfig.customAttributes[].fromLabel`           | Label from which take the value of the custom attribute.                                                                                                                                                                                                                                                                                    |                                                                                                      |
| `config.infraAgentInjection.agentConfig.image.pullPolicy`                       | The sidecar image pull policy.                                                                                                                                                                                                                                                                                                              | `IfNotPresent`                                                                                       |
| `config.infraAgentInjection.agentConfig.image.repository`                       | The infrastructure agent repository for the sidecar container.                                                                                                                                                                                                                                                                              | `newrelic/infrastructure-k8s`                                                                        |
| `config.infraAgentInjection.agentConfig.image.tag`                              | The infrastructure agent image tag for the sidecar container.                                                                                                                                                                                                                                                                               | `2.8.2-unprivileged`                                                                                 |
| `config.infraAgentInjection.agentConfig.podSecurityContext.runAsUser`           | runAsUser UID for Pod Security Context.                                                                                                                                                                                                                                                                                                     |                                                                                                      |
| `config.infraAgentInjection.agentConfig.podSecurityContext.runAsGroup`          | runAsGroup UID for Pod Security Context.                                                                                                                                                                                                                                                                                                    |                                                                                                      |
| `config.infraAgentInjection.agentConfig.configSelectors[]`                      | ConfigSelectors is the way to configure resource requirements and extra envVars of the injected sidecar container. When mutating it will be applied the first configuration having the labelSelector matching with the mutating pod.                                                                                                        |                                                                                                      |
| `config.infraAgentInjection.agentConfig.configSelectors[].resourceRequirements` | ResourceRequirements to apply to the sidecar.                                                                                                                                                                                                                                                                                               |                                                                                                      |
| `config.infraAgentInjection.agentConfig.configSelectors[].extraEnvVars`         | ExtraEnvVars to pass to the injected sidecar.                                                                                                                                                                                                                                                                                               |                                                                                                      |
| `config.infraAgentInjection.agentConfig.configSelectors[].labelSelector`        | LabelSelector matching the labels of the mutating pods.                                                                                                                                                                                                                                                                                     |                                                                                                      |



## Example

Make sure you have [added the New Relic chart repository.](../../README.md#install)

Then, to install this chart, run the following command:

```sh
helm upgrade --install [release-name] newrelic/newrelic-infra-operator --set cluster=my_cluster_name --set licenseKey [your-license-key]
```

When installing on Fargate add as well `--set fargate=true`

## Configure in which pods the sidecar should be injected

Policies are available in order to configure in which pods the sidecar should be injected.
Each policy is evaluated independently and if at least one policy matches the operator will inject the sidecar.

Policies are composed by `namespaceSelector` checking the labels of the Pod namespace, `podSelector` checking
the labels of the Pod and `namespace` checking the namespace name. Each of those, if specified, are ANDed.

By default, the policies are configured in order to inject the sidecar in each pod belonging to a Fargate profile.

>Moreover, it is possible to add the label `infra-operator.newrelic.com/disable-injection` to Pods to exclude injection
for a single Pod that otherwise would be selected by the policies.

Please make sure to configure policies correctly to avoid injecting sidecar for pods running on EC2 nodes
already monitored by the infrastructure DaemonSet.

## Configure the sidecar with labelsSelectors

It is also possible to configure `resourceRequirements` and `extraEnvVars` based on the labels of the mutating Pod.

The current configuration increases the resource requirements for sidecar injected on `KSM` instances. Moreover,
injectes disable the `DISABLE_KUBE_STATE_METRICS` environment variable for Pods not running on `KSM` instances
to decrease the load on the API server.

## Resources

The default set of resources assigned to the newrelic-infra-operator pods is shown below:

```yaml
resources:
  limits:
    memory: 80M
  requests:
    cpu: 100m
    memory: 30M
```

The default set of resources assigned to the injected sidecar when the pod is **not** KSM is shown below:

```yaml
resources:
  limits:
    memory: 100M
    cpu: 200m
  requests:
    memory: 50M
    cpu: 100m
```

The default set of resources assigned to the injected sidecar when the pod is KSM is shown below:

```yaml
resources:
  limits:
    memory: 300M
    cpu: 300m
  requests:
    memory: 150M
    cpu: 150m
```

## Tolerations

No default set of tolerations are defined.
Please note that these tolerations are applied only to the operator and the certificate-related jobs themselves, and not to any pod or container injected by it.

[1]: https://github.com/newrelic/newrelic-infra-operator
[2]: https://cert-manager.io/
