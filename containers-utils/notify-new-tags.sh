#!/bin/bash

# Default values
DEFAULT_LAST_TAG_FILE="/tmp/last_quay_tag.txt"
DEFAULT_CHECK_INTERVAL=60  # Check every minute (60 seconds)

# Function to display usage instructions
usage() {
    echo "Usage: $0 --repo-url REPO_URL [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  --repo-url REPO_URL    Full Quay.io repository URL to monitor"
    echo ""
    echo "Optional:"
    echo "  --last-tag-file FILE   Path to store last known tag (default: $DEFAULT_LAST_TAG_FILE)"
    echo "  --check-interval SECS  Seconds between checks (default: $DEFAULT_CHECK_INTERVAL)"
    echo "  --help                 Show this help message"
    exit 1
}

# Parse command-line arguments
REPO_URL=""
LAST_TAG_FILE="$DEFAULT_LAST_TAG_FILE"
CHECK_INTERVAL="$DEFAULT_CHECK_INTERVAL"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --last-tag-file)
            LAST_TAG_FILE="$2"
            shift 2
            ;;
        --check-interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required repo-url
if [ -z "$REPO_URL" ]; then
    echo "Error: Repository URL is required"
    usage
fi

# Extract organization and repository from the URL
REPO_PATH=$(echo "$REPO_URL" | sed -n 's|https://quay.io/repository/\(.*\)|\1|p')

# Function to send notifications
send_notification() {
    local new_digest="$1"
    
    # Optional: Visual notification
    osascript -e 'display notification "New image digest: '"$new_digest"'" with title "Quay.io Update"'
    
    # Optional: Log to console
    echo "$(date): New image digest detected - $new_digest"
}

# Check for new tags
check_new_tags() {
    # Use curl to fetch the latest tag and its manifest digest
    local latest_tag_info=$(curl -s "https://quay.io/api/v1/repository/$REPO_PATH/tag/" | \
        jq -r '.tags[0]')
    
    # Extract manifest digest
    local current_digest=$(echo "$latest_tag_info" | jq -r '.manifest_digest')
    
    # Check if last known digest file exists
    if [ ! -f "$LAST_TAG_FILE" ]; then
        echo "$current_digest" > "$LAST_TAG_FILE"
        return
    fi
    
    # Compare current digest with last known digest
    local last_digest=$(cat "$LAST_TAG_FILE")
    
    if [ "$current_digest" != "$last_digest" ]; then
        send_notification "$current_digest"
        echo "$current_digest" > "$LAST_TAG_FILE"
    fi
}

# Continuous monitoring
echo "Starting continuous monitoring of Quay.io image tags..."
echo "Repository URL: $REPO_URL"
echo "Repository Path: $REPO_PATH"
echo "Last tag file: $LAST_TAG_FILE"
echo "Check interval: $CHECK_INTERVAL seconds"

while true; do
    check_new_tags
    echo "Waiting $CHECK_INTERVAL seconds before next check..."
    sleep $CHECK_INTERVAL
done