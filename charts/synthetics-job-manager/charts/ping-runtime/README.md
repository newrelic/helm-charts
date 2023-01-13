# ping-runtime

## Chart Details

## Configuration


| Parameter                    | Description                                                                                                       | Default                            |
|------------------------------|-------------------------------------------------------------------------------------------------------------------|------------------------------------|
| `replicaCount`               | Number of ping-runtime replicas to maintain                                                                       | `1`                                |
| `imagePullSecrets`           | The name of a Secret object used to pull an image from a specified container registry                             |                                    |
| `nameOverride`               | The nameOverride replaces the name of the chart in the Chart.yaml file.                                           |                                    |
| `fullnameOverride`           | Name override used for your installation in place of the default                                                  |                                    |
| `appVersionOverride`         | Release version of ping-runtime to use in place of the version specified in [Chart.yaml](Chart.yaml)              |                                    |
| `image.repository`           | The container to pull.                                                                                            | `newrelic/synthetics-ping-runtime` |
| `image.pullPolicy`           | The pull policy.                                                                                                  | `IfNotPresent`                     |
| `appArmorProfileName`        | Name of an AppArmor profile to load.                                                                              |                                    |
| `resources`                  | Resource requests and limits.                                                                                     |                                    |
| `podAnnotations`             | Annotations to be added to the ping-runtime pod                                                                   |                                    |
| `podSecurityContext`         | Custom security context for the ping-runtime pod                                                                  |                                    |
| `securityContext`            | Custom security context for the ping-runtime containers                                                           |                                    |
| `labels`                     | labels to be added to all ping-runtime resources                                                                  |                                    |
| `annotations`                | Annotations to be added to the ping-runtime pod                                                                   |                                    |
| `nodeSelector`               | Node labels for ping-runtime pod assignment                                                                       |                                    |
| `tolerations`                | Node taints to tolerate for ping-runtime                                                                          |                                    |
| `affinity`                   | Pod affinity for ping-runtime                                                                                     |                                    |
