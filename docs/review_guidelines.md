# Chart review guidelines

The process to get a pull request merged is fairly simple. First, all required tests need to pass, and you must have signed our CLA. For details on our CI, see the [Charts testing GitHub action](https://github.com/helm/chart-testing-action).

If problems arise with some part of the test, such as timeout issues, contact one of the [repository maintainers](CODEOWNERS).

1. [Immutability](#Immutability)
2. [Versioning](#Versioning)
3. [Compatibility](#Compatibility)
4. [Chart metadata](#Chartmetadata)
5. [Dependencies](#Dependencies)
6. [Metadata](#Metadata)
7. [Labels](#Labels)
8. [Configuration](#Configuration)
9. [Features](#Features)
10. [Formatting](#Formatting)
11. [Documentation](#Documentation)
12. [Tests](#Tests)

##  1. <a name='Immutability'></a>Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version bump even if it is only changed to the documentation.

##  2. <a name='Versioning'></a>Versioning

The chart's `version` must adhere to [SemVer 2](https://semver.org/spec/v2.0.0.html).

Stable charts must start at `1.0.0` (for increased maintainability, do not create new pull requests for stable charts simply to meet these criteria; rather, take the opportunity to ensure that this is met when reviewing pull requests).

Breaking (backwards incompatible) changes to a chart must:

1. Bump the MAJOR version
2. Be documented in the README, under a section called _Upgrading_, with the steps necessary to upgrade to the new (specified) MAJOR version

##  3. <a name='Compatibility'></a>Compatibility

We officially support compatibility with the current and the previous minor version of Kubernetes. Generated resources should use the latest possible API versions compatible with these versions. 

For extended backwards compatibility, conditional logic based on capabilities may be used (see [built-in objects](https://github.com/helm/helm/blob/master/docs/chart_template_guide/builtin_objects.md)).

##  4. <a name='Chartmetadata'></a>Chart metadata

The accompanying `Chart.yaml` file should be as complete as possible. 

The following fields are **mandatory**:

* `name` (the chart's directory)
* `home`
* `version`
* `appVersion`
* `description`
* `maintainers` (GitHub usernames)

##  5. <a name='Dependencies'></a>Dependencies

Stable charts should not depend on charts in the incubator.

##  6. <a name='Metadata'></a>Metadata

Resources and labels should follow some conventions. The standard resource metadata (`metadata.labels` and `spec.template.metadata.labels`) should be this:

```yaml
name: {{ include "myapp.fullname" . }}
labels:
  app.kubernetes.io/name: {{ include "myapp.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  helm.sh/chart: {{ include "myapp.chart" . }}
```

If a chart has multiple components, the `app.kubernetes.io/component` label should be added (for example, `app.kubernetes.io/component: server`). 

The resource name should get the component as suffix (for example, `name: {{ include "myapp.fullname" . }}-server`).

> Templates must be namespaced. This is `helm create`'s default behavior with Helm 2.7 or higher. For example, `app.kubernetes.io/name` should use the `name` template, not `fullname`, as is still the case with older charts.

##  7. <a name='Labels'></a>Labels

###  7.1. <a name='DeploymentsStatefulSetsDaemonSetsSelectors'></a>Deployments, StatefulSets, DaemonSets Selectors

`spec.selector.matchLabels` must be specified. The standard selector should be this:

```yaml
selector:
  matchLabels:
    app.kubernetes.io/name: {{ include "myapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
```

If a chart has multiple components, a `component` label should be added to the selector (see above).

`spec.selector.matchLabels` defined in `Deployments`/`StatefulSets`/`DaemonSets` `>=v1/beta2` **must not** contain the `helm.sh/chart` label or any label containing a version of the chart, because the selector is immutable.

The chart label string contains the version; if specified, whenever the `Chart.yaml` version changes, Helm's attempt to change the immutable field would cause the upgrade to fail.

####  7.1.1. <a name='Fixingselectors'></a>Fixing selectors

##### For `Deployments`, `StatefulSets`, `DaemonSets` `apps/v1beta1` or `extensions/v1beta1`

- Set `spec.selector.matchLabels` if missing
- Remove the `helm.sh/chart` label in `spec.selector.matchLabels`
- Bump the patch version of the Chart

##### For `Deployments`, `StatefulSets`, `DaemonSets` >= `apps/v1beta2`

- Remove the `helm.sh/chart` label in `spec.selector.matchLabels`
- Bump the major version of the chart -- it's a breaking change

###  7.2. <a name='Serviceselectors'></a>Service selectors

Label selectors for services must have both `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels.

```yaml
selector:
  app.kubernetes.io/name: {{ include "myapp.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
```

If a chart has multiple components, an `app.kubernetes.io/component` label should be added to the selector.

###  7.3. <a name='PersistenceLabels'></a>Persistence Labels

####  7.3.1. <a name='StatefulSet'></a>StatefulSet

In case of a `Statefulset`, `spec.volumeClaimTemplates.metadata.labels` must have both `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels, and **must not** contain `helm.sh/chart` or any label containing a version of the chart, because `spec.volumeClaimTemplates` is immutable.

```yaml
labels:
  app.kubernetes.io/name: {{ include "myapp.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
```

If a chart has multiple components, an `app.kubernetes.io/component` label should be added to the selector.

####  7.3.2. <a name='PersistentVolumeClaim'></a>PersistentVolumeClaim

In case of a `PersistentVolumeClaim`, `matchLabels` should not be specified, as it'd prevent automatic `PersistentVolume` provisioning.

##  8. <a name='Configuration'></a>Configuration

* Docker images should be configurable. Image tags should use stable versions.

```yaml
image:
  repository: myapp
  tag: 1.2.3
  pullPolicy: IfNotPresent
```

* The use of the `default` function should be avoided if possible in favor of defaults in `values.yaml`.
* It is usually best to not specify defaults for resources and to just provide sensible values that are commented out as a recommendation, especially when resources are rather high. This makes it easier to test charts on small clusters or Minikube. Setting resources should generally be a conscious choice of the user.

##  9. <a name='Features'></a>Features

###  9.1. <a name='Kubernetesnativeworkloads'></a>Kubernetes native workloads

When reviewing charts that contain workloads such as [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/), [DaemonSets](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/), and [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/) the below points should be considered.  These are to be seen as best practices rather than strict rules.

* Create workloads that are stateless and long-running (servers) as `Deployments`. `Deployments`, in turn, create `ReplicaSets`.
* `ReplicaSets` or `ReplicationControllers` should be avoided as workload types, unless there is a compelling reason.
* Create workloads that are stateful, such as databases, key-value stores, message queues, and in-memory caches, as `StatefulSets`.
* `Deployments` and `StatefulSets` should configure their workloads with a [Pod Disruption Budget](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/) for high availability.
* Configure interpod anti-affinity for workloads that replicate data,such as databases, KV stores, etc.
* Have a default workload update strategy configured that is suitable for your chart.
* Create `Batch` workloads using `Jobs`.
* Create workloads with the latest supported [API version](https://v1-8.docs.kubernetes.io/docs/api-reference/v1.8/).
* Do not provide hard [resource limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container) to workloads and leave them configurable unless required.
* Configure complex pre-app setups using [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) when possible.

###  9.2. <a name='Persistence'></a>Persistence

* Persistence should be enabled by default
* PVCs should support specifying an existing claim
* Storage class should be empty by default so that the default storage class is used
* All options should be shown in README.md

Sample persistence section in `values.yaml`:

```yaml
persistence:
  enabled: true
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 10Gi
  # existingClaim: ""
```

Sample pod spec within a deployment:

```yaml
volumes:
  - name: data
  {{- if .Values.persistence.enabled }}
    persistentVolumeClaim:
      claimName: {{ .Values.persistence.existingClaim | default (include "myapp.fullname" .) }}
  {{- else }}
    emptyDir: {}
  {{- end -}}
```

Sample `pvc.yaml`:

```yaml
{{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) }}
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ include "myapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    helm.sh/chart: {{ include "myapp.chart" . }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode | quote }}
  resources:
    requests:
      storage: {{ .Values.persistence.size | quote }}
{{- if .Values.persistence.storageClass }}
{{- if (eq "-" .Values.persistence.storageClass) }}
  storageClassName: ""
{{- else }}
  storageClassName: "{{ .Values.persistence.storageClass }}"
{{- end }}
{{- end }}
{{- end }}
```

###  9.3. <a name='AutoScalingHorizontalPodAutoscaler'></a>AutoScaling / HorizontalPodAutoscaler

* Autoscaling should be disabled by default
* All options should be shown in the README

Sample autoscaling section in `values.yaml`:

```yaml
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
  targetMemoryUtilizationPercentage: 50
```

Sample `hpa.yaml`:

```yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ include "myapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    helm.sh/chart: {{ include "myapp.chart" . }}
    app.kubernetes.io/component: "{{ .Values.name }}"
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "myapp.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        targetAverageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        targetAverageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
{{- end }}
```

###  9.4. <a name='Ingress'></a>Ingress

* See the [Ingress resource documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/) for an overview.
* Ingress should be disabled by default.

Sample ingress section in `values.yaml`:

```yaml
ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  path: /
  hosts:
    - chart-example.test
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.test
```

Sample `ingress.yaml`:

```yaml
{{- if .Values.ingress.enabled -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" }}
apiVersion: networking.k8s.io/v1beta1
{{ else }}
apiVersion: extensions/v1beta1
{{ end -}}
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" }}
  labels:
    app.kubernetes.io/name: {{ include "myapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    helm.sh/chart: {{ include "myapp.chart" . }}
{{- with .Values.ingress.annotations }}
  annotations:
{{ toYaml . | indent 4 }}
{{- end }}
spec:
{{- if .Values.ingress.tls }}
  tls:
  {{- range .Values.ingress.tls }}
    - hosts:
      {{- range .hosts }}
        - {{ . | quote }}
      {{- end }}
      secretName: {{ .secretName }}
  {{- end }}
{{- end }}
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ . | quote }}
      http:
        paths:
          - path: {{ .Values.ingress.path }}
            backend:
              serviceName: {{ include "myapp.fullname" }}
              servicePort: http
  {{- end }}
{{- end }}
```

Sample prepend logic for getting an application URL in `NOTES.txt`:

```yaml
{{- if .Values.ingress.enabled }}
{{- range .Values.ingress.hosts }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ . }}{{ $.Values.ingress.path }}
{{- end }}
```

##  10. <a name='Formatting'></a>Formatting

* Use two-space indentation when editing YAML files.
* Keep list indentation style consistent within files.
* Add a single space after `{{` and before `}}`.

##  11. <a name='Documentation'></a>Documentation

`README.md` and `NOTES.txt` files are mandatory. `README.md` should contain a table listing all configuration options. `NOTES.txt` should provide accurate and useful information on how the chart can be used/accessed.

##  12. <a name='Tests'></a>Tests

See the [chart testing documentation](CHART_TESTING.md).
