#!/usr/bin/env python3

import csv
import sys
import os
from github import Github, Auth
from typing import List


def get_pr_details(pr) -> List[str]:
    """Extract relevant details from a PR object."""
    created_at = pr.created_at
    merged_at = pr.merged_at

    # Calculate time difference if PR was merged
    time_opened_seconds = ""
    if merged_at:
        time_diff = merged_at - created_at
        time_opened_seconds = time_diff.total_seconds()

    return [
        str(pr.number),
        pr.title,
        created_at.isoformat(),
        pr.html_url,
        pr.user.login,
        str(pr.comments),
        str(pr.commits),
        merged_at.isoformat() if merged_at else "",
        pr.state,
        time_opened_seconds,
    ]


def main():
    # Repository URL
    REPO_URL = "https://github.com/RedHatInsights/insights-results-aggregator"
    LIMIT = 500

    auth = Auth.Token(os.getenv("GITHUB_TOKEN"))
    g = Github(auth=auth)

    owner, repo = REPO_URL.split("github.com/")[1].split("/")

    repository = g.get_repo(f"{owner}/{repo}")
    pull_requests = repository.get_pulls(state="all")[:LIMIT]

    # CSV header
    header = [
        "pr_id",
        "title",
        "date_created",
        "url",
        "author",
        "comments",
        "commits",
        "mergedAt",
        "state",
        "time_opened_seconds",
    ]

    # Write to CSV
    writer = csv.writer(sys.stdout)
    writer.writerow(header)

    for pr in pull_requests:
        writer.writerow(get_pr_details(pr))


if __name__ == "__main__":
    main()
