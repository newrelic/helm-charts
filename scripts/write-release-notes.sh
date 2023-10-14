#!/usr/bin/env bash

function main() {
  validate_args "$@"
  setup "$@"

  # Process bundled charts
  while [ `find . -name \*.tgz -or -name \*.tar.gz | wc -l` -gt 0 ]; do
find . -name \*.tgz -or -name \*.tar.gz | while read chart; do
  filename=$(basename $chart)
  tagname=$(echo "$filename" | sed 's/\.tgz$//' | sed 's/\.tar\.gz$//')
  tar --extract --gunzip --file "$chart" -C $(dirname "$chart")
  write_chart_release_notes $tagname "$@"
  rm "$chart"
done
  done

  teardown
}

function validate_args() {
  if [[ $# -ne 2 ]]; then
echo "Please provide filename for release notes and Slack announcement (e.g., ${0##*/} RELEASE.md RELEASE.slack)"
exit 1
  fi
}

function setup() {
  release_file=$1
  slack_file=$2

  # Setup charts
  cd charts/nri-bundle
  helm dependency build .

  # Setup release file
  echo "# 🚀 Changes" >> $release_file
  echo "" >> $release_file

  # Setup Slack file
  echo "🚀 Latest Releases" >> $slack_file
  echo "" >> $slack_file

  # Remove charts that we do not include in the release notes
  cd charts
  rm -f kube-state-metrics-*
  rm -f newrelic-logging-*
  rm -f newrelic-pixie-*
  rm -f nri-prometheus-*
  rm -f pixie-operator-chart-*
  cd ..
}

function teardown() {
  rm -rf charts/
  cd ../..
}

function write_chart_release_notes() {
  tagname=$1
  release_file=$2
  slack_file=$3

  # Process found chart
  cd charts
  while [ `find . -mindepth 1 -maxdepth 1 -type d | sed 's#./##' | wc -l` -gt 0 ]; do
find . -mindepth 1 -maxdepth 1 -type d | sed 's#./##' | while read folderName; do
  echo "Processing $folderName"
  repository=""
  appVersion=""

  # Scrape values
  case "$folderName" in
newrelic-prometheus-agent)
repository=$(cat ${folderName}/values.yaml| yq '.images.configurator.repository')
appVersion=$(cat ${folderName}/Chart.yaml| yq '.annotations.configuratorVersion')
;;
newrelic-infrastructure | nri-kube-events)
repository=$(cat ${folderName}/values.yaml| yq '.images.integration.repository')
appVersion=$(cat ${folderName}/Chart.yaml| yq '.appVersion')
;;
newrelic-infra-operator | newrelic-k8s-metrics-adapter | nri-metadata-injection)
repository=$(cat ${folderName}/values.yaml| yq '.image.repository')
appVersion=$(cat ${folderName}/Chart.yaml| yq '.appVersion')
;;
*)
echo "Unknown chart $folderName"
;;
  esac

  chartUrl="https://github.com/${repository}/releases/tag/${tagname}"
  appUrl="https://github.com/${repository}/releases/tag/v${appVersion}"

  # Write release notes
  echo "## ${tagname}" >> ../$release_file
  echo "- [Chart ${tagname} release notes](${chartUrl})" >> ../$release_file
  echo "- [App ${repository} v${appVersion} release notes](${appUrl})" >> ../$release_file
  echo "" >> ../$release_file

  # Write Slack announcement
  echo "✅ ${tagname}" >> ../$slack_file
  echo "<${chartUrl}|Chart ${tagname} release notes>" >> ../$slack_file
  echo "<${appUrl}|App ${repository} v${appVersion} release notes>" >> ../$slack_file
  echo "" >> ../$slack_file

  rm -rf $folderName
done
  done
  cd ..
}

main "$@"
