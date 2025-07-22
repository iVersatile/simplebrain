#!/bin/bash

set -euo pipefail

# SimpleBrain Multi-Instance Manager
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/multi_instance.log"
readonly COMPOSE_FILE="docker-compose.multi-instance.yml"

# Available instances configuration
declare -A INSTANCES=(
    ["general"]="5001:phi3-mini-4k.gguf:2G:general purpose tasks"
    ["coding"]="5002:mistral-7b.gguf:4G:coding assistance"
    ["chat"]="5003:llama3-8b.gguf:6G:conversations"
)

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${MAGENTA}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} SimpleBrain Multi-Instance Manager${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to validate instance name
validate_instance() {
    local instance="$1"
    if [[ ! ${INSTANCES[$instance]+_} ]]; then
        error "Invalid instance name: $instance"
        list_available_instances
        exit 1
    fi
}

# Function to list available instances
list_available_instances() {
    echo -e "${BLUE}Available instances:${NC}"
    for instance in "${!INSTANCES[@]}"; do
        IFS=':' read -r port model memory description <<< "${INSTANCES[$instance]}"
        printf "${CYAN}  %-12s${NC} Port: ${YELLOW}%-5s${NC} Model: ${GREEN}%-18s${NC} RAM: ${MAGENTA}%-3s${NC} - %s\n" \
            "$instance" "$port" "$model" "$memory" "$description"
    done
}

# Function to create instance directories
create_instance_directories() {
    local instance="$1"
    local instance_dir="${SCRIPT_DIR}/instances/${instance}"
    
    info "Creating directory structure for instance: $instance"
    
    # Create base directories
    mkdir -p "${instance_dir}"/{workspace,models,local_agent_workspace}
    
    # Copy template files
    if [[ -d "${SCRIPT_DIR}/local_agent_workspace" ]]; then
        cp -r "${SCRIPT_DIR}/local_agent_workspace/"* "${instance_dir}/local_agent_workspace/" 2>/dev/null || true
    fi
    
    if [[ -d "${SCRIPT_DIR}/workspace" ]]; then
        cp -r "${SCRIPT_DIR}/workspace/"* "${instance_dir}/workspace/" 2>/dev/null || true
    fi
    
    # Create symlinks to model files if they exist
    if [[ -d "${SCRIPT_DIR}/models" ]]; then
        find "${SCRIPT_DIR}/models" -name "*.gguf" -exec ln -sf "$(realpath {})" "${instance_dir}/models/" \;
    fi
    
    success "Directory structure created for instance: $instance"
}

# Function to check if instance is running
check_instance_status() {
    local instance="$1"
    local container_name="simplebrain-${instance}-$(get_instance_model_type "$instance")"
    
    if docker ps | grep -q "$container_name"; then
        return 0
    else
        return 1
    fi
}

# Function to get model type for instance
get_instance_model_type() {
    local instance="$1"
    case "$instance" in
        "general") echo "phi3" ;;
        "coding") echo "mistral" ;;
        "chat") echo "llama3" ;;
        *) echo "unknown" ;;
    esac
}

# Function to wait for service to be ready
wait_for_instance() {
    local instance="$1"
    IFS=':' read -r port model memory description <<< "${INSTANCES[$instance]}"
    local max_attempts=30
    local attempt=0
    
    info "Waiting for instance '$instance' to be ready on port $port..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s "http://localhost:$port/api/agent" >/dev/null 2>&1; then
            success "Instance '$instance' is ready on port $port!"
            return 0
        fi
        
        sleep 2
        ((attempt++))
        echo -n "."
    done
    
    error "Instance '$instance' failed to start within $((max_attempts * 2)) seconds"
    return 1
}

# Function to start specific instance
start_instance() {
    local instance="$1"
    validate_instance "$instance"
    
    info "Starting SimpleBrain instance: $instance"
    
    # Create directories if they don't exist
    create_instance_directories "$instance"
    
    # Start the specific service
    docker-compose -f "$COMPOSE_FILE" up -d "simplebrain-${instance}-$(get_instance_model_type "$instance")"
    
    # Wait for service to be ready
    wait_for_instance "$instance"
}

# Function to stop specific instance
stop_instance() {
    local instance="$1"
    validate_instance "$instance"
    
    info "Stopping SimpleBrain instance: $instance"
    docker-compose -f "$COMPOSE_FILE" stop "simplebrain-${instance}-$(get_instance_model_type "$instance")"
    success "Instance '$instance' stopped"
}

# Function to show instance status
show_status() {
    header
    echo
    
    for instance in "${!INSTANCES[@]}"; do
        IFS=':' read -r port model memory description <<< "${INSTANCES[$instance]}"
        
        printf "${CYAN}Instance: %-12s${NC}" "$instance"
        
        if check_instance_status "$instance"; then
            printf "${GREEN}[RUNNING]${NC} Port: ${YELLOW}%s${NC} Model: %s\n" "$port" "$model"
            
            # Check if API is responding
            if curl -s "http://localhost:$port" >/dev/null 2>&1; then
                printf "${CYAN}  └─ API Status: ${GREEN}✓ Healthy${NC}\n"
            else
                printf "${CYAN}  └─ API Status: ${YELLOW}⚠ Starting${NC}\n"
            fi
        else
            printf "${RED}[STOPPED]${NC} Port: ${YELLOW}%s${NC} Model: %s\n" "$port" "$model"
        fi
        echo
    done
}

# Function to show logs for instance
show_logs() {
    local instance="$1"
    validate_instance "$instance"
    
    info "Showing logs for instance: $instance"
    docker-compose -f "$COMPOSE_FILE" logs -f "simplebrain-${instance}-$(get_instance_model_type "$instance")"
}

# Function to restart instance
restart_instance() {
    local instance="$1"
    validate_instance "$instance"
    
    info "Restarting SimpleBrain instance: $instance"
    docker-compose -f "$COMPOSE_FILE" restart "simplebrain-${instance}-$(get_instance_model_type "$instance")"
    
    # Wait for service to be ready
    wait_for_instance "$instance"
}

# Function to start all instances
start_all() {
    header
    info "Starting all SimpleBrain instances..."
    
    # Create all instance directories
    for instance in "${!INSTANCES[@]}"; do
        create_instance_directories "$instance"
    done
    
    # Start all services
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for all services
    for instance in "${!INSTANCES[@]}"; do
        wait_for_instance "$instance" &
    done
    wait
    
    success "All instances started successfully!"
    show_status
}

# Function to stop all instances
stop_all() {
    info "Stopping all SimpleBrain instances..."
    docker-compose -f "$COMPOSE_FILE" down
    success "All instances stopped"
}

# Function to clean up
cleanup() {
    info "Cleaning up SimpleBrain instances..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    docker system prune -f
    success "Cleanup completed"
}

# Function to show usage
usage() {
    header
    echo
    echo -e "${BLUE}Usage:${NC} $0 {command} [instance_name]"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}start${NC} [instance]     Start specific instance or all instances"
    echo -e "  ${GREEN}stop${NC} [instance]      Stop specific instance or all instances"
    echo -e "  ${GREEN}restart${NC} [instance]   Restart specific instance"
    echo -e "  ${GREEN}status${NC}               Show status of all instances"
    echo -e "  ${GREEN}logs${NC} [instance]      Show logs for specific instance"
    echo -e "  ${GREEN}list${NC}                 List available instances"
    echo -e "  ${GREEN}cleanup${NC}              Stop all and clean up resources"
    echo -e "  ${GREEN}health${NC}               Check health of all instances"
    echo
    list_available_instances
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 start general      # Start general-purpose instance"
    echo -e "  $0 start              # Start all instances"
    echo -e "  $0 status             # Show status of all instances"
    echo -e "  $0 logs coding        # Show logs for coding instance"
}

# Function to health check all instances
health_check() {
    header
    echo -e "${BLUE}Health Check Results:${NC}"
    echo
    
    local all_healthy=true
    
    for instance in "${!INSTANCES[@]}"; do
        IFS=':' read -r port model memory description <<< "${INSTANCES[$instance]}"
        
        printf "${CYAN}Testing %-12s${NC} (Port: %s) " "$instance" "$port"
        
        if check_instance_status "$instance"; then
            if curl -s --max-time 5 "http://localhost:$port" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Healthy${NC}"
            else
                echo -e "${YELLOW}⚠ Container running but API not responding${NC}"
                all_healthy=false
            fi
        else
            echo -e "${RED}✗ Not running${NC}"
            all_healthy=false
        fi
    done
    
    echo
    if $all_healthy; then
        success "All instances are healthy!"
    else
        warn "Some instances need attention"
    fi
}

# Main command handler
main() {
    case "${1:-usage}" in
        start)
            if [[ $# -eq 1 ]]; then
                start_all
            else
                start_instance "$2"
            fi
            ;;
        stop)
            if [[ $# -eq 1 ]]; then
                stop_all
            else
                stop_instance "$2"
            fi
            ;;
        restart)
            if [[ $# -eq 2 ]]; then
                restart_instance "$2"
            else
                error "Instance name required for restart command"
                usage
                exit 1
            fi
            ;;
        status)
            show_status
            ;;
        logs)
            if [[ $# -eq 2 ]]; then
                show_logs "$2"
            else
                error "Instance name required for logs command"
                usage
                exit 1
            fi
            ;;
        list)
            header
            list_available_instances
            ;;
        cleanup)
            cleanup
            ;;
        health)
            health_check
            ;;
        usage|help|-h|--help)
            usage
            ;;
        *)
            error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"