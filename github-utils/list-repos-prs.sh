#!/bin/bash
set -euo pipefail  # Exit on any error, undefined variable or failed pipeline

REPOS_FILE="ansible-utils/playbooks/vars/repos.yaml"

# CSV header
echo "repo,pr_id,title,date_created,url,author"

# Filter by only the github repos
yq -o=json '.repos | to_entries | map(select(.value.source == "github"))' "$REPOS_FILE" \
  | jq -c '.[]' | while read -r line; do
    repo_key=$(echo "$line" | jq -r '.key')
    full_url=$(echo "$line" | jq -r '.value.url')

    repo_path=$(echo "$full_url" | sed -E 's|https://github.com/||' | sed 's|.git$||')

    gh pr list \
      --repo "$repo_path" \
      --state open \
      --limit 100 \
      --json number,title,createdAt,url,author \
      | jq -r --arg r "$repo_key" '.[] | [$r, .number, .title, .createdAt, .url, .author.login] | @csv'
done
