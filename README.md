[![New Relic Experimental header](https://github.com/newrelic/open-source-office/raw/master/examples/categories/images/Experimental.png)](https://github.com/newrelic/open-source-office/blob/master/examples/categories/index.md#new-relic-experimental)

# New Relic's Helm charts repository

This is the official Helm charts repository for New Relic. It is indexed at [Helm Hub][helm-hub], where you can find the list of available charts and their documentation.

<!-- vscode-markdown-toc -->
* [Prerequisites](#Prerequisites)
* [Install](#Installthecharts)
* [Development](#Development)
* [Testing](#Testing)
* [Contributing](#Contributing)
* [Support](#Support)
* [License](#License)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## <a name='Prerequisites'></a>Prerequisites

* Helm CLI ([install instructions][installing-helm])
* New Relic account

## <a name='Installthecharts'></a>Install

To install the New Relic Helm charts, add the official repository first:

```sh
helm repo add newrelic https://helm-charts.newrelic.com
```

You can list all the available charts from the `newrelic` repository using [`helm search`][helm-search]:

```sh
helm search repo newrelic/
```

To install one of the charts, run [`helm install`][helm-install] passing the name of the chart to install and the values you want to set as arguments. You can find a list of all the values and their defaults in the documentation of each chart.

### <a name='Examples'></a>Examples

The following example installs the `nri-bundle` chart, which groups multiple New Relic charts into one. `nri-bundle` contains:

- [New Relic's Kubernetes integration][newrelic-kubernetes]
- [New Relic's Kubernetes plugin for logs][newrelic-logs]
- [New Relic's Prometheus OpenMetrics integration][newrelic-prometheus]
- [Metadata injection webhook][newrelic-webhook]
- [Kube state metrics][ksm]

#### <a name='Installnri-bundleusingHelm3'></a>Install `nri-bundle` using Helm 3
```sh
helm install newrelic-bundle newrelic/nri-bundle \
  --set global.licenseKey=YOUR_LICENSE_KEY \
  --set global.cluster=YOUR_CLUSTER_NAME \
  --set kubeEvents.enabled=true \
  --set webhook.enabled=true \
  --set prometheus.enabled=true \
  --set logging.enabled=true \
  --set ksm.enabled=true
```

#### <a name='Installnri-bundleusingHelm2'></a>Install `nri-bundle` using Helm 2
```sh
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

## <a name='Development'></a>Development

You can use the [Helm CLI][installing-helm] to develop a chart and add it to this repository.

1. Clone this repository on your local machine.
2. Add or modify the files for the desired chart.
3. To install the chart locally, run `helm install dev-chart charts/<YOUR_CHART>` 
4. Verify that the chart works as expected.
5. Remove the installed chart with `helm uninstall dev-chart`.
6. Create your pull request and follow the instructions below.

> Feel free to add different values to the chart.

### <a name='Automatedversionbumps'></a>Automated version bumps

This repository is configured to accept webhook requests to bump chart versions. Upon receiving a version bump request, a GitHub Action generates a pull request with the requested changes. The pull request must still be merged manually.

#### <a name='Triggeranautomatedversionbump'></a>Trigger an automated version bump

A [GitHub Personal Access Token][github-personal-access-token] for this repository is required. If you have the token, execute the following POST request (tailor `client_payload` to your needs):

```sh
curl -H "Accept: application/vnd.github.everest-preview+json" \
 -H "Authorization: token <PERSONAL_ACCESS_TOKEN>" \
 --request POST \
 --data '{"event_type": "bump-chart-version", "client_payload": { "chart_name": "simple-nginx", "chart_version": "1.2.3", "app_version": "1.45.7"}}' \
 https://api.github.com/repos/newrelic-experimental/helm-charts/dispatches
```

Notice the sample `client_payload` object in the request body: the request generates a pull request for the `simple-nginx` chart to update `app_version` to `1.45.7` and `chart_version` to `1.2.3`.

## <a name='Testing'></a>Testing

See [chart testing](docs/chart_testing.md)

## <a name='Contributing'></a>Contributing

See [our Contributing docs](CONTRIBUTING.md) and our [review guidelines](docs/review_guidelines.md)

## <a name='Support'></a>Support

### <a name='IssuesEnhancementRequests'></a>Issues / Enhancement Requests

Issues and enhancement requests can be submitted in the [Issues tab of this repository](../../issues). Please search for and review the existing open issues before submitting a new issue.

## <a name='License'></a>License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).

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
