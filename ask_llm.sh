#!/bin/bash

# SimpleBrain Multi-LLM Client
# Usage: ./ask_llm.sh [instance] "question"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Show usage
usage() {
    echo -e "${CYAN}SimpleBrain Multi-LLM Client${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [instance] \"question\""
    echo
    echo -e "${BLUE}Available LLM instances:${NC}"
    echo -e "${CYAN}  general${NC}  (Port: ${YELLOW}5001${NC}) - Phi-3 Mini 4K - Fast general tasks"
    echo -e "${CYAN}  coding${NC}   (Port: ${YELLOW}5002${NC}) - Mistral-7B - Programming and development"
    echo -e "${CYAN}  chat${NC}     (Port: ${YELLOW}5003${NC}) - Llama-3 8B - Conversations and analysis"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 general \"What is machine learning?\""
    echo -e "  $0 coding \"Write a Python function for sorting\""
    echo -e "  $0 chat \"Tell me a story about robots\""
    echo
    echo -e "${BLUE}Health checks:${NC}"
    echo -e "  $0 health"
}

# Health check all instances
health_check() {
    echo -e "${CYAN}🔍 Checking all LLM instances...${NC}"
    echo
    
    echo -e "${BLUE}General (Phi-3) - Port 5001:${NC}"
    curl -s http://localhost:5001/health | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    status = data.get('status', 'unknown')
    model = data.get('environment', {}).get('model_type', 'unknown')
    print(f'  Status: {status}, Model: {model}')
except:
    print('  Status: offline or error')
"
    
    echo -e "${BLUE}Coding (Mistral-7B) - Port 5002:${NC}"
    curl -s http://localhost:5002/health | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    status = data.get('status', 'unknown')
    model = data.get('environment', {}).get('model_type', 'unknown')
    print(f'  Status: {status}, Model: {model}')
except:
    print('  Status: offline or error')
"
    
    echo -e "${BLUE}Chat (Llama-3) - Port 5003:${NC}"
    curl -s http://localhost:5003/health | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    status = data.get('status', 'unknown')
    model = data.get('environment', {}).get('model_type', 'unknown')
    print(f'  Status: {status}, Model: {model}')
except:
    print('  Status: offline or error')
"
}

# Ask question to specific LLM
ask_llm() {
    local instance="$1"
    local question="$2"
    local port
    local model_name
    
    case "$instance" in
        "general")
            port="5001"
            model_name="Phi-3 Mini 4K"
            ;;
        "coding")
            port="5002"
            model_name="Mistral-7B"
            ;;
        "chat")
            port="5003"
            model_name="Llama-3 8B"
            ;;
        *)
            echo -e "${RED}Error: Invalid instance '$instance'${NC}" >&2
            echo "Available: general, coding, chat" >&2
            exit 1
            ;;
    esac
    
    echo -e "${CYAN}🤖 Asking ${model_name} (${instance}):${NC} $question"
    echo -e "${BLUE}📡 Connecting to port $port...${NC}"
    echo
    
    # Send request with longer timeout for model processing
    local response
    response=$(curl -s --max-time 60 \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"prompt\":\"$question\"}" \
        "http://localhost:$port/api/agent")
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Parse and display response
        echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    llm_response = data.get('llm_response', 'No response received')
    print('${GREEN}🤖 Response:${NC}')
    print(llm_response)
    
    # Show command execution if any
    executed_command = data.get('executed_command')
    command_result = data.get('command_result', '')
    
    if executed_command and executed_command != 'None':
        print('\n${YELLOW}🔧 Command executed:${NC} ' + executed_command)
        if command_result:
            print('${BLUE}📋 Result:${NC}')
            print(command_result)
except Exception as e:
    print('${RED}Error parsing response:${NC} ' + str(e))
"
    else
        echo -e "${RED}Error: Failed to get response from $model_name${NC}" >&2
        echo -e "${YELLOW}The model may be loading or processing. Try again in a moment.${NC}" >&2
        exit 1
    fi
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

if [[ "$1" == "health" ]]; then
    health_check
    exit 0
fi

if [[ $# -eq 2 ]]; then
    ask_llm "$1" "$2"
else
    echo -e "${RED}Error: Invalid arguments${NC}" >&2
    echo "Usage: $0 [instance] \"question\"" >&2
    echo "       $0 health" >&2
    echo "       $0 help" >&2
    exit 1
fi