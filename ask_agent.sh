#!/bin/bash

# Simple CLI wrapper for local LLM agent
# Usage: ./ask_agent.sh "Your question here"

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Your question here\""
    echo "Example: $0 \"What is 2+2?\""
    exit 1
fi

PROMPT="$1"

# Make API call and parse response
response=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"prompt\": \"$PROMPT\"}" \
    http://localhost:5001/api/agent)

# Extract just the LLM response using jq (if available) or python
if command -v jq &> /dev/null; then
    echo "$response" | jq -r '.llm_response'
else
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['llm_response'])
"
fi