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

### No such file or directory 

Sometimes we see failed to open file errors on the `filelog` and `hostmetrics` receiver because of a race condition where the file or directory no longer exists, as the pod or process was ephemeral (e.g. a cronjob, sleep) and the pod or process was terminated before the collector could read the file. 

`filelog` error: 
```
Failed to open file	{"kind": "receiver", "name": "filelog", "data_type": "logs", "component": "fileconsumer", "error": "open /var/log/pods/<podname>/<containername>/0.log: no such file or directory"}
``` 
`hostmetrics` error:
```
Error scraping metrics	{"kind": "receiver", "name": "hostmetrics", "data_type": "metrics", "error": "error reading <metric> for process \"<process>\" (pid <PID>): open /hostfs/proc/<PID>/stat: no such file or directory; error reading <metric> info for process \"<process>\" (pid 511766): open /hostfs/proc/<PID>/<metric>: no such file or directory", "scraper": "process"}
```