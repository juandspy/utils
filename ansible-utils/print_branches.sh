#!/bin/bash

# Script to print the default branch for each repository using yq
# Assumes a flat structure in inventory.yaml where keys are repo names.

set -euo pipefail

# Corrected input file path relative to workspace root
input_file="ansible-utils/inventory.yaml"

if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found at $input_file" >&2
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo "Error: yq command not found. Please install yq (https://github.com/mikefarah/yq)" >&2
    exit 1
fi

echo "Repository Default Branch"
echo "---------------------------------------- --------------" # Adjusted separator length

# Use yq to extract repository names (top-level keys)
yq eval 'keys | .[]' "$input_file" | while read -r repo_name; do
    # Extract the URL using the repo name directly under the root
    url=$(yq eval ".$repo_name.url" "$input_file")

    if [ -z "$url" ]; then
        echo "Warning: URL not found for $repo_name" >&2
        continue
    fi

    # Get the default branch
    # Redirect stderr to avoid cluttering the output for repos without a symref or other git errors
    branch=$(git ls-remote --symref "$url" HEAD 2>/dev/null | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2; exit }')

    # Handle cases where the branch couldn't be determined
    if [ -z "$branch" ]; then
        branch="<unknown>"
    fi

    # Print the result, formatting the repo name
    printf "%-40s %s\n" "$repo_name" "$branch"
done

exit 0 