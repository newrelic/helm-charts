# serverless-job-manager

## Chart Details

This chart deploys the New Relic Serverless Job Manager for Kubernetes-based Serverless Location Deployment Configuration. It orchestrates serverless workloads using K8s native features for deployment, scaling, and observability, following the architecture described in the CDD: Job Manager Service With Sidecar Using K8's.

**Note:** This chart does NOT include ping-runtime. It only supports node-api-runtime and node-browser-runtime for serverless job execution.

## Architecture Overview

The Serverless Job Manager implements a secure, scalable platform for executing serverless jobs across Kubernetes environments:

- **Job Manager (JM)**: Acts as the primary orchestrator, fetching jobs from the Compute Broker Service and dynamically provisioning K8s resources
- **Sidecar Container**: Deployed with runtime workloads as the egress proxy and communication agent for secure result reporting
- **Horizontal Pod Autoscaler**: Scales JM replicas based on queue depth metrics from the Broker Service
- **Service Account & RBAC**: Provides necessary permissions for K8s resource orchestration and coordination

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serverless.locationKey` | *Required if serverless.locationKeySecretName not set* - The authentication key associated with your Serverless Location | |
| `serverless.locationKeySecretName` | *Required if serverless.locationKey not set* - Name of the Kubernetes Secret containing the key `locationKey` | |
| `global.internalApiKey` | *Required if global.internalApiKeySecretName is not set* - Key that restricts communication between serverless-job-manager and runtimes | |
| `global.internalApiKeySecretName` | *Required if global.internalApiKey is not set* - Name of the Kubernetes Secret containing `internalApiKey` | |
| `global.hostnameOverride` | Overrides the default hostname used for the serverless-job-manager Service | `serverless-job-manager` |
| `global.checkTimeout` | Maximum number of seconds that jobs are allowed to run (1-900 seconds) | `180` |
| `global.persistence.existingClaimName` | Name of existing PersistentVolumeClaim for mounting volumes | |
| `global.persistence.existingVolumeName` | Name of existing PersistentVolume (Helm will generate a PVC) | |
| `global.persistence.storageClass` | StorageClass name for the generated PersistentVolumeClaim | Default StorageClass |
| `global.persistence.size` | Size of the volume for the generated PersistentVolumeClaim | `2Gi` |
| `global.customNodeModules.customNodeModulesPath` | Path on PersistentVolume to package.json file for custom node modules | |
| `imagePullSecrets` | Secret object for pulling images from container registry | |
| `nameOverride` | Replaces the chart name in Chart.yaml | |
| `fullnameOverride` | Name override for the installation | |
| `appVersionOverride` | Release version override | |
| `serverless.logLevel` | Log level for serverless-job-manager (`ALL`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `OFF`, `TRACE`) | `INFO` |
| `serverless.brokerApiEndpoint` | Compute Broker API endpoint. US: `https://compute-broker.nr-data.net`, EU: `https://compute-broker.eu01.nr-data.net/` | `https://compute-broker.nr-data.net` |
| `serverless.vsePassphrase` | Passphrase for verified script execution | |
| `serverless.vsePassphraseSecretName` | Kubernetes Secret name containing `vsePassphrase` key | |
| `serverless.apiProxyHost` | Proxy host for broker communication | |
| `serverless.apiProxyPort` | Proxy port for broker communication | |
| `serverless.brokerApiProxySelfSignedCert` | Accept self-signed certs (true, 1, or yes) | |
| `serverless.brokerApiProxyUsername` | Proxy authentication username | |
| `serverless.brokerApiProxyPw` | Proxy authentication password | |
| `serverless.jvmOpts` | JVM command line options | |
| `serverless.networkHealthCheckDisabled` | Bypass public internet health check | `false` |
| `serverless.userDefinedVariables.userDefinedJson` | JSON string of user-defined variables | |
| `serverless.userDefinedVariables.userDefinedFile` | Path to local JSON file with user-defined variables | |
| `serverless.userDefinedVariables.userDefinedPath` | Path on PersistentVolume to user_defined_variables.json | |
| `serverless.hpa.enabled` | Enable Horizontal Pod Autoscaler | `true` |
| `serverless.hpa.minReplicas` | Minimum number of JM replicas | `1` |
| `serverless.hpa.maxReplicas` | Maximum number of JM replicas | `10` |
| `serverless.hpa.customMetrics.queueDepthMetricName` | Custom metric name from Broker Service | `serverless_queue_depth` |
| `serverless.hpa.customMetrics.targetValue` | Target queue depth per replica | `100` |
| `serverless.sidecar.enabled` | Enable sidecar container in runtime pods | `true` |
| `serverless.sidecar.image.repository` | Sidecar container image | `newrelic/serverless-sidecar` |
| `serverless.sidecar.image.tag` | Sidecar image tag | `latest` |
| `serverless.sidecar.resources` | Sidecar resource requests and limits | See [Resources](#Resources) |
| `image.repository` | Job Manager container image | `newrelic/serverless-job-manager` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `resources` | Resource requests and limits for Job Manager | See [Resources](#Resources) |
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name to use | |
| `serviceAccount.annotations` | ServiceAccount annotations | |
| `rbac.create` | Create RBAC resources (Role, RoleBinding) | `true` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `podAnnotations` | Annotations for the serverless-job-manager pod | |
| `podSecurityContext` | Security context for the pod | |
| `securityContext` | Security context for containers | |
| `labels` | Labels for all serverless-job-manager resources | |
| `annotations` | Annotations for the pod | |
| `nodeSelector` | Node labels for pod assignment | |
| `tolerations` | Node taints to tolerate | |
| `affinity` | Pod affinity | |
| `node-api-runtime.enabled` | Enable node-api-runtime | `true` |
| `node-browser-runtime.enabled` | Enable node-browser-runtime | `true` |

### Node API Runtime Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `node-api-runtime.parallelism` | Number of jobs to execute in parallel | `1` |
| `node-api-runtime.completions` | Number of jobs expected per minute (× parallelism) | `6` |
| `node-api-runtime.imagePullSecrets` | Image pull secrets | |
| `node-api-runtime.image.repository` | Container image | `newrelic/synthetics-node-api-runtime` |
| `node-api-runtime.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `node-api-runtime.resources` | Resource requests and limits | See [Resources](#Resources) |

### Node Browser Runtime Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `node-browser-runtime.parallelism` | Number of jobs to execute in parallel | `1` |
| `node-browser-runtime.completions` | Number of jobs expected per minute (× parallelism) | `6` |
| `node-browser-runtime.imagePullSecrets` | Image pull secrets | |
| `node-browser-runtime.image.repository` | Container image | `newrelic/synthetics-node-browser-runtime` |
| `node-browser-runtime.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `node-browser-runtime.resources` | Resource requests and limits | See [Resources](#Resources) |

## Example

Make sure you have [added the New Relic chart repository.](../../README.md#installing-charts)

Then, to install this chart, run the following command:

```sh
helm install newrelic/serverless-job-manager \
--set serverless.locationKey=<enter_serverless_location_key> \
--set global.internalApiKey=<enter_internal_api_key>
```

To install the runtime charts, pass in the values.yaml for both serverless-job-manager and runtime charts:

```sh
helm install [chart-name] charts/serverless-job-manager/charts/node-api-runtime \
--values charts/serverless-job-manager/values.yaml \
--values charts/serverless-job-manager/charts/node-api-runtime/values.yaml
```

## Resources

The default set of resources assigned to **serverless-job-manager**:

```yaml
resources:
  requests:
    cpu: 0.5
    memory: 800Mi
  limits:
    cpu: 0.75
    memory: 1.6Gi
```

The default set of resources assigned to **sidecar container**:

```yaml
resources:
  requests:
    cpu: 0.1
    memory: 128Mi
  limits:
    cpu: 0.2
    memory: 256Mi
```

The default set of resources assigned to **node-api runtime**:

```yaml
resources:
  requests:
    cpu: 0.5
    memory: 1250Mi
  limits:
    cpu: 0.75
    memory: 2500Mi
```

The default set of resources assigned to **node-browser runtime**:

```yaml
resources:
  requests:
    cpu: 1
    memory: 2000Mi
  limits:
    cpu: 1.5
    memory: 3000Mi
```

## Architecture Details

### Job Manager Components

1. **Deployment**: Orchestrates the Job Manager pods
2. **Service (ClusterIP)**: Provides stable DNS endpoint for result reporting from runtime pods
3. **ServiceAccount**: Dedicated identity for K8s API interactions
4. **Role & RoleBinding**: Grants permissions for:
   - CRUD operations on Jobs, Pods, Services, Deployments, HPAs
   - K8s Leases for distributed coordination
5. **HorizontalPodAutoscaler**: Scales based on Broker queue depth metrics

### Security Features

- **Service Account Isolation**: Dedicated ServiceAccount with minimal required permissions
- **RBAC**: Fine-grained access control for K8s resources
- **Sidecar Egress Control**: All external traffic routed through sidecar proxy
- **Network Policies**: Optional NetworkPolicy for additional isolation
- **Result Authentication**: Cryptographic signing of job results to prevent spoofing

### Scaling Strategy

- **Job Manager HPA**: Proactive scaling based on Broker queue depth (custom external metrics)
- **Runtime Pods**: Ephemeral K8s Jobs created on-demand
- **K8s Scheduler**: Handles pod placement and node scaling triggers
- **Cluster Autoscaler**: Provisions new nodes when resources are exhausted

## Differences from synthetics-job-manager

This chart is based on synthetics-job-manager but adapted for serverless deployments:

1. **No ping-runtime**: Excludes the ping-runtime sub-chart and all related configurations
2. **Broker Integration**: Uses Compute Broker Service instead of Synthetics Horde API
3. **Enhanced RBAC**: Includes ServiceAccount, Role, and RoleBinding for K8s orchestration
4. **HPA Support**: Built-in Horizontal Pod Autoscaler with custom metrics
5. **Sidecar Configuration**: Explicit sidecar container configuration for runtime pods
6. **Network Policies**: Optional NetworkPolicy support for enhanced isolation
7. **Renamed Parameters**: Uses `serverless.*` instead of `synthetics.*` for configuration

## Support

For issues and questions, please refer to the [New Relic Helm Charts repository](https://github.com/newrelic/helm-charts).