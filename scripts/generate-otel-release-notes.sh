#!/bin/bash
#
# Generate release notes for nr-k8s-otel-collector from git commits between tags.
#
# Usage: ./generate-otel-release-notes.sh <current_tag> <prev_tag> <output_file>
#
# Example: ./generate-otel-release-notes.sh nr-k8s-otel-collector-0.12.0 nr-k8s-otel-collector-0.11.0 RELEASE.md
#

set -e

CHART_PATH="charts/nr-k8s-otel-collector"

function main() {
  if [[ $# -ne 3 ]]; then
    echo "Usage: ${0##*/} <current_tag> <prev_tag> <output_file>"
    exit 1
  fi

  local current_tag="$1"
  local prev_tag="$2"
  local output_file="$3"

  generate_changelog "$current_tag" "$prev_tag" "$output_file"
}

function strip_conventional_prefix() {
  local subject="$1"
  local repo="${GITHUB_REPOSITORY:-newrelic/helm-charts}"
  # Strip optional [bracket-prefix] (e.g. "[nr-k8s-otel-collector] ")
  subject=$(echo "$subject" | sed -E 's/^\[[^]]*\][[:space:]]*//')
  # Strip conventional commit type: feat(scope)!: or feat!: or feat: (hyphens allowed in type for e.g. "nr-k8s-otel-collector:")
  subject=$(echo "$subject" | sed -E 's/^[a-z][a-z0-9-]*(\([^)]*\))?!?:[[:space:]]*//')
  # Capitalize first letter (awk used for bash 3.2 compatibility on macOS)
  subject=$(echo "$subject" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  # Convert (#1234) to linked PR reference
  echo "$subject" | sed -E "s|\\(#([0-9]+)\\)|([#\1](https://github.com/${repo}/pull/\1))|g"
}

function generate_changelog() {
  local current_tag="$1"
  local prev_tag="$2"
  local output_file="$3"

  echo "Generating changelog: ${prev_tag}..${current_tag}"

  # Get commits touching the chart between tags, excluding the bot version bump commit
  local commits
  commits=$(git log "${prev_tag}..${current_tag}" \
    --pretty=format:"%s" \
    --no-merges \
    -- "${CHART_PATH}" | \
    grep -v "^chore(nr-k8s-otel-collector): bump version" || true)

  {
    echo "## 🚀 What's Changed"
    echo ""

    if [ -z "$commits" ]; then
      echo "No user-facing changes since ${prev_tag}"
    else
      while IFS= read -r subject; do
        local description
        description=$(strip_conventional_prefix "$subject")
        echo "* ${description}"
      done <<< "$commits"
    fi

    echo ""
    echo "**Full Changelog**: https://github.com/${GITHUB_REPOSITORY:-newrelic/helm-charts}/compare/${prev_tag}...${current_tag}"
  } > "$output_file"

  echo "Release notes written to ${output_file}:"
  cat "$output_file"
}

main "$@"
