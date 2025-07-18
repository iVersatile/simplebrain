#!/bin/bash

# Health check script for local LLM
check_api() {
    curl -s -X POST -H "Content-Type: application/json" \
        -d '{"prompt": "health check"}' \
        http://localhost:5001/api/agent >/dev/null 2>&1
}

check_container() {
    docker-compose -f docker-compose.local-llm.yml ps | grep -q "Up"
}

if check_container && check_api; then
    echo "✅ Local LLM system healthy"
    exit 0
else
    echo "❌ Local LLM system unhealthy"
    exit 1
fi