# pipeline-control-gateway

Bootstraps New Relic [Pipeline Control](https://newrelic.com/platform/pipeline-control).

## Fixed Service IP

By default Kubernetes picks the ClusterIP of the gateway Service. Set `service.clusterIP` to use a fixed address, for example to keep a DNS record valid after the Service is re-created:

```yaml
service:
  clusterIP: 10.96.0.50
```

| Value | Default | Description |
| --- | --- | --- |
| `service.clusterIP` | `""` | Fixed ClusterIP of the Service. Empty lets Kubernetes choose. |

The address must be free and inside the cluster's service range. `clusterIP` cannot be changed on an existing Service: delete the Service once and let the release re-create it.
