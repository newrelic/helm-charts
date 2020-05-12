# Contributing Guidelines

The Kubernetes Charts project accepts contributions via GitHub pull requests. This document outlines the process to help get your contribution accepted.

## Contributor's License Agreement (CLA)

To be able to contribute to the New Relic Helm charts repository you have to sign a CLA.
The CLA signature process is handled by a bot and is presented to the contributor as a
check in the pull request.

If you didn't sign the CLA yet, follow the procedures in the comment of the bot to do
so.

## How to contribute to an existing chart

1. Fork this repository, develop and test your chart's changes.
1. Ensure your Chart changes follow the [technical](#technical-requirements) and [documentation](#documentation-requirements) guidelines, described below.
1. Submit a pull request.
1. Automated builds will run for testing and linting.
1. A code review will automaticallly be requested by the owners of the chart.
1. The PR is reviewed, merged and the chart is automatically released.

***NOTE***: In order to make testing and merging of PRs easier, please submit changes to multiple charts in separate PRs.

### Technical requirements

* All Chart dependencies should also be submitted independently
* Must pass the linter (`helm lint`)
* Must successfully launch with default values (`helm install .`)
    * All pods go to the running state (or NOTES.txt provides further instructions if a required value is missing).
    * All services have at least one endpoint
* Must include source GitHub repositories for images used in the Chart
* Images should not have any major security vulnerabilities
* Must be up-to-date with the latest stable Helm/Kubernetes features
    * Use Deployments in favor of ReplicationControllers
* Should follow Kubernetes best practices
    * Include Health Checks wherever practical
    * Allow configurable [resource requests and limits](http://kubernetes.io/docs/user-guide/compute-resources/#resource-requests-and-limits-of-pod-and-container)
* Provide a method for data persistence (if applicable)
* Support application upgrades
* Allow customization of the application configuration
* Provide a secure default configuration
* Do not leverage alpha features of Kubernetes
* Includes a [NOTES.txt](https://helm.sh/docs/topics/charts/#chart-license-readme-and-notes) explaining how to use the application after install
* Follows [best practices](https://helm.sh/docs/chart_best_practices/)
  (especially for [labels](https://helm.sh/docs/chart_best_practices/labels/)
  and [values](https://helm.sh/docs/chart_best_practices/values/))

### Documentation requirements

* Must include an in-depth `README.md`, including:
    * Short description of the Chart
    * Any prerequisites or requirements
    * Customization: explaining options in `values.yaml` and their defaults
* Must include a short `NOTES.txt`, including:
    * Any relevant post-installation information for the Chart
    * Instructions on how to access the application or service provided by the Chart

### Pull request approval and release process

A Github Workflow will run to lint and test the chart's installation.

A maintainer of the chart will review the changes and eventually approve them. Any change requires at least one review.
No pull requests can be merged until at least one maintainer reviews it. A good guide for what to review
can be found in the [Review Guidelines](REVIEW_GUIDELINES.md).

Once the Chart has been merged, the release will be automatically made by a Github Workflwo using the Github Pages of this repository.

## Support Channels

Whether you are a user or contributor, official support channels include:

- GitHub issues: https://github.com/newrelic-experimental/charts/issues

Before opening a new issue or submitting a new pull request, it's helpful to search the project - it's likely that another user has already reported the issue you're facing, or it's a known issue that we're already aware of.
