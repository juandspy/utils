#!/bin/bash

# Script to check for resource limit/request patterns in deploy folders
# Usage: ./check-deploy-resources.sh [repos_yaml_file]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FUNCTIONS="$SCRIPT_DIR/common-functions.sh"

# Source common functions
if [[ ! -f "$COMMON_FUNCTIONS" ]]; then
    echo "Error: common-functions.sh not found at $COMMON_FUNCTIONS" >&2
    exit 1
fi
source "$COMMON_FUNCTIONS"

# Default repos YAML file
REPOS_YAML="${1:-$SCRIPT_DIR/../ansible-utils/playbooks/vars/repos.yaml}"

# Patterns to search for
PATTERNS=(
    "CPU_REQUEST"
    "CPU_LIMIT"
    "MEM_REQUEST"
    "MEMORY_REQUEST"
    "MEM_LIMIT"
    "MEMORY_LIMIT"
)

# Temporary directory for clones
CLONE_BASE_DIR="${TMPDIR:-/tmp}/deploy-resources-check"
mkdir -p "$CLONE_BASE_DIR"

# Output file for table
TABLE_OUTPUT_FILE="table.out"

# Function to search for patterns in a file
search_patterns_in_file() {
    local file_path="$1"
    local found_patterns=()
    
    # Use grep with -oE to extract actual matched strings
    # Pattern matches variable names containing our search patterns
    # e.g., IRA_CPU_LIMIT, DB_WRITER_CPU_REQUEST, etc.
    for pattern in "${PATTERNS[@]}"; do
        # Extract all matches for this pattern (full variable names)
        while IFS= read -r match; do
            # Add to array if not already present
            local already_found=false
            if [[ ${#found_patterns[@]} -gt 0 ]]; then
                for existing in "${found_patterns[@]}"; do
                    if [[ "$existing" == "$match" ]]; then
                        already_found=true
                        break
                    fi
                done
            fi
            if [[ "$already_found" == "false" ]]; then
                found_patterns+=("$match")
            fi
        done < <(grep -oE "[A-Z0-9_]*${pattern}[A-Z0-9_]*" "$file_path" 2>/dev/null | sort -u)
    done
    
    if [[ ${#found_patterns[@]} -gt 0 ]]; then
        # Sort and join with spaces
        printf '%s\n' "${found_patterns[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//'
    fi
}

# Function to escape CSV field (quote if contains comma, quote, or newline)
escape_csv_field() {
    local field="$1"
    # If field contains comma, quote, or newline, wrap in quotes and escape quotes
    if [[ "$field" =~ [,$\"$'\n'] ]]; then
        # Escape quotes by doubling them
        field=$(echo "$field" | sed 's/"/""/g')
        echo "\"$field\""
    else
        echo "$field"
    fi
}

# Function to format CSV output
print_table_header() {
    echo "REPO NAME,FILE URL,OCCURRENCE" > "$TABLE_OUTPUT_FILE"
}

print_table_row() {
    local repo_name="$1"
    local file_url="$2"
    local occurrence="$3"
    
    # Escape each field for CSV
    local escaped_repo=$(escape_csv_field "$repo_name")
    local escaped_url=$(escape_csv_field "$file_url")
    local escaped_occurrence=$(escape_csv_field "$occurrence")
    
    echo "${escaped_repo},${escaped_url},${escaped_occurrence}" >> "$TABLE_OUTPUT_FILE"
}

# Main execution
main() {
    print_status "Starting deploy folder resource pattern analysis..."
    
    # Initialize table output file
    > "$TABLE_OUTPUT_FILE"
    
    # Extract repository list
    print_status "Extracting repository list from $REPOS_YAML"
    local repos=($(extract_repos "$REPOS_YAML"))
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_error "No repositories found in YAML file"
        exit 1
    fi
    
    print_success "Found ${#repos[@]} repositories to analyze"
    
    # Print table header
    print_table_header
    
    # Process each repository
    for repo in "${repos[@]}"; do
        print_status "Processing repository: $repo"
        
        local repo_url=$(get_repo_url "$repo" "$REPOS_YAML")
        local default_branch=$(get_default_branch "$repo" "$REPOS_YAML")
        local repo_dir="$CLONE_BASE_DIR/$repo"
        
        if [[ -z "$repo_url" ]]; then
            print_warning "Could not find URL for repository: $repo"
            print_table_row "$repo" "URL not found" "N/A"
            continue
        fi
        
        # Clone or update repository
        if [[ -d "$repo_dir" ]]; then
            print_status "Repository $repo already exists, updating..."
            # (cd "$repo_dir" && git fetch origin "$default_branch" 2>/dev/null && git checkout "$default_branch" 2>/dev/null && git reset --hard "origin/$default_branch" 2>/dev/null) || print_warning "Failed to update $repo"
        else
            print_status "Cloning $repo from $repo_url..."
            if ! git clone --depth 1 --branch "$default_branch" "$repo_url" "$repo_dir" 2>/dev/null; then
                print_error "Failed to clone $repo"
                print_table_row "$repo" "Clone failed" "N/A"
                continue
            fi
        fi
        
        # Find files in deploy folder
        local deploy_dir="$repo_dir/deploy"
        if [[ ! -d "$deploy_dir" ]]; then
            print_warning "Deploy folder not found in $repo"
            continue
        fi
        
        # Search for patterns in all files under deploy folder
        while IFS= read -r -d '' file; do
            local relative_path="${file#$repo_dir/}"
            local patterns_found=$(search_patterns_in_file "$file")
            
            if [[ -n "$patterns_found" ]]; then
                local file_url=$(get_file_url "$repo_url" "$default_branch" "$relative_path")
                print_table_row "$repo" "$file_url" "$patterns_found"
            fi
        done < <(find "$deploy_dir" -type f -print0 2>/dev/null)
    done
    
    print_success "Analysis complete!"
}

# Run main function
main

