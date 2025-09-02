#!/bin/bash

# Usage:
# ./gabi_to_csv.sh "SELECT org_id,account_number,cluster,updated_at FROM new_reports LIMIT 4"


# Check if API_TOKEN is set
if [ -z "$API_TOKEN" ]; then
    echo "Error: API_TOKEN environment variable is not set"
    echo "Please set it with: export API_TOKEN='your_token_here'"
    echo "You can get the token from the cluster UI: https://gitlab.cee.redhat.com/service/app-interface/-/blob/master/docs/app-sre/sop/gabi-instances-request.md#access-gabi-instances"
    exit 1
fi

# Check if query is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"SQL_QUERY\" [output_file.csv]"
    echo "Example: $0 \"SELECT org_id,account_number,cluster,updated_at FROM new_reports LIMIT 4\""
    echo "Example: $0 \"SELECT * FROM new_reports LIMIT 10\" results.csv"
    exit 1
fi

QUERY="$1"
OUTPUT_FILE="${2:-}"

# API endpoint
API_URL="https://gabi-ccx-data-pipeline-stage.apps.crcs02ue1.urby.p1.openshiftapps.com/query"

# Execute query and convert to CSV
if [ -n "$OUTPUT_FILE" ]; then
    # Save to file
    curl -H "Authorization: Bearer $API_TOKEN" \
         -H "Content-Type: application/json" \
         -X POST "$API_URL" \
         -d "{\"query\": \"$QUERY\"}" -s | \
    jq -r '.result[] | @csv' > "$OUTPUT_FILE"
    echo "Results saved to $OUTPUT_FILE"
else
    # Output to stdout with markdown formatting
    curl -H "Authorization: Bearer $API_TOKEN" \
         -H "Content-Type: application/json" \
         -X POST "$API_URL" \
         -d "{\"query\": \"$QUERY\"}" -s | \
    jq -r '.result[] | @csv' | csv2md
fi
