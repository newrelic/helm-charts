# apm-php-agent

## Chart Details

This chart will deploy the New Relic's PHP agent APM through a deployment with a service exposed over the cluster.

## Configuration

| Parameter                                                  | Description                                                                                                                                                                                        | Default                                |
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| `global.cluster` - `cluster`                               | The cluster name for the Kubernetes cluster.                                                                                                                                                       |                                        |
| `agentPort`                                                | The port agent pods and the service will open.                                                                                                                                                     | `31339`                                |
| `image.repository`                                         | The newrelic php agent image name.                                                                                                                                                                 | `newrelic/php-daemon`                  |
| `image.tag`                                                | The newrelic php agent image tag.                                                                                                                                                                  | `9.15.0`                                |
| `image.pullSecrets`                                        | Image pull secrets.                                                                                                                                                                                | `nil`                                  |
| `replicas`                                                 | The desired replica count.                                                                                                                                                                         | `1`                                    |
| `resources`                                                | A yaml defining the resources for the events-router container.                                                                                                                                     | `{}`                                   |
| `serviceAccount.create`                                    | If true, a service account would be created and assigned to the deployment                                                                                                                         | `true`                                 |
| `serviceAccount.name`                                      | The service account to assign to the deployment. If `serviceAccount.create` is true then this name will be used when creating the service account                                                  |                                        |
| `serviceAccount.annotations`                               | The annotations to add to the service account if `serviceAccount.create` is set to true.                                                                                                           |                                        |
| `priorityClassName`                                        | Scheduling priority of the pod                                                                                                                                                                     | `nil`                                  |
| `nodeSelector`                                             | Node label to use for scheduling                                                                                                                                                                   | `{}`                                   |
| `tolerations`                                              | List of node taints to tolerate (requires Kubernetes >= 1.6)                                                                                                                                       | `[]`                                   |
| `affinity`                                                 | Node affinity to use for scheduling                                                                                                                                                                | `{}`                                   |

## Installation

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

To install this chart, run the following command:

```sh
helm install newrelic-php newrelic/apm-php-agent \
--set global.cluster=my-k8s-cluster
```

## Accessing the agent

### From the same namespace

Use `{helm_release_name}-{chart-name}` to access the agent from a pod in the same namespace.
From the installation example above the service should be reached through `newrelic-phpt-apm-php-agent`.

### From different namespaces

Use `{helm_release_name}-{chart-name}.{namespace}.svc.cluster.local` to access the agent from a pod in a different namespace.
From the installation example above the service should be reached through `newrelic-php-apm-php-agent.default.svc.cluster.local`.

You could also add an external service in your application project :
```
# newrelic-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: newrelic
  labels:
    ...
spec:
  type: ExternalName
  externalName: newrelic-php-agent-apm-php-agent.default.svc.cluster.local
  ports:
    - port: 31339
```

That way you could reach the agent through the service name `newrelic`.

## Uninstall

To remove this chart, run the following command:

```sh
helm uninstall newrelic-php
```
