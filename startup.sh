#!/bin/bash

set -euo pipefail

# SimpleBrain Container Startup Script
readonly LOG_PREFIX="[SimpleBrain-Startup]"

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

# Function to check and build llama.cpp if needed
setup_llama_cpp() {
    local workspace_dir="/app/workspace"
    local llama_dir="${workspace_dir}/llama.cpp"
    local llama_build_dir="${llama_dir}/build"
    local llama_executable="${llama_build_dir}/bin/main"
    
    log_info "Setting up llama.cpp..."
    
    # Create workspace directory
    mkdir -p "$workspace_dir"
    cd "$workspace_dir"
    
    # Check if llama.cpp source exists
    if [[ ! -d "$llama_dir" ]]; then
        log_info "llama.cpp source not found, extracting from archive..."
        
        if [[ -f "${workspace_dir}/llama.cpp.tar.gz" ]]; then
            tar -xzf "${workspace_dir}/llama.cpp.tar.gz"
        else
            log_error "llama.cpp source archive not found!"
            return 1
        fi
    fi
    
    # Check if executable already exists
    if [[ -x "$llama_executable" ]]; then
        log_success "llama.cpp executable found at $llama_executable"
        return 0
    fi
    
    # Build llama.cpp
    log_info "Building llama.cpp (this may take a few minutes)..."
    cd "$llama_dir"
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Configure and build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc) main
    
    # Create projects directory and symlink for backward compatibility
    mkdir -p "${workspace_dir}/projects/llama.cpp"
    ln -sf "$llama_executable" "${workspace_dir}/projects/llama.cpp/main"
    
    if [[ -x "$llama_executable" ]]; then
        log_success "llama.cpp built successfully!"
    else
        log_error "Failed to build llama.cpp"
        return 1
    fi
}

# Function to validate environment
validate_environment() {
    log_info "Validating environment..."
    
    # Check required environment variables
    local required_vars=("MODEL_PATH" "INSTANCE_NAME")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable $var is not set"
            return 1
        fi
    done
    
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
    
    log_success "Environment validation passed"
}

# Function to test LLM setup
test_llm() {
    log_info "Testing LLM setup..."
    
    cd /app/local_agent
    python3 -c "
import llm_interface_fixed as llm_interface
issues = llm_interface.test_llm_setup()
if issues:
    print('LLM setup issues:')
    for issue in issues:
        print(f'  - {issue}')
    exit(1)
else:
    print('LLM setup test passed!')
"
    
    if [[ $? -eq 0 ]]; then
        log_success "LLM test passed"
    else
        log_error "LLM test failed"
        return 1
    fi
}

# Function to start Flask app
start_flask() {
    log_info "Starting Flask application..."
    
    cd /app/local_agent
    
    # Copy fixed files over original ones
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
    
    # Setup and validation
    setup_llama_cpp || {
        log_error "Failed to setup llama.cpp"
        exit 1
    }
    
    validate_environment || {
        log_error "Environment validation failed"
        exit 1
    }
    
    test_llm || {
        log_error "LLM test failed"
        exit 1
    }
    
    # Start the Flask application
    start_flask
}

# Handle signals gracefully
trap 'log_info "Received shutdown signal, stopping Flask..."; exit 0' SIGTERM SIGINT

# Run main function
main "$@"