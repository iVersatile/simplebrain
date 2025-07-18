#!/bin/bash

set -euo pipefail

# Local LLM Agent Automation - Simplified 
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/llm_automation.log"
readonly COMPOSE_FILE="docker-compose.local-llm.yml"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

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

# Function to check if container is running
check_container_status() {
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local port="$2"
    local max_attempts=30
    local attempt=0
    
    info "Waiting for $service_name to be ready on port $port..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s "http://localhost:$port" >/dev/null 2>&1; then
            success "$service_name is ready!"
            return 0
        fi
        
        sleep 2
        ((attempt++))
        echo -n "."
    done
    
    error "$service_name failed to start within $((max_attempts * 2)) seconds"
    return 1
}

# Function to download model automatically
download_model() {
    local model_path="./models/model.gguf"
    
    if [[ -f "$model_path" ]]; then
        info "Model already exists at $model_path"
        return 0
    fi
    
    info "Downloading Phi-3 model..."
    
    # Create models directory
    mkdir -p "./models"
    
    # Download model
    local model_url="https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
    
    if command -v wget &> /dev/null; then
        wget -O "$model_path" "$model_url"
    elif command -v curl &> /dev/null; then
        curl -L -o "$model_path" "$model_url"
    else
        error "Neither wget nor curl found. Please install one of them."
        return 1
    fi
    
    success "Model downloaded successfully"
}

# Function to create health check
create_health_check() {
    info "Setting up health monitoring..."
    
    cat > "${SCRIPT_DIR}/health_check_llm.sh" <<'EOF'
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
EOF
    
    chmod +x "${SCRIPT_DIR}/health_check_llm.sh"
    
    success "Health check script created"
}

# Main automation functions
start_environment() {
    log "Starting local LLM environment..."
    
    # Check if already running
    if check_container_status; then
        warn "Environment is already running"
        return 0
    fi
    
    # Download model if needed
    download_model
    
    # Start containers
    info "Starting Docker containers..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for container to be ready
    sleep 10
    
    # Start Flask app if not running
    docker-compose -f "$COMPOSE_FILE" exec -d local-llm bash -c "cd /app/local_agent && python3 app.py >/dev/null 2>&1 &"
    
    sleep 5
    
    # Test the system
    if curl -s -X POST -H "Content-Type: application/json" -d '{"prompt": "test"}' http://localhost:5001/api/agent >/dev/null; then
        success "Local LLM environment started successfully! 🚀"
        info "Access methods:"
        info "  • CLI: ./ask_agent.sh \"your question\""
        info "  • Interactive: ./cli_agent.py"
        info "  • API: http://localhost:5001/api/agent"
        info "  • Direct: ./llama_direct.sh \"your question\""
    else
        error "Environment started but API is not responding"
        return 1
    fi
}

stop_environment() {
    log "Stopping local LLM environment..."
    
    docker-compose -f "$COMPOSE_FILE" down
    
    success "Environment stopped"
}

restart_environment() {
    log "Restarting local LLM environment..."
    
    stop_environment
    sleep 3
    start_environment
}

status_environment() {
    if check_container_status; then
        success "Local LLM environment is running ✅"
        
        # Show resource usage
        info "Resource usage:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep local_llm_agent
        
        # Test API
        if curl -s http://localhost:5001/api/agent >/dev/null 2>&1; then
            info "API is responding ✅"
        else
            warn "API is not responding ❌"
        fi
    else
        warn "Local LLM environment is not running ❌"
    fi
}

install_environment() {
    log "Installing local LLM environment..."
    
    # Run initial setup
    ./setup_local_llm.sh
    
    # Create health check
    create_health_check
    
    success "Local LLM environment installation complete!"
    info "Use './automate_local_llm.sh start' to start the environment"
}

# Function to show usage
show_usage() {
    cat << EOF
Local LLM Agent Automation (Simplified)

Usage: $0 [COMMAND]

Commands:
  install    Install and configure the local LLM environment
  start      Start the environment
  stop       Stop the environment  
  restart    Restart the environment
  status     Show environment status
  health     Run health check
  logs       Show logs
  clean      Clean up old containers and images
  
Examples:
  $0 install     # First time setup
  $0 start       # Start the environment
  $0 status      # Check if running
  $0 health      # Health check
  
Features:
  • Local Phi-3 model inference
  • Flask API (port 5001)
  • Command-line interfaces
  • No Code dependencies
  • Simplified and lightweight
EOF
}

# Main function
main() {
    # Create log file
    touch "$LOG_FILE"
    
    case "${1:-}" in
        install)
            install_environment
            ;;
        start)
            start_environment
            ;;
        stop)
            stop_environment
            ;;
        restart)
            restart_environment
            ;;
        status)
            status_environment
            ;;
        health)
            "${SCRIPT_DIR}/health_check_llm.sh"
            ;;
        logs)
            docker-compose -f "$COMPOSE_FILE" logs -f
            ;;
        clean)
            docker system prune -f
            docker volume prune -f
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"