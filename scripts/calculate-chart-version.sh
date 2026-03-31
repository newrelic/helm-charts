#!/bin/bash
#
# Calculate next chart version based on conventional commits since last release
#
# Usage: ./calculate-chart-version.sh <CHART_PATH> <LAST_TAG>
#
# Example: ./calculate-chart-version.sh charts/nr-k8s-otel-collector nr-k8s-otel-collector-0.10.13
#
# This script analyzes conventional commit messages and determines the appropriate
# semantic version bump:
#   - BREAKING CHANGE: or feat!: -> MAJOR bump (1.0.0 -> 2.0.0)
#   - feat: -> MINOR bump (1.0.0 -> 1.1.0)
#   - fix: or chore: -> PATCH bump (1.0.0 -> 1.0.1)
#

set -e

CHART_PATH="${1:?Chart path is required}"
LAST_TAG="${2:-}"  # Allow empty tag (means no previous release)

# Get commits since last release for the specific chart
# If no last tag, get all commits for the chart
if [ -z "$LAST_TAG" ]; then
  commits=$(git log --format=%s -- ${CHART_PATH})
else
  commits=$(git log ${LAST_TAG}..HEAD --format=%s -- ${CHART_PATH})
fi

# If no commits, keep current version
if [ -z "$commits" ]; then
  current_version=$(yq '.version' ${CHART_PATH}/Chart.yaml)
  echo "$current_version"
  exit 0
fi

# Analyze commit types
has_breaking=false
has_feat=false
has_fix=false

while IFS= read -r commit; do
  # Check for BREAKING CHANGE in commit message or ! in type
  if [[ "$commit" =~ "BREAKING CHANGE:" ]] || [[ "$commit" =~ ^[a-z]+\!: ]]; then
    has_breaking=true
  # Check for feat: prefix (with or without [chart-name] prefix or scope)
  elif [[ "$commit" =~ ^feat: ]] || [[ "$commit" =~ ^\[.*\][[:space:]]feat: ]] || [[ "$commit" =~ ^feat\( ]]; then
    has_feat=true
  # Check for fix: or chore: prefix (with or without [chart-name] prefix or scope)
  elif [[ "$commit" =~ ^fix: ]] || [[ "$commit" =~ ^fix\( ]] || [[ "$commit" =~ ^chore: ]] || [[ "$commit" =~ ^chore\( ]] || [[ "$commit" =~ ^\[.*\][[:space:]]fix: ]] || [[ "$commit" =~ ^\[.*\][[:space:]]chore: ]]; then
    has_fix=true
  fi
done <<< "$commits"

# Get base version to bump from
# For weekly releases, we calculate the bump from the last released version (tag),
# not from the current Chart.yaml version (which may have been bumped but not released)
if [ -z "$LAST_TAG" ]; then
  # No previous release, use current Chart.yaml version as base
  base_version=$(yq '.version' ${CHART_PATH}/Chart.yaml)
else
  # Extract version from tag (e.g., "nr-k8s-otel-collector-0.10.14" -> "0.10.14")
  base_version=$(echo "$LAST_TAG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+$')
fi

IFS='.' read -r major minor patch <<< "$base_version"

# Calculate version bump based on commit types
if [[ "$has_breaking" == true ]]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [[ "$has_feat" == true ]]; then
  minor=$((minor + 1))
  patch=0
elif [[ "$has_fix" == true ]]; then
  patch=$((patch + 1))
else
  # No relevant commits, keep base version
  echo "$base_version"
  exit 0
fi

NEW_VERSION="${major}.${minor}.${patch}"
echo "$NEW_VERSION"
