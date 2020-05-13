# New Relic Helm charts repository

Official Helm charts for New Relic's products or other charts developed by New Relic.

## Installing charts

The official New Relic helm charts repository is indexed at
[Helm Hub][helm-hub], there you can find the list of available charts and their
documentation. 

To install the Helm CLI follow the instruction of their [official
documentation][installing-helm].

To install the New Relic Helm charts, first, you need to add the repository:

```
helm repo add newrelic https://helm-charts.newrelic.com
```

You can list all the available charts from the `newrelic` repository with the 
[`helm search`][helm-search] command:

```
helm search repo | grep newrelic/
```

To install one of the charts just run the [`helm install`][helm-install]
command specifying the name of the chart to install and the values you want to
set. You can find a list of all the values and their defaults in the
documentation of each chart.

The following example installs the `nri-bundle` chart, which groups multiple
New Relic charts into one. It contains:

- [The Kubernetes integration][newrelic-kubernetes].
- [Metadata injection webhook][newrelic-webhook].
- [Prometheus OpenMetrics integration][newrelic-prometheus].
- [Kubernetes plugin for logs][newrelic-logs].
- [Kube state metrics][ksm].

**Helm 3**
```
helm install newrelic-bundle newrelic/nri-bundle \
  --set global.licenseKey=YOUR_LICENSE_KEY \
  --set global.cluster=YOUR_CLUSTER_NAME \
  --set kubeEvents.enabled=true \
  --set webhook.enabled=true \
  --set prometheus.enabled=true \
  --set logging.enabled=true \
  --set ksm.enabled=true
```

**Helm 2**
```
helm install newrelic/nri-bundle \
  --name newrelic-bundle \
  --set global.licenseKey=YOUR_LICENSE_KEY \
  --set global.cluster=YOUR_CLUSTER_NAME \
  --set kubeEvents.enabled=true \
  --set webhook.enabled=true \
  --set prometheus.enabled=true \
  --set logging.enabled=true \
  --set ksm.enabled=true
```

## Developing a chart

You can use the Helm CLI to develop a chart in this repository.

1. [Install Helm][installing-helm]
1. Add/modify the files for the desired chart
1. Run `helm install dev-chart charts/<YOUR_CHART>` to install it locally.
   Feel free to add different values to the chart if you wish so.
1. Verify if the chart works as expected.
1. Remove the installed chart with `helm uninstall dev-chart`.
1. Create your pull request and follow the instructions below.

### Contributing

Please view [our contributing docs](CONTRIBUTING.md) for more information.

### Automated version bumps

This repository is configured to accept webhook requests to automatically bump chart versions. If it receives a version bump request, a Github Action will prepare a pull request that contains the requested changes. The PR has to be manually merged after this.

#### Trigger an automated version bump

A repo scoped [GitHub Personal Access Token][github-personal-access-token] is required.

If you have the Personal Access token, execute the following HTTP POST request:

```
curl -H "Accept: application/vnd.github.everest-preview+json" \
 -H "Authorization: token <PERSONAL_ACCESS_TOKEN>" \
 --request POST \
 --data '{"event_type": "bump-chart-version", "client_payload": { "chart_name": "simple-nginx", "chart_version": "1.2.3", "app_version": "1.45.7"}}' \
 https://api.github.com/repos/newrelic-experimental/helm-charts/dispatches
```

Notice the `client_payload` object inside the request body. This specific request will prepare a PR for the `simple-nginx` chart, to update the `app_version` to `1.45.7`, and `chart_version` to `1.2.3`. 

You can configure the client_payload accordingly.


[helm-hub]: https://hub.helm.sh/charts/newrelic
[helm-search]: https://helm.sh/docs/intro/using_helm/#helm-search-finding-charts
[helm-install]: https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
[newrelic-kubernetes]: https://docs.newrelic.com/docs/integrations/kubernetes-integration/get-started/introduction-kubernetes-integration
[newrelic-webhook]: https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-your-applications/link-your-applications-kubernetes
[newrelic-prometheus]: https://docs.newrelic.com/docs/integrations/prometheus-integrations/get-started/new-relic-prometheus-openmetrics-integration-kubernetes
[newrelic-logs]: https://docs.newrelic.com/docs/logs/enable-logs/enable-logs/kubernetes-plugin-logs
[ksm]: https://github.com/kubernetes/kube-state-metrics
[installing-helm]: https://helm.sh/docs/intro/install/
[github-personal-access-token]: https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line