# Contributing

Contributions are always welcome. Before contributing please read the
[code of conduct](./CODE_OF_CONDUCT.md) and [search the issue tracker](https://github.com/newrelic/helm-charts/issues); your issue may have already been discussed or fixed in `master`. To contribute, [fork](https://help.github.com/articles/fork-a-repo/) this repository, commit your changes, and [send a Pull Request](https://help.github.com/articles/using-pull-requests/).

Note that our [code of conduct](./CODE_OF_CONDUCT.md) applies to all platforms and venues related to this project; please follow it in all your interactions with the project and its participants.

## Feature requests

Feature requests should be submitted in the [Issue tracker](../../issues), with a description of the expected behavior & use case, where they'll remain closed until sufficient interest, [e.g. :+1: reactions](https://help.github.com/articles/about-discussions-in-issues-and-pull-requests/), has been [shown by the community](../../issues?q=label%3A%22votes+needed%22+sort%3Areactions-%2B1-desc).

Before submitting an Issue, please search for similar ones in the [closed issues](../../issues?q=is%3Aissue+is%3Aclosed+label%3Aenhancement).

## Pull requests

### Requirements

* Check our [review guidelines](./docs/review_guidelines.md).
* Ensure your change adhere to the [technical and documentation requirements](./docs/requirements.md).
* Open separate pull requests to submit changes to multiple charts.

### Approval and release process

Pull requests approvals go through the following steps:

1. A GitHub action is triggered to lint and test the chart's installation. For more information, see [Chart testing](./docs/chart_testing.md).
2. A maintainer [reviews](./docs/review_guidelines.md) the changes. Any change requires at least one review.
3. The pull request can be merged when at least one maintainer approves it.

Once the chart has been merged, it is automatically released.

## Contributor License Agreement

Keep in mind that when you submit your pull request, you'll need to sign the [CLA](./cla.md) via the click-through using CLA-Assistant. If you'd like to execute our corporate CLA, or if you have any questions, please drop us an email at opensource@newrelic.com.

For more information about CLAs, please check out Alex Russell's excellent post,
["Why Do I Need to Sign This?"](https://infrequently.org/2008/06/why-do-i-need-to-sign-this/).
