#!/bin/bash -e

REPOS=(
    "dvo-extractor"
    "insights-ccx-messaging"
    "insights-results-aggregator"
    "insights-behavioral-spec"
    "insights-results-aggregator-utils"
    "insights-results-aggregator-mock"
    "insights-content-template-renderer"
    "insights-operator-gathering-conditions-service"
    "insights-results-aggregator-exporter"
    "ccx-notification-writer"
    "ccx-notification-service"
    "insights-results-aggregator-cleaner"
    "insights-results-smart-proxy"
    "insights-content-service"
)

CLONED_REPOS_FOLDER="/Users/jdiazsua/Documents/Projects"
OWNERORG="RedHatInsights"
FORKOWNER="juandspy"
CURR_DIR=$(pwd)
FILE_TO_UPLOAD="dependabot-automerge.yml"
FOLDER_IN_THE_REPO=".github/workflows"
JIRA_TASK="CCXDEV-12378"
REASON="to automerge the dependabot pull requests"

for repo in "${REPOS[@]}"
do
    repo_path="$CLONED_REPOS_FOLDER/$repo"
    if [ -d "$repo_path" ]; then
        echo "$repo_path exists"
    else
        echo "$repo_path doesn't exist. Cloning it"
        (
            cd $CLONED_REPOS_FOLDER
            git clone git@github.com:$OWNERORG/$repo.git
        )
    fi

    (
        cd "$repo_path"
        default_branch=$(git remote show origin | grep "HEAD branch" | sed 's/.*: //')
        git checkout "$default_branch"
        git pull origin "$default_branch"
        if [ -f "$FOLDER_IN_THE_REPO/$FILE_TO_UPLOAD" ]; then
            echo "[WARNING] Skipping $repo because file exists"
            continue
        fi

        if ! git remote -v | grep -q "fork"; then
            echo "[WARNING] Fork not found. Forking the repo..."
            gh repo set-default https://github.com/$OWNERORG/$repo
            gh repo fork
            git remote add fork git@github.com:$FORKOWNER/$repo
        fi

        git branch -D "$JIRA_TASK" || true
        git checkout -b "$JIRA_TASK"
        mkdir -p "$FOLDER_IN_THE_REPO"
        cp "$CURR_DIR/$FILE_TO_UPLOAD" "$FOLDER_IN_THE_REPO/$FILE_TO_UPLOAD"
        git add "$FOLDER_IN_THE_REPO/$FILE_TO_UPLOAD"
        git commit -m "[${JIRA_TASK}] Add $FILE_TO_UPLOAD $REASON"
        git push fork "${JIRA_TASK}" -f
        gh pr create --fill --head "$FORKOWNER:$JIRA_TASK" || true
    )
    echo "-------------"
done
