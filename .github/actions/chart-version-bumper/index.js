const core = require('@actions/core');
const github = require('@actions/github');
const path = require('path');
const { bumpChartVersion } = require('./bump_chart_version.js');

function locateChartsDir() {
  // Locate the charts dir from this file: 
  // => remove the 3 parts: [.github, actions, chart-version-bumper], add [charts]
  // TODO: fix it, quite ugly
  return path.join(__dirname, '/..', '/..', '/..', 'charts');
}

try {
  const chartName = core.getInput('chart_name');
  const chartVersion = core.getInput('chart_version');
  const appVersion = core.getInput('app_version');

  console.log(`Bumping chart ${chartName} to version ${chartVersion} with app version: ${appVersion}`);
  
  const chartsDir = locateChartsDir()
  const chartPath =  `${chartsDir}/${chartName}/Chart.yaml`
  const changes = bumpChartVersion(chartPath, chartVersion, appVersion);

  core.setOutput("changes", changes);
} catch (error) {
  core.setFailed(error.message);
}