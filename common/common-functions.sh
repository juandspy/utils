#!/bin/bash

# Common functions for repository analysis scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to extract repos from YAML file
extract_repos() {
    local yaml_file="$1"
    if [[ ! -f "$yaml_file" ]]; then
        print_error "Repos YAML file not found: $yaml_file"
        exit 1
    fi
    
    # Check if yq is available
    if ! command -v yq &> /dev/null; then
        print_error "yq is required but not installed. Please install yq first."
        exit 1
    fi
    
    # Extract repo names using yq
    yq eval '.repos | keys | .[]' "$yaml_file"
}

# Function to get repo URL from YAML
get_repo_url() {
    local repo_name="$1"
    local yaml_file="$2"
    yq eval ".repos.${repo_name}.url" "$yaml_file"
}

# Function to get default branch from YAML
get_default_branch() {
    local repo_name="$1"
    local yaml_file="$2"
    yq eval ".repos.${repo_name}.default_branch" "$yaml_file"
}

# Function to convert SSH repo URL to HTTPS web URL
convert_repo_url_to_web() {
    local repo_url="$1"
    local web_url="$repo_url"
    
    # Convert SSH URLs to HTTPS for GitHub/GitLab
    if [[ "$repo_url" == git@github.com:* ]]; then
        web_url=$(echo "$repo_url" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
    elif [[ "$repo_url" == git@gitlab.cee.redhat.com:* ]]; then
        web_url=$(echo "$repo_url" | sed 's|git@gitlab.cee.redhat.com:|https://gitlab.cee.redhat.com/|' | sed 's|\.git$||')
    fi
    
    echo "$web_url"
}

# Function to get file URL (generic function for GitHub/GitLab)
get_file_url() {
    local repo_url="$1"
    local default_branch="$2"
    local file_path="$3"
    local not_found_message="${4:-No file found}"
    
    # Convert SSH URLs to HTTPS for GitHub/GitLab
    local web_url=$(convert_repo_url_to_web "$repo_url")
    
    # Construct the URL to the file
    if [[ "$file_path" == "NONE" ]] || [[ -z "$file_path" ]]; then
        echo "$not_found_message"
    else
        if [[ "$web_url" == https://github.com/* ]]; then
            echo "${web_url}/blob/${default_branch}/${file_path}"
        else
            echo "${web_url}/-/blob/${default_branch}/${file_path}"
        fi
    fi
}

# Function to get raw file URL (for fetching file content)
get_raw_file_url() {
    local repo_url="$1"
    local default_branch="$2"
    local file_path="$3"
    
    # Convert SSH URLs to HTTPS for GitHub/GitLab
    local web_url=$(convert_repo_url_to_web "$repo_url")
    
    # Construct the raw file URL
    local raw_url=""
    if [[ "$web_url" == https://github.com/* ]]; then
        raw_url="${web_url}/raw/${default_branch}/${file_path}"
    else
        raw_url="${web_url}/-/raw/${default_branch}/${file_path}"
    fi
    
    echo "$raw_url"
}

