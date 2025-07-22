#!/bin/bash

set -euo pipefail

# SimpleBrain Simple Startup Script
readonly LOG_PREFIX="[SimpleBrain]"

# Colors for logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}${LOG_PREFIX} $1${NC}"
}

log_success() {
    echo -e "${GREEN}${LOG_PREFIX} $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}${LOG_PREFIX} $1${NC}"
}

log_error() {
    echo -e "${RED}${LOG_PREFIX} $1${NC}"
}

# Function to validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check model file
    if [[ ! -f "$MODEL_PATH" ]]; then
        log_error "Model file not found: $MODEL_PATH"
        log_info "Available files in models directory:"
        ls -la "$(dirname "$MODEL_PATH")" || true
        return 1
    fi
    
    # Check model file size
    local model_size
    model_size=$(stat -c%s "$MODEL_PATH" 2>/dev/null || stat -f%z "$MODEL_PATH" 2>/dev/null || echo 0)
    if [[ $model_size -lt 104857600 ]]; then  # 100MB
        log_warn "Model file seems small ($model_size bytes) - this might be a problem"
    else
        log_success "Model file looks valid ($(( model_size / 1024 / 1024 ))MB)"
    fi
    
    # Check llama.cpp executable
    local llama_path="/app/workspace/projects/llama.cpp/main"
    if [[ ! -x "$llama_path" ]]; then
        log_error "llama.cpp executable not found at $llama_path"
        log_info "Available files in workspace:"
        ls -la /app/workspace/ || true
        return 1
    fi
    
    log_success "Environment validation passed"
}

# Function to start Flask app
start_flask() {
    log_info "Starting Flask application..."
    
    cd /app/local_agent
    
    # Copy fixed files over original ones if they exist
    if [[ -f "app_fixed.py" ]]; then
        cp app_fixed.py app.py
        log_info "Using fixed Flask application"
    fi
    
    if [[ -f "llm_interface_fixed.py" ]]; then
        cp llm_interface_fixed.py llm_interface.py
        log_info "Using fixed LLM interface"
    fi
    
    # Set Flask environment
    export FLASK_APP=app.py
    export FLASK_ENV=production
    
    # Start Flask with better error handling
    log_success "Starting Flask server on port ${API_PORT:-5000}..."
    
    # Use exec to replace the shell process, so signals are handled correctly
    exec python3 app.py
}

# Main startup sequence
main() {
    log_info "Starting SimpleBrain container..."
    log_info "Instance: ${INSTANCE_NAME:-unknown}"
    log_info "Model Type: ${MODEL_TYPE:-unknown}"
    log_info "Model Path: ${MODEL_PATH:-not set}"
    
    # Validation
    validate_environment || {
        log_error "Environment validation failed"
        exit 1
    }
    
    # Start the Flask application
    start_flask
}

# Handle signals gracefully
trap 'log_info "Received shutdown signal, stopping Flask..."; exit 0' SIGTERM SIGINT

# Run main function
main "$@"