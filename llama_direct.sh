#!/bin/bash

# Direct access to llama.cpp inside simplified container
# Usage: ./llama_direct.sh "Your question here"

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Your question here\""
    echo "Example: $0 \"What is machine learning?\""
    exit 1
fi

PROMPT="$1"

# Run llama.cpp directly in the simplified container
docker-compose -f docker-compose.local-llm.yml exec local-llm \
    /app/workspace/llama.cpp/build/bin/llama-cli \
    -m /app/models/model.gguf \
    -p "$PROMPT" \
    -n 128 \
    --temp 0.7 \
    -c 2048