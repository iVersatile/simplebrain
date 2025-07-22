#!/bin/bash

set -euo pipefail

# SimpleBrain Multi-Instance CLI Client
# Allows interaction with specific instances or auto-select based on task type

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Instance configuration
declare -A INSTANCES=(
    ["general"]="5001:General purpose tasks"
    ["coding"]="5002:Programming and development"
    ["chat"]="5003:Conversations and creative writing"
)

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Function to show usage
usage() {
    echo -e "${CYAN}SimpleBrain Multi-Instance CLI${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [instance] \"question\""
    echo -e "${BLUE}   or:${NC} $0 \"question\"  # Auto-select best instance"
    echo
    echo -e "${BLUE}Available instances:${NC}"
    for instance in "${!INSTANCES[@]}"; do
        IFS=':' read -r port description <<< "${INSTANCES[$instance]}"
        printf "${CYAN}  %-12s${NC} (Port: ${YELLOW}%s${NC}) - %s\n" "$instance" "$port" "$description"
    done
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 coding \"How do I implement binary search in Python?\""
    echo -e "  $0 chat \"Tell me a story about a robot\""
    echo -e "  $0 general \"What is machine learning?\""
    echo -e "  $0 \"Write a Python function\"  # Auto-selects coding instance"
}

# Function to auto-select instance based on question content
auto_select_instance() {
    local question="$1"
    local question_lower=$(echo "$question" | tr '[:upper:]' '[:lower:]')
    
    # Keywords for different instance types
    local coding_keywords="code|python|javascript|java|programming|function|algorithm|debug|api|database|sql|git|docker|terminal|command|script|bug|error|syntax"
    local chat_keywords="story|creative|write|poem|essay|conversation|chat|tell me|imagine|what if|opinion|feel|think|personal|experience"
    
    if echo "$question_lower" | grep -qE "$coding_keywords"; then
        echo "coding"
    elif echo "$question_lower" | grep -qE "$chat_keywords"; then
        echo "chat"
    else
        echo "general"
    fi
}

# Function to check if instance is running
check_instance_running() {
    local instance="$1"
    IFS=':' read -r port description <<< "${INSTANCES[$instance]}"
    
    if curl -s --max-time 2 "http://localhost:$port" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to ask question to specific instance
ask_instance() {
    local instance="$1"
    local question="$2"
    
    if [[ ! ${INSTANCES[$instance]+_} ]]; then
        echo -e "${RED}Error: Invalid instance '$instance'${NC}" >&2
        echo "Available instances: ${!INSTANCES[*]}" >&2
        exit 1
    fi
    
    IFS=':' read -r port description <<< "${INSTANCES[$instance]}"
    
    # Check if instance is running
    if ! check_instance_running "$instance"; then
        echo -e "${RED}Error: Instance '$instance' is not running or not responding${NC}" >&2
        echo -e "${YELLOW}Tip: Start it with: ./automate_multi_instance.sh start $instance${NC}" >&2
        exit 1
    fi
    
    echo -e "${CYAN}🤖 Asking ${instance} instance:${NC} $question"
    echo -e "${BLUE}📡 Connecting to port $port...${NC}"
    echo
    
    # Send request to the instance
    local response
    response=$(curl -s --max-time 30 \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"prompt\":\"$question\"}" \
        "http://localhost:$port/api/agent")
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Parse JSON response
        local llm_response
        local executed_command
        local command_result
        
        llm_response=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('llm_response', 'No response received'))
except:
    print('Error parsing response')
")
        
        executed_command=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    cmd = data.get('executed_command')
    print(cmd if cmd and cmd != 'None' else '')
except:
    pass
")
        
        command_result=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    result = data.get('command_result', '')
    print(result if result else '')
except:
    pass
")
        
        # Display response
        echo -e "${GREEN}🤖 Response:${NC}"
        echo "$llm_response"
        
        # Show command execution if any
        if [[ -n "$executed_command" ]]; then
            echo
            echo -e "${YELLOW}🔧 Command executed:${NC} $executed_command"
            if [[ -n "$command_result" ]]; then
                echo -e "${BLUE}📋 Result:${NC}"
                echo "$command_result"
            fi
        fi
        
    else
        echo -e "${RED}Error: Failed to get response from instance '$instance'${NC}" >&2
        echo -e "${YELLOW}Check if the instance is properly started and healthy${NC}" >&2
        exit 1
    fi
}

# Main logic
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi
    
    if [[ $# -eq 1 ]]; then
        # Auto-select instance based on question
        local question="$1"
        local selected_instance
        selected_instance=$(auto_select_instance "$question")
        
        echo -e "${CYAN}🎯 Auto-selected instance:${NC} $selected_instance"
        ask_instance "$selected_instance" "$question"
        
    elif [[ $# -eq 2 ]]; then
        # Use specified instance
        local instance="$1"
        local question="$2"
        ask_instance "$instance" "$question"
        
    else
        echo -e "${RED}Error: Too many arguments${NC}" >&2
        usage
        exit 1
    fi
}

# Handle help flags
if [[ "${1:-}" =~ ^(-h|--help|help)$ ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"