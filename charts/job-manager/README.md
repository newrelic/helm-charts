# job-manager

## Chart Details

This chart deploys the New Relic Job Manager for **PUBLIC NR-hosted serverless locations**. It orchestrates workloads using K8s native features for deployment, scaling, and observability in a multi-tenant architecture.

**Important:** This chart is currently under development. Docker images referenced by this chart (`newrelic/job-manager:release-1`) are not yet published to Docker Hub. The chart passes linting and template validation tests but is excluded from CI installation tests until images are available.

**Scope:** This chart is designed for PUBLIC NR-hosted multi-tenant locations only. It is not intended for private customer-hosted locations.

**Note:** This chart does NOT include ping-runtime. Serverless architecture only supports node-api-runtime and node-browser-runtime for job execution.

## Architecture Overview

The Job Manager implements a secure, scalable platform for executing jobs across Kubernetes environments using native K8s primitives.

### Core Components

- **Job Manager Deployment**: Lightweight orchestrator pods that poll the orchestrator platform for pending jobs and dynamically provision K8s runtime resources (Jobs, Pods, ConfigMaps)
- **Job Manager Service (ClusterIP)**: Provides stable DNS endpoint for runtime pods to report job results back to any available job manager pod
- **Service Account & RBAC**: Grants job manager pods permissions to CRUD runtime resources and coordinate via K8s Leases
- **Horizontal Pod Autoscaler**: Auto-scales job manager replicas based on external metrics (pending job queue depth) from the orchestrator platform
- **K8s Leases**: Coordinates distributed activities between job manager pods:
  - **runtime-pruning-lease**: Coordinates deletion of unresponsive ephemeral jobs
- **NetworkPolicy**: Enforces security boundaries - job managers can reach K8s API and broker; runtime pods are isolated
- **Sidecar Container**: Deployed with runtime workloads as init container (restartPolicy: Always) acting as egress proxy and secure communication agent

### Workload Types

The job manager dynamically creates ephemeral workloads for job execution:

**Ephemeral Workloads** (One-time execution):
- K8s Job per execution
- Self-terminating upon job completion
- Sidecar handles egress and result reporting

## Configuration

### Location Configuration (NGEP-Aligned)

This chart uses a location configuration structure aligned with the NGEP ComputeLocation schema. All location settings are configurable but designed for PUBLIC NR-hosted multi-tenant deployments.

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `jobManager.location.key` | *Required if keySecretName not set* - Authentication key from NGEP for this location | Yes (one of) | |
| `jobManager.location.keySecretName` | *Required if key not set* - Name of Kubernetes Secret containing `locationKey` | Yes (one of) | |
| `jobManager.location.name` | Location name (e.g., "us-east-1-public", "eu-west-1-public") | Yes | |
| `jobManager.location.id` | NGEP entity ID for the ComputeLocation (recommended for production) | No | |
| `jobManager.location.description` | Human-readable description of the location | No | |
| `jobManager.location.tags.region` | AWS/Azure/GCP region (e.g., "us-east-1", "eu-west-1") | Yes | |
| `jobManager.location.tags.provider` | Cloud provider (e.g., "AWS", "Azure", "GCP") | No | |
| `jobManager.location.tags.environment` | Environment type (e.g., "production", "staging") | No | |
| `jobManager.location.associatedWorkloads` | List of workload types from NGEP (e.g., ["node-api-runtime_v1", "node-browser-runtime_v1"]) | Yes | See values.yaml |

### Multi-Tenant Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `jobManager.multiTenant.enabled` | Enable multi-tenant mode (always true for public locations) | `true` |
| `jobManager.multiTenant.accountValidation.enabled` | Enable account validation before job execution | `true` |
| `jobManager.multiTenant.accountValidation.validationEndpoint` | Account validation API endpoint | `https://auth.newrelic.com/validate` |
| `jobManager.multiTenant.capacity.maxConcurrentJobs` | Maximum concurrent jobs across all accounts | `1000` |
| `jobManager.multiTenant.capacity.perAccountQuota` | Default quota per account | `50` |
| `jobManager.multiTenant.isolation.networkPolicies` | Enable network policies for account isolation | `true` |
| `jobManager.multiTenant.isolation.resourceQuotas` | Enable resource quotas per account | `true` |

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.internalApiKey` | *Required if global.internalApiKeySecretName is not set* - Key that restricts communication between job-manager and runtimes | |
| `global.internalApiKeySecretName` | *Required if global.internalApiKey is not set* - Name of the Kubernetes Secret containing `internalApiKey` | |
| `global.hostnameOverride` | Overrides the default hostname used for the job-manager Service | `job-manager` |
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
| `jobManager.logLevel` | Log level for job-manager (`ALL`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `OFF`, `TRACE`) | `INFO` |
| `jobManager.brokerApiEndpoint` | Compute Broker API endpoint. US: `https://compute-broker.nr-data.net`, EU: `https://compute-broker.eu01.nr-data.net/` | `https://compute-broker.nr-data.net` |
| `jobManager.vsePassphrase` | Passphrase for verified script execution | |
| `jobManager.vsePassphraseSecretName` | Kubernetes Secret name containing `vsePassphrase` key | |
| `jobManager.apiProxyHost` | Proxy host for broker communication | |
| `jobManager.apiProxyPort` | Proxy port for broker communication | |
| `jobManager.brokerApiProxySelfSignedCert` | Accept self-signed certs (true, 1, or yes) | |
| `jobManager.brokerApiProxyUsername` | Proxy authentication username | |
| `jobManager.brokerApiProxyPw` | Proxy authentication password | |
| `jobManager.jvmOpts` | JVM command line options | |
| `jobManager.networkHealthCheckDisabled` | Bypass public internet health check | `false` |
| `jobManager.userDefinedVariables.userDefinedJson` | JSON string of user-defined variables | |
| `jobManager.userDefinedVariables.userDefinedFile` | Path to local JSON file with user-defined variables | |
| `jobManager.userDefinedVariables.userDefinedPath` | Path on PersistentVolume to user_defined_variables.json | |
| `jobManager.hpa.enabled` | Enable Horizontal Pod Autoscaler | `true` |
| `jobManager.hpa.minReplicas` | Minimum number of JM replicas | `1` |
| `jobManager.hpa.maxReplicas` | Maximum number of JM replicas | `10` |
| `jobManager.hpa.customMetrics.queueDepthMetricName` | Custom metric name from Broker Service | `serverless_queue_depth` |
| `jobManager.hpa.customMetrics.targetValue` | Target queue depth per replica | `100` |
| `jobManager.sidecar.enabled` | Enable sidecar container in runtime pods | `true` |
| `jobManager.sidecar.image.repository` | Sidecar container image | `newrelic/serverless-sidecar` |
| `jobManager.sidecar.image.tag` | Sidecar image tag | `latest` |
| `jobManager.sidecar.resources` | Sidecar resource requests and limits | See [Resources](#Resources) |
| `image.repository` | Job Manager container image | `newrelic/serverless-job-manager` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `resources` | Resource requests and limits for Job Manager | See [Resources](#Resources) |
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name to use | |
| `serviceAccount.annotations` | ServiceAccount annotations | |
| `rbac.create` | Create RBAC resources (Role, RoleBinding) | `true` |
| `service.port` | Port for the job-manager service | `8080` |
| `service.adminPort` | Admin port for health checks and metrics | `8082` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `podAnnotations` | Annotations for the job-manager pod | |
| `podSecurityContext` | Security context for the pod | |
| `securityContext` | Security context for containers | |
| `labels` | Labels for all job-manager resources | |
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

Make sure you have [added the New Relic chart repository.](../../README.md#Installthecharts)

### Quick Start (Minimal Configuration)

First, create a Kubernetes Secret with your location credentials:

```sh
kubectl create secret generic nr-location-secrets \
  --from-literal=locationKey=<YOUR_LOCATION_KEY_FROM_NGEP> \
  --from-literal=internalApiKey=<YOUR_INTERNAL_API_KEY>
```

Then, install the chart with minimal required configuration:

```sh
helm install job-manager newrelic/job-manager \
  --set jobManager.location.name=us-east-1-public \
  --set jobManager.location.tags.region=us-east-1 \
  --set jobManager.location.keySecretName=nr-location-secrets \
  --set global.internalApiKeySecretName=nr-location-secrets
```

### Full Configuration Example

For a complete production setup, use a values file:

```sh
helm install job-manager newrelic/job-manager \
  -f charts/job-manager/ci/values-public-location.yaml
```

Example `values-public-location.yaml`:

```yaml
jobManager:
  location:
    keySecretName: "nr-location-secrets"
    name: "us-east-1-public"
    id: "a1b2c3d4-5678-90ab-cdef-1234567890ab"
    description: "New Relic public serverless location in US East"
    tags:
      region: "us-east-1"
      provider: "AWS"
      environment: "production"
    associatedWorkloads:
      - "node-api-runtime_v1"
      - "node-browser-runtime_v1"

global:
  internalApiKeySecretName: "nr-location-secrets"
  checkTimeout: "180"

node-api-runtime:
  enabled: true
  parallelism: 5

node-browser-runtime:
  enabled: true
  parallelism: 5
```

## Validation

The chart includes automatic validation to ensure correct configuration:

1. **Required Fields**: The following fields are validated at install/upgrade time:
   - `jobManager.location.name` - Location identifier
   - `jobManager.location.tags.region` - Cloud region
   - `jobManager.location.associatedWorkloads` - Workload definitions
   - Either `jobManager.location.key` or `jobManager.location.keySecretName`

2. **Runtime Validation**: Ensures enabled runtimes match `associatedWorkloads`:
   - If `node-api-runtime.enabled=true`, then `node-api-runtime` must be in `associatedWorkloads`
   - If `node-browser-runtime.enabled=true`, then `node-browser-runtime` must be in `associatedWorkloads`
   - At least one runtime must be enabled

3. **Serverless Restrictions**:
   - **ping-runtime is NOT supported** in serverless architecture
   - Chart will fail if `ping-runtime` is found in `associatedWorkloads`

If validation fails, Helm will display a clear error message indicating what needs to be fixed.

## Important Notes

- **Location Creation**: ComputeLocation entities are created in NGEP (via NerdGraph API or UI), not by this Helm chart. You must create the location in NGEP first and obtain the `locationKey` before deploying.

- **Public Locations Only**: This chart is optimized for PUBLIC NR-hosted multi-tenant locations. Private customer-hosted locations have different requirements.

- **Multi-Tenant Mode**: Multi-tenant features are always enabled for public locations and include:
  - Account validation before job execution
  - Per-account resource quotas
  - Network isolation between accounts
  - Job queue management per account

- **NGEP Alignment**: All location configuration parameters align with the NGEP ComputeLocation schema to ensure consistency between NGEP entities and Kubernetes deployments.

## Resources

The default set of resources assigned to **job-manager**:

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

## Security Architecture

This implementation follows security best practices from the [Kubernetes Threat Matrix](https://microsoft.github.io/Threat-Matrix-for-Kubernetes/):

### Network Isolation

- **Job Manager Pods**: Deployed in dedicated namespace with NetworkPolicy allowing:
  - EGRESS to K8s API server for resource management
  - EGRESS to orchestrator/broker platform
  - EGRESS to internet (configurable)
  - INGRESS from runtime namespaces on service port
  - Blocks cloud metadata API access (169.254.169.254)

- **Runtime Pods**: (Configured by job manager application)
  - Isolated from each other within namespace
  - Cannot access K8s control plane
  - Cannot access cloud metadata APIs
  - Cannot access kubelet APIs
  - Only allowed to communicate with job manager service

### RBAC & Service Accounts

- **Job Manager SA**: Granted minimal permissions:
  - CRUD on runtime resources (Jobs, Pods, ConfigMaps)
  - CRUD on Leases for coordination
  - NO permissions to create/modify Roles or access cluster-wide resources
  - TLS certificate for K8s API authentication

- **Runtime Pods**: NO service account tokens granted (automount disabled)

### Image Security

- Image policy webhook/OPA Gatekeeper recommended for production
- Base images use distroless/minimal attack surface
- Vulnerability scanning via Trivy/Snyk in CI/CD
- Prevent privileged containers, host mounts, elevated capabilities

### Additional Measures

- No SSH daemons in any containers
- Logs shipped to New Relic, old logs purged promptly
- K8s events shipped for audit trail
- Optional: gVisor/Kata Containers for enhanced runtime isolation
- Optional: AppArmor/Seccomp/SELinux profiles

## Autoscaling Strategy

The platform implements 3-layer autoscaling using K8s native primitives:

### 1. Job Manager Autoscaling (HPA)

- **Metric Source**: External metrics from orchestrator platform endpoint
- **Metrics Exposed**: Pending job count, oldest job age
- **Scaling Logic**: When jobs queue up, HPA spawns additional job manager replicas
- **Response Time**: ~15 seconds (lightweight containers)
- **Scale to Zero**: Supported for customer locations to minimize costs
- **Configuration**:
  ```yaml
  jobManager.hpa.customMetrics.queueDepthMetricName: "serverless_queue_depth"
  jobManager.hpa.customMetrics.targetValue: "100"  # jobs per replica
  ```

### 2. Ephemeral Runtime Scaling

- **Scaling Logic**: Each job execution creates a new K8s Job
- **K8s Native**: Cluster autoscaler provisions nodes as needed
- **Backpressure**: If pod creation fails due to resources, job manager retries with exponential backoff

### 3. Node Autoscaling (Cluster Autoscaler)

- **Triggers**: Pending pods from job manager ephemeral workloads
- **Configuration**:
  - `scale-down-utilization-threshold`: Determines node underutilization
  - `scale-down-unneeded-time`: Grace period before scale-down
- **Recommendations**:
  - NR-hosted: Keep overhead for fast pod spawning (~20% extra capacity)
  - Customer-hosted: Stricter thresholds to minimize costs

## Architecture Details

### Job Manager Components

1. **Deployment**: Orchestrates the Job Manager pods with configurable replicas
2. **Service (ClusterIP)**: Provides stable DNS endpoint for result reporting from runtime pods
3. **ServiceAccount**: Dedicated identity for K8s API interactions with TLS certificate
4. **Role & RoleBinding**: Grants permissions for:
   - CRUD operations on Jobs, Pods, ConfigMaps (runtime namespace)
   - CRUD on Leases for distributed coordination (job manager namespace)
5. **HorizontalPodAutoscaler**: Auto-scales based on external queue depth metrics from orchestrator
6. **Leases**: Distributed coordination for:
   - `runtime-pruning`: One manager pod holds lease to prune unresponsive jobs
7. **NetworkPolicy**: Enforces egress/ingress rules per security model

### Job Execution Flow

1. Job manager pods poll orchestrator platform at fixed rate with fixed batch size
2. Jobs acknowledged only after handed to runtime pod (minimizes delay on backpressure)
3. Create K8s Job for ephemeral workload execution with single-use token
4. Runtime pod executes job, sidecar proxies all EGRESS traffic
5. Runtime pod sends result to job manager service (any manager can handle)
6. Periodic coordination: One manager holds lease to prune TTL-breached jobs

## Support

For issues and questions, please refer to the [New Relic Helm Charts repository](https://github.com/newrelic/helm-charts).
