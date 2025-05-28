# Charts testing

## Pull request testing

Pull request testing is done by running [Helm's Chart Testing](https://github.com/helm/chart-testing) automatically, which lints the chart and installs it in a cluster created using [Kubernetes in Docker (KIND)](https://github.com/kubernetes-sigs/kind).

The Helm's Chart Testing action runs [ct lint-and-install](https://github.com/helm/chart-testing/blob/master/doc/ct_lint-and-install.md). This is the main logic for validating pull requests. Only charts that have changed are tested.

Testing logic has been extracted from the [chart-testing](https://github.com/helm/chart-testing) project, a Go library that provides utilities to lint, install, and test charts. Its Docker image can be run by anyone on their own charts.

## Custom test values

Testing charts with default values may not always be suitable. For example, some charts may require values that are not part of the chart's default `values.yaml` (such as keys). Furthermore, it is often desirable to test a chart with different configurations, reflecting different use cases (for example, setting a password instead of using the default generated one, activating persistence instead of using the default `emptyDir volume`, etc.).

To enable custom test values, create a directory named `ci` in the chart's directory and add any number of `*-values.yaml` files to it Only files with the suffix `-values.yaml` are considered. Instead of using defaults, the chart is installed and tested separately for each files using `--values`.

For examples, take a look at the existing tests in this repository.

>To use default test values, an empty `values` file must be present in the `ci` directory.

## Running tests locally

- Install Helm's 'chart-testing' utilities
  - `brew install chart-testing`
  - `brew install yamllint`
  - `helm plugin install https://github.com/helm-unittest/helm-unittest`
- Run linter and yaml validation
  - `ct lint-and-install`
- Run unit tests: 
  - `helm unittest charts/newrelic-logging`
