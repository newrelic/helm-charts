# Installation: 

### 1. Download source code 
```
git clone https://github.com/newrelic/helm-charts.git
```

### 2. Update config [here](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/values.yaml#L20-L24) to add a cluster name, and New Relic Ingest - License key
Example: 
```
licenseKey: "EXAMPLEINGESTLICENSEKEY345878592NRALL"
cluster: "SampleApp" 
```

### 3. From the root directory of this chart, run:
```
helm install nr-k8s-otel-collector nr-k8s-otel-collector -n newrelic --create-namespace
```

## Confirm installation
### Watch pods spin up: 
```
kubectl get pods -A --watch 
```

### Check logs of opentelemetry pod that spins up: 
```
kubectl logs <otel-pod-name> -n newrelic
```

### Confirm data coming through in New Relic 
You should see data reporting into New Relic within a couple of seconds to the `InfrastructureEvent` table, `Metric` table, and `Log` tables.
```
FROM Metric SELECT * 
```
```
FROM InfrastructureEvent SELECT * 
```
```
FROM Log SELECT * 
```

## Development notes
### Iterating on otel config: 
1. Make changes to the [opentelemetry configuration](https://github.com/newrelic/helm-charts/tree/master/charts/nr-k8s-otel-collector/templates/configmap.yaml#L6-L485) 
2. Upgrade the release:
```
helm upgrade nr-k8s-otel-collector nr-k8s-otel-collector -n newrelic
```



## Common Errors

### Exporting Errors

Timeout errors while starting up the collector are expected as the collector attempts to establish a connection with NR. 
These timeout errors can also pop up over time as the collector is running but are transient and expected to self-resolve. Further improvements are underway to mitigate the amount of timeout errors we're seeing from the NR1 endpoint.

```
info	exporterhelper/retry_sender.go:154	Exporting failed. Will retry the request after interval.	{"kind": "exporter", "data_type": "metrics", "name": "otlphttp/newrelic", "error": "failed to make an HTTP request: Post \"https://staging-otlp.nr-data.net/v1/metrics\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)", "interval": "5.445779213s"}
```
