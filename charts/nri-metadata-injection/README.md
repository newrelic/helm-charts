# newrelic-metadata-injection

## Chart Details

This chart will deploy the [New Relic Infrastructure metadata injection webhook][1].

## Configuration

| Parameter                     | Description                                                  | Default                    |
| ----------------------------- | ------------------------------------------------------------ | -------------------------- |
| `cluster`                     | The cluster name for the Kubernetes cluster.                 |                            |
| `injectOnlyLabeledNamespaces` | Limit the injection of metadata only to specific namespaces that match the label `newrelic-metadata-injection: enabled`. | false |
| `image.repository`            | The container to pull.                                       | `newrelic/k8s-metadata-injection`   |
| `image.pullPolicy`            | The pull policy.                                             | `IfNotPresent`                      |
| `image.tag`                   | The version of the container to pull.                        | `1.4.0`                             |
| `imageJob.repository`         | The job container to pull.                                   | `newrelic/k8s-webhook-cert-manager` |
| `imageJob.pullPolicy`         | The job pull policy.                                         | `IfNotPresent`                      |
| `image.pullSecrets`           | Image pull secrets.                                          | `nil`                               |
| `imageJob.tag`                | The job version of the container to pull.                    | `1.4.0`                             |
| `imageJob.volumeMounts`       | Additional Volume mounts for Cert Job                        | `[]`                                |
| `imageJob.volumes`            | Additional Volumes for Cert Job                              | `[]`                                |
| `replicas`                    | Number of replicas in the deployment                         | `1`                                 |
| `resources`                   | Any resources you wish to assign to the pod.                 | See Resources below                 |
| `serviveAccount.create`       | If true a service account would be created and assigned for the webhook and the job. | `true` |
| `serviveAccount.name`         | The service account to assign to the webhook and the job. If `serviveAccount.create` is true then this name will be used when creating the service account; if this value is not set or it evaluates to false, then when creating the account the returned value from the template `nr-metadata-injection.fullname` will be used as name. | |
| `customTLSCertificate`        | Use custom TLS certificate. Setting this options means that you will have to do some post install work as detailed in the *Manage custom certificates* section of the [official docs][1]. | `false` |
| `certManager.enabled`         | Use cert-manager to provision the MutatingWebhookConfiguration certs. | `false` |
| `podSecurityContext.enabled`  | Enable custom Pod Security Context                           | `false`                             |
| `podSecurityContext.fsGroup`  | fsGroup for Pod Security Context                             | `1001`                              |
| `podSecurityContext.runAsUser`| runAsUser UID for Pod Security Context                       | `1001`                              |
| `podSecurityContext.runAsGroup`| runAsUser GID for Pod Security Context                      | `1001`                              |
| `podAnnotations`              | If you wish to provide additional annotations to apply to the pod(s), specify them here.      |                                 |
| `priorityClassName`           | Scheduling priority of the pod                               | `nil`                               |
| `nodeSelector`                | Node label to use for scheduling                             | `{}`                                |
| `timeoutSeconds`              | Seconds to wait for a webhook to respond. The timeout value must be between 1 and 30 seconds| `10`                             |
| `tolerations`                 | List of node taints to tolerate (requires Kubernetes >= 1.6) | `[]`                                |
| `affinity`                    | Node affinity to use for scheduling                          | `{}`                                |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/newrelic-mutation-webhook --set cluster=my_cluster_name
```

## Resources

The default set of resources assigned to the pods is shown below:

    resources:
      limits:
        memory: 80M
      requests:
        cpu: 100m
        memory: 30M

[1]: https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-your-applications/link-your-applications-kubernetes#configure-injection
[2]: https://cert-manager.io/
