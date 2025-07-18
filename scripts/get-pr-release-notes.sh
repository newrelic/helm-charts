#!/bin/bash

function main() {
  validate_args "$@"
  write_chart_release_notes $tagname "$@"
}

function validate_args() {
  if [[ $# -ne 2 ]]; then
    echo "Please provide commitish and a filename for release notes (e.g., ${0##*/} b0ccd56a195939d016df6139da944ee5b6e4bf05 RELEASE.md)"
    exit 1
  fi
}

function write_chart_release_notes() {
  commitish=$1
  release_file=$2
  echo GITHUB_TOKEN=$(echo "$GITHUB_TOKEN" | base64)
  # Given the commitish, we can get the PR number and then the PR body (no need to do fancy validation WOO HOO)
  gh_pr_body=$(gh pr list --search "$commitish" --state merged --json title,body,number | jq '.[0].body')
#  gh_pr_body=$(gh pr list --search "$commitish" --json title,body,number -R "dbudziwojskiNR/helm-charts" | jq '.[0].body' )

  # Extract the release notes from the PR body in a shell script
  if [[ "$gh_pr_body" =~ \<!--BEGIN-RELEASE-NOTES--\>[\\r\\n]*(.*)\<!--END-RELEASE-NOTES--\> ]]; then
      release_notes=${BASH_REMATCH[1]}
      echo $release_notes > $release_file
      echo "Release Notes: $release_notes"
  else
      echo "Missing release notes section in PR body."
  fi
}

main "$@"
