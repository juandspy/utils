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
USERNAME="InsightsDroid"
PERMISSION="write"

# For each repo, create a table with the permissions
for repo in "${REPOS[@]}"
do
    permission=$(gh api "repos/$OWNERORG/$repo/collaborators/$USERNAME/permission" | jq '.permission' -r)
    echo "$USERNAME has $permission permission in $OWNERORG/$repo"

    if [ "$permission" != "write" ]; then
        out=$(gh api \
            --method=PUT \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            repos/$OWNERORG/$repo/collaborators/$USERNAME \
            -f permission=$PERMISSION | jq '.message' -r)
        if [ "$out" == "Not Found" ]; then
            echo "You don't have enough permissions to add $USERNAME to $repo"
        else
            echo "$USERNAME now has write permissions in $OWNERORG/$repo"
            echo $out
        fi
    fi
    echo "---------------------"
done