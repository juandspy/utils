#!/bin/bash -ex

REPOS=(
    "insights-results-aggregator"
    "insights-behavioral-spec"
    "insights-results-aggregator-utils"
    "insights-results-aggregator-mock"
    "dvo-extractor"
    "insights-content-template-renderer"
    "insights-operator-gathering-conditions-service"
    "insights-results-aggregator-exporter"
    "ccx-notification-writer"
    "ccx-notification-service"
    "insights-results-aggregator-cleaner"
    "insights-ccx-messaging"
    "insights-results-smart-proxy"
    "insights-content-service"
)

OWNERORG="RedHatInsights"
AUTHOR="app/dependabot"

SEARCH_QUERY="author:$AUTHOR"
COMMENT="@dependabot recreate"

for repo in "${REPOS[@]}"
do
    export GH_PAGER=cat
    pr_list=$(gh pr list --search $SEARCH_QUERY --repo https://github.com/$OWNERORG/$repo --json url)
    urls=$(echo $pr_list | jq -r '.[] | .url')
    for url in $urls
    do
        gh pr comment --body="$COMMENT" $url
    done
done