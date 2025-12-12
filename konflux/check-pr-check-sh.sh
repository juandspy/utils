#!/bin/bash

# Script to check for pr_check.sh files in repositories
# Based on repos.yaml configuration

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the utils root directory (parent of script directory)
UTILS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source common functions
source "${UTILS_ROOT}/common/common-functions.sh"

# Configuration
REPOS_YAML="/Users/jdiazsua/Documents/Projects/utils/ansible-utils/playbooks/vars/repos.yaml"
OUTPUT_FILE="pr_check_sh_report.csv"
MARKDOWN_FILE="${SCRIPT_DIR}/pr-checks.md"

# Function to check if file exists at URL
check_file_exists() {
    local url="$1"
    
    # Try with redirect following first (hypothesis A: redirects)
    local http_code_with_redirect=$(curl -sL -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    # Also check without redirect following for comparison
    local http_code_no_redirect=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    # Check for redirect codes or success codes
    if [[ "$http_code_with_redirect" == "200" ]] || [[ "$http_code_with_redirect" == "301" ]] || [[ "$http_code_with_redirect" == "302" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get file URL (wrapper around common get_file_url)
get_pr_check_url() {
    local repo_url="$1"
    local default_branch="$2"
    local file_path="$3"
    get_file_url "$repo_url" "$default_branch" "$file_path" "No pr_check.sh found"
}

# Main execution
main() {
    print_status "Starting pr_check.sh file analysis..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Check if csv2md is available
    if ! command -v csv2md &> /dev/null; then
        print_error "csv2md is required but not installed. Please install csv2md first."
        exit 1
    fi
    
    # Initialize CSV output
    echo "repo,file_path,file_url" > "$OUTPUT_FILE"
    
    # Extract repository list
    print_status "Extracting repository list from $REPOS_YAML"
    local repos=($(extract_repos "$REPOS_YAML"))
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_error "No repositories found in YAML file"
        exit 1
    fi
    
    print_success "Found ${#repos[@]} repositories to analyze"
    
    # Process each repository
    for repo in "${repos[@]}"; do
        print_status "Processing repository: $repo"
        
        local repo_url=$(get_repo_url "$repo" "$REPOS_YAML")
        local default_branch=$(get_default_branch "$repo" "$REPOS_YAML")
        
        if [[ -z "$repo_url" ]]; then
            print_warning "Could not find URL for repository: $repo"
            echo "$repo,ERROR,URL not found" >> "$OUTPUT_FILE"
            continue
        fi
        
        # Check if pr_check.sh exists in root directory
        local file_path="pr_check.sh"
        local raw_url=$(get_raw_file_url "$repo_url" "$default_branch" "$file_path")
        
        if check_file_exists "$raw_url"; then
            print_success "Found pr_check.sh in $repo"
            local file_url=$(get_pr_check_url "$repo_url" "$default_branch" "$file_path")
            echo "$repo,\"$file_path\",\"$file_url\"" >> "$OUTPUT_FILE"
        else
            print_warning "No pr_check.sh found in $repo"
            local file_url=$(get_pr_check_url "$repo_url" "$default_branch" "NONE")
            echo "$repo,NONE,\"$file_url\"" >> "$OUTPUT_FILE"
        fi
        
    done
    
    print_success "Analysis complete! Results saved to $OUTPUT_FILE"
    
    # Generate markdown report
    print_status "Generating markdown report..."
    echo "# PR Check Script Report" > "$MARKDOWN_FILE"
    echo "" >> "$MARKDOWN_FILE"
    csv2md "$OUTPUT_FILE" >> "$MARKDOWN_FILE"
    print_success "Markdown report saved to $MARKDOWN_FILE"
    
    # Display summary table
    print_status "Summary:"
    echo ""
    echo "Repository | File Path | File URL"
    echo "-----------|-----------|----------"
    tail -n +2 "$OUTPUT_FILE" | while IFS=',' read -r repo file_path file_url; do
        printf "%-10s | %-20s | %s\n" "$repo" "$file_path" "$file_url"
    done
}

# Run main function
main "$@"

