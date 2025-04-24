# Utility functions for dealing with multiple git repositories

## Adding a file to multiple repos

Edit any variable in the shell script. Then run it this way:

```shell
./add-file-to-repos.sh 2>&1 | tee out.log
```

and find the URLs to the PRs created using grep:

```shell
grep -E 'https:\/\/github\.com\/RedHatInsights\/.*\/pull\/.*' out.log
```

You can also use `./check-pr-checks.sh` to generate a CSV with the status of each PR.

## Commenting on multiple PRs

You can use `./comment-on-prs.sh`. Modify the search query and comment.

## Add collaborator to the repos

Use `./add-admin-repos.sh`

## Listing the open PRs for a given set of repos

Use `./list-repos-prs.sh` with a list of repos in a YAML format (like
[repos.yaml](../ansible-utils/playbooks/vars/repos.yaml)). This will generate
a CSV you can then convert to Markdown using `csv2md`
(https://github.com/lzakharov/csv2md).

For example:

```
./github-utils/list-repos-prs.sh > github-utils/open-prs.csv
 echo "# Open Pull Requests" > github-utils/open-prs.md && csv2md github-utils/open-prs.csv >> github-utils/open-prs.md
```