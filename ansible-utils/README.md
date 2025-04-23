# Ansible utils

## Prerequisites

Install ansible with `pipx install ansible`. Maybe you need to run
```
$ export PATH="$PATH:/Users/jdiazsua/.local/pipx/venvs/ansible/bin"
```
if you are on MacOS.

## Running playbooks

```
$ ansible-playbook playbooks/update_repos.yaml
```