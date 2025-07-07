| Component          | Receiver              | Metric                                                     | Type    | Description                                                                    |
|--------------------|-----------------------|------------------------------------------------------------|---------|--------------------------------------------------------------------------------|
| API Server         | Prometheus Receiver   | apiserver_storage_objects                                  | Gauge   | Number of objects stored in the API server.                                    |
| API Server         | Prometheus Receiver   | go_goroutines                                              | Gauge   | Number of goroutines that currently exist.                                     |
| API Server         | Prometheus Receiver   | go_threads                                                 | Gauge   | Number of OS threads created.                                                  |
| API Server         | Prometheus Receiver   | process_resident_memory_bytes                              | Gauge   | Resident memory size in bytes.                                                 |
| cAdvisor           | Prometheus Receiver   | container_cpu_cfs_periods_total                            | Counter | Total number of elapsed enforcement period intervals.                          |
| cAdvisor           | Prometheus Receiver   | container_cpu_cfs_throttled_periods_total                  | Counter | Total number of throttled period intervals.                                    |
| cAdvisor           | Prometheus Receiver   | container_cpu_usage_seconds_total                          | Counter | Total CPU time consumed.                                                       |
| cAdvisor           | Prometheus Receiver   | container_memory_mapped_file                               | Gauge   | Size of memory mapped files in bytes.                                          |
| cAdvisor           | Prometheus Receiver   | container_memory_working_set_bytes                         | Gauge   | Working set size of memory in bytes.                                           |
| cAdvisor           | Prometheus Receiver   | container_network_receive_bytes_total                      | Counter | Cumulative count of bytes received.                                            |
| cAdvisor           | Prometheus Receiver   | container_network_receive_errors_total                     | Counter | Cumulative count of receive errors encountered.                                |
| cAdvisor           | Prometheus Receiver   | container_network_transmit_bytes_total                     | Counter | Cumulative count of bytes transmitted.                                         |
| cAdvisor           | Prometheus Receiver   | container_network_transmit_errors_total                    | Counter | Cumulative count of transmit errors encountered.                               |
| cAdvisor           | Prometheus Receiver   | container_spec_memory_limit_bytes                          | Gauge   | Memory limit of the container in bytes.                                        |
| Controller Manager | Prometheus Receiver   | go_goroutines                                              | Gauge   | Number of goroutines that currently exist.                                     |
| Controller Manager | Prometheus Receiver   | process_resident_memory_bytes                              | Gauge   | Resident memory size in bytes.                                                 |
| Kubelet            | KubeletStats Receiver | container.cpu.usage                                        | Gauge   | Total CPU usage (sum of all cores per second) averaged over the sample window. |
| Kubelet            | KubeletStats Receiver | container.filesystem.available                             | Gauge   | Available filesystem space for the container.                                  |
| Kubelet            | KubeletStats Receiver | container.filesystem.capacity                              | Gauge   | Total filesystem capacity for the container.                                   |
| Kubelet            | KubeletStats Receiver | container.filesystem.usage                                 | Gauge   | Used filesystem space for the container.                                       |
| Kubelet            | KubeletStats Receiver | container.memory.usage                                     | Gauge   | Total memory usage of the container.                                           |
| Kubelet            | Prometheus Receiver   | go_goroutines                                              | Gauge   | Number of goroutines that currently exist.                                     |
| Kubelet            | Prometheus Receiver   | go_threads                                                 | Gauge   | Number of OS threads created.                                                  |
| Kubelet            | KubeletStats Receiver | k8s.node.cpu.time                                          | Gauge   | Total CPU time used by the node.                                               |
| Kubelet            | KubeletStats Receiver | k8s.node.cpu.usage                                         | Gauge   | Total CPU usage (sum of all cores per second) averaged over the sample window. |
| Kubelet            | KubeletStats Receiver | k8s.node.filesystem.capacity                               | Gauge   | Total filesystem capacity for the node.                                        |
| Kubelet            | KubeletStats Receiver | k8s.node.filesystem.usage                                  | Gauge   | Used filesystem space for the node.                                            |
| Kubelet            | KubeletStats Receiver | k8s.node.memory.available                                  | Gauge   | Available memory for the node.                                                 |
| Kubelet            | KubeletStats Receiver | k8s.node.memory.working_set                                | Gauge   | Working set size of the node memory.                                           |
| Kubelet            | KubeletStats Receiver | k8s.pod.filesystem.available                               | Gauge   | Available filesystem space for the pod.                                        |
| Kubelet            | KubeletStats Receiver | k8s.pod.filesystem.capacity                                | Gauge   | Total filesystem capacity for the pod.                                         |
| Kubelet            | KubeletStats Receiver | k8s.pod.filesystem.usage                                   | Gauge   | Used filesystem space for the pod.                                             |
| Kubelet            | KubeletStats Receiver | k8s.pod.memory.working_set                                 | Gauge   | Working set size of the pod memory.                                            |
| Kubelet            | KubeletStats Receiver | k8s.pod.network.io                                         | Counter | Total network I/O for the pod.                                                 |
| Kubelet            | Prometheus Receiver   | process_resident_memory_bytes                              | Gauge   | Resident memory size in bytes.                                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_cronjob_created                                       | Gauge   | Creation timestamp of the CronJob.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_cronjob_spec_suspend                                  | Gauge   | Suspend flag of the CronJob.                                                   |
| KubeStateMetrics   | Prometheus Receiver   | kube_cronjob_status_active                                 | Gauge   | Number of active CronJob instances.                                            |
| KubeStateMetrics   | Prometheus Receiver   | kube_cronjob_status_last_schedule_time                     | Gauge   | Last schedule time of the CronJob.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_created                                     | Gauge   | Creation timestamp of the DaemonSet.                                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_current_number_scheduled             | Gauge   | Current number of scheduled DaemonSet instances.                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_desired_number_scheduled             | Gauge   | Desired number of scheduled DaemonSet instances.                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_number_available                     | Gauge   | Number of available DaemonSet instances.                                       |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_number_misscheduled                  | Gauge   | Number of misscheduled DaemonSet instances.                                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_number_ready                         | Gauge   | Number of ready DaemonSet instances.                                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_number_unavailable                   | Gauge   | Number of unavailable DaemonSet instances                                      |
| KubeStateMetrics   | Prometheus Receiver   | kube_daemonset_status_updated_number_scheduled             | Gauge   | Updated number of scheduled DaemonSet instances.                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_created                                    | Gauge   | Creation timestamp of the Deployment.                                          |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_metadata_generation                        | Gauge   | Generation number of the Deployment metadata.                                  |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_spec_replicas                              | Gauge   | Number of desired replicas for the Deployment.                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_spec_strategy_rollingupdate_max_surge      | Gauge   | Maximum surge allowed during rolling update.                                   |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_condition                           | Gauge   | Deployment status conditions.                                                  |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_observed_generation                 | Gauge   | The most recent generation observed for this Deployment.                       |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_replicas                            | Gauge   | Number of replicas for the Deployment.                                         |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_replicas_available                  | Gauge   | Number of available replicas for the Deployment.                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_replicas_ready                      | Gauge   | Number of ready replicas for the Deployment.                                   |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_replicas_unavailable                | Gauge   | Number of unavailable replicas for the Deployment.                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_deployment_status_replicas_updated                    | Gauge   | Number of updated replicas for the Deployment.                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_horizontalpodautoscaler_spec_max_replicas             | Gauge   | Maximum number of replicas for the HorizontalPodAutoscaler.                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_horizontalpodautoscaler_spec_min_replicas             | Gauge   | Minimum number of replicas for the HorizontalPodAutoscaler.                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_horizontalpodautoscaler_status_condition              | Gauge   | Status conditions of the HorizontalPodAutoscaler.                              |
| KubeStateMetrics   | Prometheus Receiver   | kube_horizontalpodautoscaler_status_current_replicas       | Gauge   | Current number of replicas for the HorizontalPodAutoscaler.                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_horizontalpodautoscaler_status_desired_replicas       | Gauge   | Desired number of replicas for the HorizontalPodAutoscaler.                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_complete                                          | Gauge   | Whether the Job is complete (1) or not (0).                                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_created                                           | Gauge   | Creation timestamp of the Job.                                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_failed                                            | Gauge   | Whether the Job has failed (1) or not (0).                                     |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_owner                                             | Gauge   | Owner information of the Job.                                                  |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_spec_active_deadline_seconds                      | Gauge   | Number of seconds the Job can run before being terminated.                     |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_spec_completions                                  | Gauge   | Desired number of successfully finished pods for the Job.                      |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_spec_parallelism                                  | Gauge   | Maximum desired number of pods executing in parallel for the Job.              |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_status_active                                     | Gauge   | Number of active pods for the Job.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_status_completion_time                            | Gauge   | Completion time of the Job.                                                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_status_failed                                     | Gauge   | Number of failed pods for the Job.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_status_start_time                                 | Gauge   | Start time of the Job.                                                         |
| KubeStateMetrics   | Prometheus Receiver   | kube_job_status_succeeded                                  | Gauge   | Number of succeeded pods for the Job.                                          |
| KubeStateMetrics   | Prometheus Receiver   | kube_node_status_allocatable                               | Gauge   | Allocatable resources of the Node.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_node_status_capacity                                  | Gauge   | Capacity of the Node.                                                          |
| KubeStateMetrics   | Prometheus Receiver   | kube_node_status_condition                                 | Gauge   | Condition of the Node's status.                                                |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolume_capacity_bytes                       | Gauge   | Capacity of the PersistentVolume in bytes.                                     |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolume_created                              | Gauge   | Creation timestamp of the PersistentVolume.                                    |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolume_info                                 | Gauge   | Information about the PersistentVolume.                                        |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolume_status_phase                         | Gauge   | Phase of the PersistentVolume.                                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolumeclaim_access_mode                     | Gauge   | Access mode of the PersistentVolumeClaim.                                      |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolumeclaim_created                         | Gauge   | Creation timestamp of the PersistentVolumeClaim.                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolumeclaim_info                            | Gauge   | Information about the PersistentVolumeClaim.                                   |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolumeclaim_resource_requests_storage_bytes | Gauge   | Storage resource requests of the PersistentVolumeClaim in bytes.               |
| KubeStateMetrics   | Prometheus Receiver   | kube_persistentvolumeclaim_status_phase                    | Gauge   | Phase of the PersistentVolumeClaim.                                            |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_info                                    | Gauge   | Information about the Pod container.                                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_resource_limits                         | Gauge   | Resource limits of the Pod container.                                          |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_resource_requests                       | Gauge   | Resource requests of the Pod container.                                        |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_status_phase                            | Gauge   | Current phase of the Pod container.                                            |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_status_ready                            | Gauge   | Whether the Pod container is ready (1) or not (0).                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_status_restarts_total                   | Counter | Total number of restarts for the Pod container.                                |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_container_status_waiting_reason                   | Gauge   | Reason for the container waiting state.                                        |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_created                                           | Gauge   | Creation timestamp of the Pod.                                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_info                                              | Gauge   | Information about the Pod.                                                     |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_owner                                             | Gauge   | Owner information of the Pod.                                                  |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_start_time                                        | Gauge   | Start time of the Pod.                                                         |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_status_phase                                      | Gauge   | Current phase of the Pod status.                                               |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_status_ready                                      | Gauge   | Whether the Pod is ready (1) or not (0).                                       |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_status_ready_time                                 | Gauge   | Time when the Pod status became ready.                                         |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_status_scheduled                                  | Gauge   | Whether the Pod is scheduled (1) or not (0).                                   |
| KubeStateMetrics   | Prometheus Receiver   | kube_pod_status_scheduled_time                             | Gauge   | Time when the Pod became scheduled.                                            |
| KubeStateMetrics   | Prometheus Receiver   | kube_replicaset_owner                                      | Gauge   | Owner information of the ReplicaSet.                                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_service_created                                       | Gauge   | Creation timestamp of the Service.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_service_info                                          | Gauge   | Information about the Service.                                                 |
| KubeStateMetrics   | Prometheus Receiver   | kube_service_spec_type                                     | Gauge   | Type of the Service specification.                                             |
| KubeStateMetrics   | Prometheus Receiver   | kube_service_status_load_balancer_ingress                  | Gauge   | Status of the load balancer ingress for the Service.                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_created                                   | Gauge   | Creation timestamp of the StatefulSet.                                         |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_persistentvolumeclaim_retention_policy    | Gauge   | Retention policy of PersistentVolumeClaims for the StatefulSet.                |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_replicas                                  | Gauge   | Desired number of replicas for the StatefulSet.                                |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_current_revision                   | Gauge   | Current revision of the StatefulSet.                                           |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_replicas                           | Gauge   | Number of replicas for the StatefulSet.                                        |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_replicas_available                 | Gauge   | Number of available replicas for the StatefulSet.                              |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_replicas_current                   | Gauge   | Number of current replicas for the StatefulSet.                                |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_replicas_ready                     | Gauge   | Number of ready replicas for the StatefulSet.                                  |
| KubeStateMetrics   | Prometheus Receiver   | kube_statefulset_status_replicas_updated                   | Gauge   | Number of updated replicas for the StatefulSet.                                |
| Node               | HostMetric Receiver   | process.cpu.utilization                                    | Gauge   | CPU utilization of the process as a percentage.                                |
| Node               | HostMetric Receiver   | process.disk.io                                            | Counter | Number of disk I/O operations performed by the process.                        |
| Node               | HostMetric Receiver   | process.memory.usage                                       | Gauge   | Memory usage of the process in bytes.                                          |
| Node               | HostMetric Receiver   | process.memory.virtual                                     | Gauge   | Virtual memory usage of the process in bytes.                                  |
| Node               | HostMetric Receiver   | system.cpu.load_average.15m                                | Gauge   | System load average over the last 15 minutes.                                  |
| Node               | HostMetric Receiver   | system.cpu.load_average.1m                                 | Gauge   | System load average over the last 1 minute.                                    |
| Node               | HostMetric Receiver   | system.cpu.load_average.5m                                 | Gauge   | System load average over the last 5 minutes.                                   |
| Node               | HostMetric Receiver   | system.cpu.utilization                                     | Gauge   | Total CPU utilization percentage.                                              |
| Node               | HostMetric Receiver   | system.disk.io                                             | Counter | Number of disk I/O operations performed.                                       |
| Node               | HostMetric Receiver   | system.disk.io_time                                        | Counter | Time spent in disk I/O operations in seconds.                                  |
| Node               | HostMetric Receiver   | system.disk.operation_time                                 | Counter | Total time spent in disk operations in seconds.                                |
| Node               | HostMetric Receiver   | system.disk.operations                                     | Counter | Number of disk operations performed.                                           |
| Node               | HostMetric Receiver   | system.filesystem.usage                                    | Gauge   | Usage of filesystem space in bytes.                                            |
| Node               | HostMetric Receiver   | system.filesystem.utilization                              | Gauge   | Utilization of the filesystem as a percentage.                                 |
| Node               | HostMetric Receiver   | system.memory.usage                                        | Gauge   | Total memory usage in bytes.                                                   |
| Node               | HostMetric Receiver   | system.memory.utilization                                  | Gauge   | Memory utilization as a percentage.                                            |
| Node               | HostMetric Receiver   | system.network.errors                                      | Counter | Number of network errors.                                                      |
| Node               | HostMetric Receiver   | system.network.io                                          | Counter | Number of network I/O operations.                                              |
| Node               | HostMetric Receiver   | system.network.packets                                     | Counter | Number of network packets transmitted and received.                            |
| Scheduler          | Prometheus Receiver   | go_goroutines                                              | Gauge   | Number of goroutines that currently exist.                                     |
| Scheduler          | Prometheus Receiver   | process_resident_memory_bytes                              | Gauge   | Resident memory size in bytes.                                                 |
