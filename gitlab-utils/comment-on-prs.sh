#!/bin/bash -ex

REPOS=(
    "ccx-data-pipeline"
)

OWNERORG="ccx"

SEARCH_QUERY="Update+dependency"
COMMENT="/retest"

for repo in "${REPOS[@]}"
do
    BASE_URL="https://gitlab.cee.redhat.com/api/v4/projects/$OWNERORG%2F$repo"
    pr_list=$(curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$BASE_URL/merge_requests?search=$SEARCH_QUERY")
    urls=$(echo $pr_list | jq -r '.[] | .web_url')
    for url in $urls
    do
        MERGE_REQUEST_ID=$(echo $url | awk -F'/' '{print $NF}')
        curl --location \
            --request POST "$BASE_URL/merge_requests/$MERGE_REQUEST_ID/notes" \
            --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            --header "Content-Type: application/json" \
            --data-raw "{ \"body\": \"$COMMENT\" }"
        sleep 120
    done
done