# Utility functions for dealing with multiple gitlab repositories

## Listing the open PRs for a given set of repos

Use `./list-repos-prs.sh` with a list of repos in a YAML format (like
[repos.yaml](../ansible-utils/playbooks/vars/repos.yaml)). This will generate
a CSV you can then convert to Markdown using `csv2md`
(https://github.com/lzakharov/csv2md).

For example:

```
./gitlab-utils/list-repos-prs.sh > gitlab-utils/open-prs.csv
echo "# Open Pull Requests" > gitlab-utils/open-prs.md && csv2md gitlab-utils/open-prs.csv >> gitlab-utils/open-prs.md
```
