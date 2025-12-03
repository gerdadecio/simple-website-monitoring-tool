#!/bin/bash

# Website Status Checker - Enhanced Version with Config File Support
# This script checks the status of multiple endpoints and outputs JSON

# Config file location
CONFIG_FILE="/usr/local/etc/monitor-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="./config.json"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Output file - write to nginx html directory if it exists, otherwise current directory
if [ -d "/usr/share/nginx/html" ]; then
    OUTPUT_FILE="/usr/share/nginx/html/status.json"
else
    OUTPUT_FILE="status.json"
fi

# Read timeout from config (default to 10 if not found)
TIMEOUT=$(grep -oE '"requestTimeoutSeconds"\s*:\s*[0-9]+' "$CONFIG_FILE" | grep -oE '[0-9]+' | head -1)
TIMEOUT=${TIMEOUT:-10}

# Get current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "Starting status check at $TIMESTAMP"
echo "Reading configuration from $CONFIG_FILE"

# Count endpoints
ENDPOINT_COUNT=$(grep -c '"name"' "$CONFIG_FILE")
echo "Checking $ENDPOINT_COUNT endpoints..."

# Start JSON array
echo "[" > "$OUTPUT_FILE"

# Parse the config file and process each endpoint
CURRENT_INDEX=0

# Extract each endpoint block and process
while IFS= read -r line; do
    if [[ "$line" =~ \"name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        NAME="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ \"baseUrl\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        BASE_URL="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ \"pingEndpoint\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        PING_ENDPOINT="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ \"versionEndpoint\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        VERSION_ENDPOINT="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ \"loginEndpoint\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        LOGIN_ENDPOINT="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ \"homeEndpoint\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
        HOME_ENDPOINT="${BASH_REMATCH[1]}"

        # When we have all fields, process the endpoint
        if [ ! -z "$NAME" ] && [ ! -z "$BASE_URL" ]; then
            echo "Checking: $NAME ($BASE_URL)"

            # Construct ping URL
            PING_URL="${BASE_URL}${PING_ENDPOINT}"

            # Create temporary files for headers and body
            HEADER_FILE=$(mktemp)
            BODY_FILE=$(mktemp)

            # Use curl to fetch HTTP status code, response time, headers, and body from ping endpoint
            RESPONSE=$(curl -D "$HEADER_FILE" -o "$BODY_FILE" -s -w "%{http_code}|%{time_total}" --max-time "$TIMEOUT" -L "$PING_URL" 2>&1)
            CURL_EXIT_CODE=$?

            if [ $CURL_EXIT_CODE -eq 0 ]; then
                # Parse the response
                HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
                RESPONSE_TIME=$(echo "$RESPONSE" | cut -d'|' -f2)

                # Convert response time from seconds to milliseconds
                RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000 / 1" | bc)

                # Construct version URL
                VERSION_URL="${BASE_URL}${VERSION_ENDPOINT}"
                VERSION_RESPONSE=$(curl -s --max-time "$TIMEOUT" -L "$VERSION_URL")

                # The version endpoint returns plain text, so just capture it directly
                # Trim whitespace and newlines
                VERSION=$(echo "$VERSION_RESPONSE" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

                # If empty or failed, set to N/A
                if [ -z "$VERSION" ]; then
                    VERSION="N/A"
                fi
            else
                # Handle error
                HTTP_CODE="ERROR"
                RESPONSE_TIME_MS="0"
                VERSION="N/A"
            fi

            # Clean up temporary files
            rm -f "$HEADER_FILE" "$BODY_FILE"

            # Build JSON object for this endpoint
            if [ $CURRENT_INDEX -gt 0 ]; then
                echo "  }," >> "$OUTPUT_FILE"
            fi

            echo "  {" >> "$OUTPUT_FILE"
            echo "    \"name\": \"$NAME\"," >> "$OUTPUT_FILE"
            echo "    \"url\": \"$BASE_URL\"," >> "$OUTPUT_FILE"
            echo "    \"status_code\": \"$HTTP_CODE\"," >> "$OUTPUT_FILE"
            echo "    \"response_time\": $RESPONSE_TIME_MS," >> "$OUTPUT_FILE"
            echo "    \"timestamp\": \"$TIMESTAMP\"," >> "$OUTPUT_FILE"
            echo "    \"version\": \"$VERSION\"," >> "$OUTPUT_FILE"
            echo "    \"login_url\": \"${BASE_URL}${LOGIN_ENDPOINT}\"," >> "$OUTPUT_FILE"
            echo "    \"home_url\": \"${BASE_URL}${HOME_ENDPOINT}\"" >> "$OUTPUT_FILE"

            CURRENT_INDEX=$((CURRENT_INDEX + 1))

            # Reset variables for next iteration
            NAME=""
            BASE_URL=""
            PING_ENDPOINT=""
            VERSION_ENDPOINT=""
            LOGIN_ENDPOINT=""
            HOME_ENDPOINT=""
        fi
    fi
done < "$CONFIG_FILE"

# Close the last object and array
if [ $CURRENT_INDEX -gt 0 ]; then
    echo "  }" >> "$OUTPUT_FILE"
fi
echo "]" >> "$OUTPUT_FILE"

echo "Status check complete. Results written to $OUTPUT_FILE"
