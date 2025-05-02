#!/bin/bash

# This file prints a to-do list for checking or adding codecov badges using
# Notion or markdown tasks format.

set -euo pipefail  # Exit on any error, undefined variable or failed pipeline

REPOS_FILE="ansible-utils/playbooks/vars/repos.yaml"

# Filter by only the GitHub repos
yq -o=json '.repos | to_entries | map(select(.value.source == "github"))' "$REPOS_FILE" \
  | jq -c '.[]' | while read -r line; do
    repo_key=$(echo "$line" | jq -r '.key')
    full_url=$(echo "$line" | jq -r '.value.url')
    default_branch=$(echo "$line" | jq -r '.value.default_branch')

    # Remove "https://github.com/" and ".git" if present
    repo_path=$(echo "$full_url" | sed -E 's|https://github.com/||' | sed 's|.git$||')

    # Download the README.md to a temporary file
    temp_readme=$(mktemp)
    curl -s "https://raw.githubusercontent.com/$repo_path/refs/heads/$default_branch/README.md" -o "$temp_readme"

    # Check if README.md contains "codecov"
    if grep -qi "codecov" "$temp_readme"; then
        echo "- [ ] Update/fix/check codecov for $full_url"
        echo "  - [ ] Check the coverage is up to date"
        echo "  - [ ] Add the codecov.io token to the settings"
        echo "  - [ ] Add the codecov.io token to the GH Action"
    else
        echo "- [ ] Add [![codecov](https://codecov.io/gh/$repo_path/branch/$default_branch/graph/badge.svg)](https://codecov.io/gh/$repo_path) to $full_url"
    fi

    # Clean up the temporary file
    rm "$temp_readme"

done
