[![Community Plus header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Plus.png)](https://opensource.newrelic.com/oss-category/#community-plus)

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
You can have all the information about the installation in the [New Relic Documentation page for installaing the Kubernetes integration
using Helm](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/installation/install-kubernetes-integration-using-helm/)

Just as a glance of the process of installation and configuration the process involves to create a `values.yaml` that will look like this:
```yaml
global:
  licenseKey: YOUR_LICENSE_KEY
  cluster: YOUR_CLUSTER_NAME
kubeEvents:
  enabled: true
webhook:
  enabled: true
prometheus:
  enabled: true
logging:
  enabled: true
ksm:
  enabled: true
```

Add the official repository:
```sh
helm repo add newrelic https://helm-charts.newrelic.com
```

Then, run `helm upgrade`:
```shell
helm upgrade --install newrelic-bundle newrelic/nri-bundle -f your-custom-values.yaml
```

You can find a list of all the global values in the [`nri-bundle`'s README](charts/nri-bundle/README.md). There you can find also links
to the values of all the subcharts.

### <a name='Examples'></a>Examples

The following example installs the `nri-bundle` chart, which groups multiple New Relic charts into one. `nri-bundle` contains:

- [New Relic's Kubernetes integration][newrelic-kubernetes]
- [New Relic's Kubernetes plugin for logs][newrelic-logs]
- [New Relic's Prometheus OpenMetrics integration][newrelic-prometheus]
- [Metadata injection webhook][newrelic-webhook]
- [Kube state metrics][ksm]

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
Member
@paologallinaharbur paologallinaharbur 1 hour ago

This is still used by charts/synthetics-minion #729

Unless we want to "deprecate" it by removing the docs
@kang-makes

A [GitHub Personal Access Token][github-personal-access-token] for this repository is required. If you have the token, execute the following POST request (tailor `client_payload` to your needs):

`chart_name`: (required) Name of the helm chart to be bumped.
`chart_version`: (optional) If specified the chart version will be set with this value. If left empty the patch version of the chart will be bumped by 1, e.g: 1.2.19 -> 1.2.20
`app_version`: (required) Version of the application.

```sh
curl -H "Accept: application/vnd.github.everest-preview+json" \
     -H "Authorization: token <PERSONAL_ACCESS_TOKEN>" \
     --request POST \
     --data '{"event_type": "bump-chart-version", "client_payload": { "chart_name": "simple-nginx", "chart_version": "1.2.3", "app_version": "1.45.7"}}' \
     https://api.github.com/repos/newrelic/helm-charts/dispatches
```

Notice the sample `client_payload` object in the request body: the request generates a pull request for the `simple-nginx` chart to update `app_version` to `1.45.7` and `chart_version` to `1.2.3`.

## <a name='Testing'></a>Testing

See [chart testing](docs/chart_testing.md)

## <a name='Contributing'></a>Contributing

See [our Contributing docs](CONTRIBUTING.md) and our [review guidelines](docs/review_guidelines.md)

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

To all contributors, we thank you!  Without your contribution, this project would not be what it is today.


## <a name='Support'></a>Support

Should you need assistance with New Relic products, you are in good hands with several support diagnostic tools and support channels.

If the issue has been confirmed as a bug or is a feature request, file a GitHub issue.

**Support Channels**

* [New Relic Documentation](https://docs.newrelic.com): Comprehensive guidance for using our platform
* [New Relic Community](https://discuss.newrelic.com/c/support-products-agents/new-relic-infrastructure): The best place to engage in troubleshooting questions
* [New Relic Developer](https://developer.newrelic.com/): Resources for building a custom observability applications
* [New Relic University](https://learn.newrelic.com/): A range of online training for New Relic users of every level
* [New Relic Technical Support](https://support.newrelic.com/) 24/7/365 ticketed support. Read more about our [Technical Support Offerings](https://docs.newrelic.com/docs/licenses/license-information/general-usage-licenses/support-plan).

### <a name='IssuesEnhancementRequests'></a>Issues / Enhancement Requests

Issues and enhancement requests can be submitted in the [Issues tab of this repository](../../issues). Please search for and review the existing open issues before submitting a new issue.

## <a name='Troubleshoot'></a>Troubleshoot

### <a name='TroubleshootCannotLoadRepos'></a>Getting "Couldn't load repositories file" (Helm 2)

You need to initialize Helm with:
```sh
helm init
```

## <a name='License'></a>License

The project is released under version 2.0 of the [Apache license](http://www.apache.org/licenses/LICENSE-2.0).

[Artifact Hub]: https://artifacthub.io/packages/search?repo=newrelic
[helm-search]: https://helm.sh/docs/intro/using_helm/#helm-search-finding-charts
[helm-install]: https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
[newrelic-kubernetes]: https://docs.newrelic.com/docs/integrations/kubernetes-integration/get-started/introduction-kubernetes-integration
[newrelic-webhook]: https://docs.newrelic.com/docs/integrations/kubernetes-integration/link-your-applications/link-your-applications-kubernetes
[newrelic-prometheus]: https://docs.newrelic.com/docs/integrations/prometheus-integrations/get-started/new-relic-prometheus-openmetrics-integration-kubernetes
[newrelic-logs]: https://docs.newrelic.com/docs/logs/enable-logs/enable-logs/kubernetes-plugin-logs
[ksm]: https://github.com/kubernetes/kube-state-metrics
[installing-helm]: https://helm.sh/docs/intro/install/
[github-personal-access-token]: https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
