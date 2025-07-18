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

  # Given the commitish, we can get the PR number and then the PR body
  gh_pr_body=$(gh pr list --search "$commitish" --state merged --json title,body,number | jq '.[0].body')

  # Extract the release notes from the PR body using well-known tags
  if [[ "$gh_pr_body" =~ \<!--BEGIN-RELEASE-NOTES--\>[\\r\\n]*(.*)\<!--END-RELEASE-NOTES--\> ]]; then
      release_notes=${BASH_REMATCH[1]}
      printf '%b' "$release_notes" > $release_file
      echo "Release Notes: $release_notes"
  else
      echo "Missing or malformed release notes section in PR body."
      exit 1
  fi
}

main "$@"
