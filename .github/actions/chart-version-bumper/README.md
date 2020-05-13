# Chart version bumper

Chart version bumper is a Github Action that increases the Chart & App version of a given chart hosted in this repository.

## Inputs

### `chart_name`

**Required** The name of the chart, in the `<repo_root>/charts/` directory

### `chart_version`

**Required** The (new) version of the chart.

### `app_version`

**Required** The (new) version of the app that the Helm chart contains

## Outputs

### `verboseChangeString` 

The changes that were made, in a human readable string, usable for pull request or slack messages

### `changeString`

The changes that were made, in a single line, usable for PR titles or commit messages
