# Charts Testing

## Pull Request Testing

Pull request testing is done by running [Helm's Chart Testing Action](https://github.com/helm/chart-testing) automatically.
It will lint the chart and install it in a cluster created using [Kubernetes in Docker (KIND)](https://github.com/kubernetes-sigs/kind).

### Procedure

The Helm's Chart Testing Action will run the [ct lint-and-install](https://github.com/helm/chart-testing/blob/master/doc/ct_lint-and-install.md) command.
This is the main logic for validation of a pull request. It intends to only test charts that have changed in this PR.

The testing logic has been extracted to the [chart-testing](https://github.com/helm/chart-testing) project. A go library provides the required logic to lint, install, and test charts.
It is provided as a Docker image and can be run by anyone on their own charts.

### Providing Custom Test Values

Testing charts with default values may not be suitable in all cases. For instance, charts may require some values to be set which should not be part of the chart's default `values.yaml` (such as keys etc.). Furthermore, it is often desirable to test a chart with different configurations, reflecting different use cases (e.g. setting a password instead of using the default generated one, activating persistence instead of using the default emptyDir volume, etc.).

In order to enable custom test values, create a directory `ci` in the chart's directory and add any number of `*-values.yaml` files to this directory. Only files with a suffix `-values.yaml` are considered. Instead of using the defaults, the chart is then installed and tested separately for each of these files using the `--values` flag.

Please note that in order to test using the default values when using the `ci` directory, an empty values file must be present in the directory.

For examples, you can take a look at existing tests in this repository (e.g. [Simple Nginx chart](charts/simple_nginx)).

Please also note that it is a different concept than "[Helm Chart Test](https://github.com/helm/helm/blob/master/docs/chart_tests.md)", although the Helm Chart test, if defined, will be run by this test tool for each test values.
