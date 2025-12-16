# node-browser-runtime

## Chart Details

## Configuration

| Parameter             | Description                                                                                                                | Default                                    |
|-----------------------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|
| `parallelism`         | Number of node-browser-runtime jobs to execute in parallel                                                                 | `1`                                        |
| `completions`         | Number of node-browser-runtime jobs that you expect to execute per minute (multiplied by the value of `parallelism` above) | `6`                                        |
| `imagePullSecrets`    | The name of a Secret object used to pull an image from a specified container registry                                      |                                            |
| `nameOverride`        | The nameOverride replaces the name of the chart in the Chart.yaml file.                                                    |                                            |
| `fullnameOverride`    | Name override used for your installation in place of the default                                                           |                                            |
| `appVersionOverride`  | Release version of node-browser-runtime to use in place of the version specified in [Chart.yaml](Chart.yaml)               |                                            |
| `image.repository`    | The container to pull.                                                                                                     | `newrelic/synthetics-node-browser-runtime` |
| `image.pullPolicy`    | The pull policy.                                                                                                           | `IfNotPresent`                             |
| `appArmorProfileName` | Name of an AppArmor profile to load.                                                                                       |                                            |
| `resources`           | Resource requests and limits.                                                                                              |                                            |
| `podAnnotations`      | Annotations to be added to the node-browser-runtime pod                                                                    |                                            |
| `podSecurityContext`  | Custom security context for the node-browser-runtime pod                                                                   |                                            |
| `securityContext`     | Custom security context for the node-browser-runtime containers                                                            |                                            |
| `labels`              | labels to be added to all node-browser-runtime resources                                                                   |                                            |
| `annotations`         | Annotations to be added to the node-browser-runtime pod                                                                    |                                            |
| `nodeSelector`        | Node labels for node-browser-runtime pod assignment                                                                        |                                            |
| `tolerations`         | Node taints to tolerate for node-browser-runtime                                                                           |                                            |
| `affinity`            | Pod affinity for node-browser-runtime                                                                                      |                                            |
