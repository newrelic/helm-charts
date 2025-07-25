
When using your own collector, the following configurations need to be added to your collector config in order to enable the New Relic Kubernetes experience. 

**NB** kube-state-metrics must be deployed in your cluster. 

## Receivers


### Prometheus Receiver
The Prometheus receiver must be configured to scrape the following targets
#### kube-state-metrics 
kube-state-metrics should be scraped by Opentelemetry deployed as a deployment. 

``` deployment.yaml 
    - job_name: kube-state-metrics
        scrape_interval: 1m
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - action: keep
            regex: kube-state-metrics
            source_labels:
            - __meta_kubernetes_pod_label_app_kubernetes_io_name
        - action: replace
            target_label: job_label
            replacement: kube-state-metrics
```
#### apiserver 
apiserver should be scraped by Opentelemetry deployed as a deployment. 

```deployment.yaml 
    - job_name: apiserver
        scrape_interval: 1m
        kubernetes_sd_configs:
        - role: endpoints
            namespaces:
            names:
                - default
        scheme: https
        tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: false
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - action: keep
        regex: default;kubernetes;https
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
        - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
        - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
        - action: replace
        target_label: job_label
        replacement: apiserver
```
#### controller-manager 
controller-manager should be scraped by Opentelemetry deployed as a deployment
```deployment.yaml 
    - job_name: controller-manager
        scrape_interval: 1m
        metrics_path: /metrics
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: false
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - action: keep
        regex: default;kubernetes;https
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
        - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
        - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
        - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
        - action: replace
        target_label: job_label
        replacement: controller-manager
```

#### scheduler 
scheduler should be scraped by Opentelemetry deployed as a deployment 
```deployment.yaml 
    - job_name: scheduler
        scrape_interval: 1m
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - action: keep
        regex: default;kubernetes;https
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
        - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
        - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: service
        - action: replace
        target_label: job_label
        replacement: scheduler
```
#### cadvisor 
cadvisor should be scraped by Opentelemetry deployed as a daemonset
``` daemonset.yaml 
    - job_name: cadvisor
        scrape_interval: 1m
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - replacement: kubernetes.default.svc.cluster.local:443
          target_label: __address__
        - regex: (.+)
          replacement: /api/v1/nodes/$${1}/proxy/metrics/cadvisor
          source_labels:
            - __meta_kubernetes_node_name
          target_label: __metrics_path__
        - action: replace
          target_label: job_label
          replacement: cadvisor
        - source_labels: [__meta_kubernetes_node_name]
          regex: ${KUBE_NODE_NAME}
          action: keep
        scheme: https
        tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: false
        server_name: kubernetes
``` 
#### kubelet 
kubelet should be scraped by Opentelemetry deployed as a daemonset 

``` daemonset.yaml 
    - job_name: kubelet
        scrape_interval: 1m
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - replacement: kubernetes.default.svc.cluster.local:443
          target_label: __address__
        - regex: (.+)
          replacement: /api/v1/nodes/$${1}/proxy/metrics
          source_labels:
            - __meta_kubernetes_node_name
          target_label: __metrics_path__
        - action: replace
          target_label: job_label
          replacement: kubelet
        - source_labels: [__meta_kubernetes_node_name]
          regex: ${KUBE_NODE_NAME}
          action: keep
        scheme: https
        tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: false
        server_name: kubernetes

```
### Hostmetrics Receiver 
hostmetrics receiver: 
```
    hostmetrics:
        root_path: /hostfs
        collection_interval: 1m
        scrapers:
          cpu:
            metrics:
              system.cpu.time:
                enabled: false
              system.cpu.utilization:
                enabled: true
          load:
          memory:
            metrics:
              system.memory.utilization:
                enabled: true
          paging:
            metrics:
              system.paging.utilization:
                enabled: false
              system.paging.faults:
                enabled: false
          filesystem:
            metrics:
              system.filesystem.utilization:
                enabled: true
          disk:
            metrics:
              system.disk.merged:
                enabled: false
              system.disk.pending_operations:
                enabled: false
              system.disk.weighted_io_time:
                enabled: false
          network:
            metrics:
              system.network.connections:
                enabled: false
          processes:
          process:
            metrics:
              process.cpu.utilization:
                enabled: true
              process.cpu.time:
                enabled: false
            mute_process_name_error: true
            mute_process_exe_error: true
            mute_process_io_error: true
            mute_process_user_error: true
```
### Kubeletstats Receiver
kubeletstats:
```
    kubeletstats:
        collection_interval: {{ .Values.receivers.kubeletstats.scrapeInterval }}
        {{- if not (include "newrelic.common.gkeAutopilot" .) }}
        endpoint: "${KUBE_NODE_NAME}:10250"
        auth_type: "serviceAccount"
        insecure_skip_verify: true
        {{- else }}
        endpoint: "${KUBE_NODE_NAME}:10255"
        auth_type: "none"
        {{- end }}
        metrics:
          k8s.container.cpu_limit_utilization:
            enabled: true 
```  

## Processors

We renamed the metric `kubernetes_build_info` to `k8s_cluster_info` which informs new relic that the kubernetes cluster is up and running. 
```
    metricstransform/k8s_cluster_info:
        transforms:
          - include: kubernetes_build_info
            action: update
            new_name: k8s.cluster.info 
```

We consolidated the kube_pod_container_status_(waiting|running|terminated) metric to `kube_pod_container_status_phase, adding a label for the phase that the pod is in, to facilitate querying on the NR platform. 
```
    metricstransform/kube_pod_status_phase:
        transforms:
          - include: 'kube_pod_container_status_waiting'
            match_type: strict 
            action: update
            new_name: 'kube_pod_container_status_phase'
            operations:
            - action: add_label
              new_label: container_phase
              new_value: waiting 
          - include: 'kube_pod_container_status_running'
            match_type: strict
            action: update
            new_name: 'kube_pod_container_status_phase'
            operations:
            - action: add_label
              new_label: container_phase
              new_value: running 
          - include: 'kube_pod_container_status_terminated'
            match_type: strict
            action: update
            new_name: 'kube_pod_container_status_phase'
            operations:
            - action: add_label
              new_label: container_phase
              new_value: terminated 
``` 

This copies over the value of the following attributes (pod|deployment|node|namespace) in various metrics over to k8s.pod.name, k8s.deployment.name, k8s.node.name, k8s.namespace.name attributes as we use those attributes in the NR platform. We will be removing this soon however, as we standardize attribute references across the platform. 
```
    attributes/self:
        actions:
          - key: k8s.pod.name
            action: upsert
            from_attribute: pod
          - key: k8s.deployment.name
            action: upsert
            from_attribute: deployment
          - key: k8s.node.name
            action: upsert
            from_attribute: node
          - key: k8s.namespace.name
            action: upsert
            from_attribute: namespace
``` 

We aggregate the attributes in the following metrics (system.cpu.utilization and system.paging.operations) for ease of querying in the NR platform. 
```
    metricstransform/hostmetrics_cpu:
        transforms:
          - include: system.cpu.utilization
            action: update
            operations:
              - action: aggregate_labels
                label_set: [ state ]
                aggregation_type: mean
          - include: system.paging.operations
            action: update
            operations:
              - action: aggregate_labels
                label_set: [ direction ]
                aggregation_type: sum
``` 

Resource detection is an important part of lighting up the host entities in the NR platform, and helps decorate the host metrics with the correct attributes so that we can query for them in various charts across the platform. Daemonset only.
```
      resourcedetection/cloudproviders:
        detectors: [gcp, eks, ec2, aks, azure]
        timeout: 2s
        override: false
```

We upsert various attributes to every metric reported by otel to support various NR platform functionality. This processor is subject to change. 
```
    resource:
        attributes:
          - key: k8s.cluster.name
            action: upsert
            value: <cluster-name>
          - key: newrelicOnly
            action: upsert
            value: 'true'
          - key: service.name
            action: delete
          - key: service_name
            action: delete
```

The k8s attribute processor is probably already used if you are using opentelemetry to monitor your kubernetes cluster; it works to decorate the metrics with various kubernetes related metadata to support querying and clarity in understanding where the metrics come from. 
```
    k8sattributes:
        auth_type: "serviceAccount"
        passthrough: false
        filter:
          node_from_env_var: KUBE_NODE_NAME
        extract:
          metadata:
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.deployment.name
            - k8s.daemonset.name
            - k8s.namespace.name
            - k8s.node.name
            - k8s.pod.start_time
        pod_association:
          - sources: 
            - from: resource_attribute
              name: k8s.pod.uid
```

## Exporters 

US
```
    otlphttp/newrelic_us:
        endpoint: https://otlp.nr-data.net
            headers:
            api-key: <<NR api key>
```
EU 
```
    otlphttp/newrelic_eu:
        endpoint: https://otlp.eu01.nr-data.net
            headers:
            api-key: <<NR api key>
```


