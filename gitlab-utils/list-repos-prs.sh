#!/bin/bash
set -euo pipefail

REPOS_FILE="ansible-utils/playbooks/vars/repos.yaml"

# CSV header
echo "repo,pr_id,title,date_created,url,author"

yq -o=json '.repos | to_entries | map(select(.value.source == "gitlab"))' "$REPOS_FILE" \
  | jq -c '.[]' | while read -r line; do
    repo_key=$(echo "$line" | jq -r '.key')
    full_url=$(echo "$line" | jq -r '.value.url')

    if [[ "$full_url" =~ ^git@ ]]; then
      repo_path=$(echo "$full_url" | sed -E 's|git@gitlab[^:]*:||' | sed 's|.git$||')
    else
      repo_path=$(echo "$full_url" | sed -E 's|https://gitlab[^/]+/||' | sed 's|.git$||')
    fi

    glab mr list \
      --repo "$full_url" \
      -F json \
      --per-page 100 \
      | jq -r --arg r "$repo_key" '.[] | select(.state == "opened") | [$r, .iid, .title, .created_at, .web_url, .author.username] | @csv'
done