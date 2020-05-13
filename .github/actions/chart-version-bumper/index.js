const core = require('@actions/core');
const fs = require('fs');
const path = require('path');
const { bumpChartVersion } = require('./bump_chart_version.js');

function locateChartsDir() {
  // Locate the charts dir from this file: 
  // => remove the 3 parts: [.github, actions, chart-version-bumper], add [charts]
  // TODO: fix it, quite ugly
  return path.join(__dirname, '/..', '/..', '/..', 'charts');
}

// stringifyChanges creates human readable messages from the changes array
function stringifyChanges(chartName, changes) {
  var changeString = changes
.map(change => `${change.field} to ${change.to}`)
.join(" and ");
  changeString = `[charts/${chartName}] Automatically bumped ${changeString}`;

  var verboseChangeString = `[charts/${chartName}] the following changes were done:`;
  for (const {field, from, to} of changes) {
verboseChangeString += `\n - **${field}** bumped from **${from}** to **${to}**`;
  }

  return {changeString, verboseChangeString};
}

try {
  // Retrieve all input needed
  const chartName = core.getInput('chart_name');
  const chartVersion = core.getInput('chart_version');
  const appVersion = core.getInput('app_version');

  console.log(`Bumping chart ${chartName} to version ${chartVersion} with app version: ${appVersion}`);
  
  const chartsDir = locateChartsDir();
  const chartPath =  `${chartsDir}/${chartName}/Chart.yaml`;
  const chartYAML = fs.readFileSync(chartPath, 'utf8');

  const {changes, newYAML} = bumpChartVersion(chartYAML, chartVersion, appVersion);

  if (changes.length == 0) {
// Make sure the pipeline stops if no changes were made
core.setFailed("Current Chart versions are already up to date. Aborting pipeline.");
return
  }

  // write the changed doc to disk
  fs.writeFileSync(chartPath, newYAML);
  
  const {changeString, verboseChangeString} = stringifyChanges(chartName, changes);

  core.setOutput("changeString", changeString);
  core.setOutput("verboseChangeString", verboseChangeString);
} catch (error) {
  core.setFailed(error.message);
}