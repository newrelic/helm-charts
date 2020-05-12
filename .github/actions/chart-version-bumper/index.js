import { getInput, setOutput, setFailed } from '@actions/core';
import { context } from '@actions/github';

try {
  const chartName = getInput('chart_name');
  console.log(`Bumping version of ${chartName}!`);

  const time = (new Date()).toTimeString();
  setOutput("time", time);

  // Get the JSON webhook payload for the event that triggered the workflow
  const payload = JSON.stringify(context.payload, undefined, 2)
  console.log(`The event payload: ${payload}`);
} catch (error) {
  setFailed(error.message);
}