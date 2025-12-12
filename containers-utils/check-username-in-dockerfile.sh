#!/bin/bash

# Script to check for non-root users in Dockerfiles across repositories
# Based on repos.yaml configuration

set -e

# Configuration
CLONE_BASE_DIR="/tmp/dockerfile_check"
REPOS_YAML="/Users/jdiazsua/Documents/Projects/utils/ansible-utils/playbooks/vars/repos.yaml"
OUTPUT_FILE="dockerfile_users_report.csv"

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

# Function to find Dockerfile/Containerfile
find_dockerfile() {
    local repo_dir="$1"
    local dockerfile=""
    
    # Check for common Dockerfile names
    for file in "Dockerfile" "Containerfile" "dockerfile" "containerfile"; do
        if [[ -f "$repo_dir/$file" ]]; then
            dockerfile="$file"
            break
        fi
    done
    
    # Check for Dockerfile in subdirectories
    if [[ -z "$dockerfile" ]]; then
        dockerfile=$(find "$repo_dir" -name "Dockerfile" -o -name "Containerfile" -o -name "dockerfile" -o -name "containerfile" | head -1 | xargs basename 2>/dev/null || echo "")
    fi
    
    echo "$dockerfile"
}

# Function to extract users from Dockerfile
extract_users() {
    local dockerfile_path="$1"
    local users=""
    
    if [[ ! -f "$dockerfile_path" ]]; then
        echo "No Dockerfile found"
        return
    fi
    
    # Extract USER instructions
    local user_instructions=$(grep -i "^USER" "$dockerfile_path" 2>/dev/null || echo "")
    
    # Extract useradd commands
    local useradd_commands=$(grep -i "useradd" "$dockerfile_path" 2>/dev/null || echo "")
    
    # Extract RUN commands that might create users
    local run_user_commands=$(grep -i "RUN.*useradd\|RUN.*adduser" "$dockerfile_path" 2>/dev/null || echo "")
    
    # Combine all user-related information
    local all_users=""
    if [[ -n "$user_instructions" ]]; then
        all_users="$user_instructions"
    fi
    if [[ -n "$useradd_commands" ]]; then
        all_users="${all_users}${all_users:+ | }$useradd_commands"
    fi
    if [[ -n "$run_user_commands" ]]; then
        all_users="${all_users}${all_users:+ | }$run_user_commands"
    fi
    
    if [[ -z "$all_users" ]]; then
        echo "No user configuration found"
    else
        echo "$all_users"
    fi
}

# Function to get Dockerfile URL
get_dockerfile_url() {
    local repo_name="$1"
    local repo_url="$2"
    local default_branch="$3"
    local dockerfile_path="$4"
    
    # Convert SSH URLs to HTTPS for GitHub/GitLab
    local web_url="$repo_url"
    if [[ "$repo_url" == git@github.com:* ]]; then
        web_url=$(echo "$repo_url" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
    elif [[ "$repo_url" == git@gitlab.cee.redhat.com:* ]]; then
        web_url=$(echo "$repo_url" | sed 's|git@gitlab.cee.redhat.com:|https://gitlab.cee.redhat.com/|' | sed 's|\.git$||')
    fi
    
    # Construct the URL to the Dockerfile
    if [[ "$dockerfile_path" == "NONE" ]]; then
        echo "No Dockerfile found"
    else
        if [[ "$web_url" == https://github.com/* ]]; then
            echo "${web_url}/blob/${default_branch}/${dockerfile_path}"
        else
            echo "${web_url}/-/blob/${default_branch}/${dockerfile_path}"
        fi
    fi
}

# Main execution
main() {
    print_status "Starting Dockerfile user analysis..."
    
    # Create output directory
    mkdir -p "$CLONE_BASE_DIR"
    
    # Initialize CSV output
    echo "repo,filename,users,dockerfile_url" > "$OUTPUT_FILE"
    
    # Extract repository list (limit to first 3 for testing)
    print_status "Extracting repository list from $REPOS_YAML"
    local repos=($(extract_repos "$REPOS_YAML"))
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        print_error "No repositories found in YAML file"
        exit 1
    fi
    
    print_success "Found ${#all_repos[@]} total repositories, analyzing first ${#repos[@]} repositories"
    
    # Process each repository
    for repo in "${repos[@]}"; do
        print_status "Processing repository: $repo"
        
        local repo_url=$(get_repo_url "$repo" "$REPOS_YAML")
        local default_branch=$(get_default_branch "$repo" "$REPOS_YAML")
        local repo_dir="$CLONE_BASE_DIR/$repo"
        
        if [[ -z "$repo_url" ]]; then
            print_warning "Could not find URL for repository: $repo"
            echo "$repo,ERROR,URL not found,No URL available" >> "$OUTPUT_FILE"
            continue
        fi
        
        # Clone repository
        if [[ -d "$repo_dir" ]]; then
            print_status "Repository $repo already exists, updating..."
            # (cd "$repo_dir" && git pull origin "$default_branch" 2>/dev/null) || print_warning "Failed to update $repo"
        else
            print_status "Cloning $repo from $repo_url..."
            if ! git clone "$repo_url" "$repo_dir" 2>/dev/null; then
                print_error "Failed to clone $repo"
                echo "$repo,ERROR,Clone failed,No URL available" >> "$OUTPUT_FILE"
                continue
            fi
        fi
        
        # Find Dockerfile
        local dockerfile=$(find_dockerfile "$repo_dir")
        if [[ -z "$dockerfile" ]]; then
            print_warning "No Dockerfile found in $repo"
            local dockerfile_url=$(get_dockerfile_url "$repo" "$repo_url" "$default_branch" "NONE")
            echo "$repo,NONE,No Dockerfile found,\"$dockerfile_url\"" >> "$OUTPUT_FILE"
            continue
        fi
        
        # Extract users
        local users=$(extract_users "$repo_dir/$dockerfile")
        
        # Get Dockerfile URL
        local dockerfile_url=$(get_dockerfile_url "$repo" "$repo_url" "$default_branch" "$dockerfile")
        
        # Output results
        echo "$repo,$dockerfile,\"$users\",\"$dockerfile_url\"" >> "$OUTPUT_FILE"
        
    done
    
    print_success "Analysis complete! Results saved to $OUTPUT_FILE"
    
    # Display summary table
    print_status "Summary:"
    echo ""
    echo "Repository | Dockerfile | Users | Dockerfile URL"
    echo "-----------|------------|-------|----------------"
    tail -n +2 "$OUTPUT_FILE" | while IFS=',' read -r repo filename users dockerfile_url; do
        printf "%-10s | %-10s | %s | %s\n" "$repo" "$filename" "$users" "$dockerfile_url"
    done
    
    # Cleanup option
    echo ""
    read -p "Do you want to clean up cloned repositories? (y/N): " cleanup
    if [[ "$cleanup" =~ ^[Yy]$ ]]; then
        print_status "Cleaning up cloned repositories..."
        rm -rf "$CLONE_BASE_DIR"
        print_success "Cleanup complete"
    else
        print_status "Repositories kept in $CLONE_BASE_DIR"
    fi
}

# Run main function
main "$@"
