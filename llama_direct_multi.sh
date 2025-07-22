#!/bin/bash

# Direct access to llama.cpp inside multi-instance containers
# Usage: ./llama_direct_multi.sh [instance] "Your question here"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Instance configuration - using simple approach for compatibility
get_instance_info() {
    local instance="$1"
    case "$instance" in
        "general")
            echo "simplebrain-general-phi3:/app/models/phi3-mini-4k.gguf"
            ;;
        "coding")
            echo "simplebrain-coding-mistral:/app/models/mistral-7b.gguf"
            ;;
        "chat")
            echo "simplebrain-chat-llama3:/app/models/llama3-8b.gguf"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Show usage
usage() {
    echo -e "${CYAN}SimpleBrain Direct LLM Access${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [instance] \"question\""
    echo
    echo -e "${BLUE}Available instances:${NC}"
    echo -e "${CYAN}  general${NC} - Phi-3 Mini 4K (fast, general tasks)"
    echo -e "${CYAN}  coding${NC}  - Mistral-7B (programming tasks)"
    echo -e "${CYAN}  chat${NC}    - Llama-3 8B (conversations)"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 general \"What is machine learning?\""
    echo -e "  $0 coding \"Write a Python function\""
    echo -e "  $0 chat \"Tell me a story\""
    echo
    echo -e "${BLUE}Note:${NC} This bypasses the Flask API and calls llama.cpp directly"
}

# Check if container is running
check_container() {
    local container_name="$1"
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${RED}Error: Container '$container_name' is not running${NC}" >&2
        echo -e "${YELLOW}Start it with: docker-compose -f docker-compose.multi-instance.yml up -d${NC}" >&2
        return 1
    fi
    return 0
}

# Run llama.cpp directly in container
run_llama_direct() {
    local instance="$1"
    local question="$2"
    
    local instance_info
    instance_info=$(get_instance_info "$instance")
    
    if [[ -z "$instance_info" ]]; then
        echo -e "${RED}Error: Invalid instance '$instance'${NC}" >&2
        echo "Available instances: general, coding, chat" >&2
        exit 1
    fi
    
    IFS=':' read -r container_name model_path <<< "$instance_info"
    
    # Check if container is running
    if ! check_container "$container_name"; then
        exit 1
    fi
    
    echo -e "${CYAN}🤖 Direct access to ${instance} instance${NC}"
    echo -e "${BLUE}📦 Container: ${container_name}${NC}"
    echo -e "${BLUE}🧠 Model: ${model_path}${NC}"
    echo -e "${BLUE}❓ Question: ${question}${NC}"
    echo

    # Run llama.cpp directly with appropriate parameters
    docker exec "$container_name" \
        /app/workspace/projects/llama.cpp/main \
        -m "$model_path" \
        -p "$question" \
        -n 256 \
        --temp 0.7 \
        -c 2048 \
        --no-display-prompt \
        --no-warmup \
        -e
}

# Main logic
if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -eq 2 ]]; then
    run_llama_direct "$1" "$2"
else
    echo -e "${RED}Error: Invalid arguments${NC}" >&2
    echo "Usage: $0 [instance] \"question\"" >&2
    echo "       $0 help" >&2
    exit 1
fi