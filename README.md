# New Relic Helm charts repository

This repository intends to host official Helm charts for New Relic's products or other charts developed by New Relic.

## Developing a chart

You can use the Helm CLI to develop a chart in this repository.

1. [Install Helm](https://helm.sh/docs/intro/install/)
2. Add/modify the files for the desired chart
3. Run `helm install dev-chart charts/<YOUR_CHART>` to install it locally.
   Feel free to add different values to the chart if you wish so.
4. Verify if the chart works as expected.
5. Remove the installed chart with `helm uninstall dev-chart`

### Contributing

Please view [our contributing docs](CONTRIBUTING.md) for more information.


