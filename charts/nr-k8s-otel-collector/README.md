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



