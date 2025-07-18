#!/bin/bash

set -euo pipefail

# Local LLM Agent Setup - Simplified 
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE_DIR="${SCRIPT_DIR}/workspace"
readonly MODELS_DIR="${SCRIPT_DIR}/models"
readonly LOCAL_AGENT_DIR="${SCRIPT_DIR}/local_agent_workspace"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${MAGENTA}[SUCCESS]${NC} $1"
}

# Function to display banner
show_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                     Local LLM Agent Setup                                ║"
    echo "║                                                                           ║"
    echo "║  🚀 Local LLM Inference    🔧 Flask API    🛡️ Security First            ║"
    echo "║                                                                           ║"
    echo "║  Features:                                                                ║"
    echo "║  • Local Phi-3 model inference with llama.cpp                            ║"
    echo "║  • Flask API for HTTP access                                              ║"
    echo "║  • Command-line interfaces                                                ║"
    echo "║  • Secure containerized environment                                       ║"
    echo "║  • No cloud dependencies                                                  ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to create directory structure
create_directories() {
    log "Creating directory structure..."
    
    # Create main directories
    mkdir -p "$WORKSPACE_DIR"
    mkdir -p "$MODELS_DIR"
    mkdir -p "$LOCAL_AGENT_DIR"
    
    # Set permissions
    chmod 755 "$WORKSPACE_DIR"
    chmod 755 "$MODELS_DIR"
    chmod 755 "$LOCAL_AGENT_DIR"
    
    log "Directory structure created successfully"
}

# Function to validate Docker setup
validate_docker() {
    log "Validating Docker setup..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        return 1
    fi
    
    log "Docker setup validated"
}

# Function to copy local agent files
setup_local_agent() {
    log "Setting up local agent application..."
    
    # Copy existing local agent files if they exist
    
    if [[ -d "local_agent_workspace" && "$(ls -A local_agent_workspace)" ]]; then
        log "Local agent files already exist"
    else
        error "Local agent files not found. Please ensure they exist."
        return 1
    fi
    
    # Ensure proper permissions
    chmod 755 "$LOCAL_AGENT_DIR"/*
    
    log "Local agent application setup completed"
}

# Function to download model if needed
check_model() {
    log "Checking for model file..."
    
    if [[ -f "$MODELS_DIR/model.gguf" ]]; then
        local model_size=$(du -h "$MODELS_DIR/model.gguf" | cut -f1)
        info "Model file found: $model_size"
        return 0
    fi
    
    warn "Model file not found at $MODELS_DIR/model.gguf"
    info "Please download a GGUF model file to $MODELS_DIR/model.gguf"
    info "Example: wget -O $MODELS_DIR/model.gguf https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
    
    return 1
}

# Function to build and start environment
start_environment() {
    log "Building and starting local LLM environment..."
    
    # Build container
    log "Building container..."
    docker-compose -f docker-compose.local-llm.yml build --no-cache
    
    # Start container
    log "Starting container..."
    docker-compose -f docker-compose.local-llm.yml up -d
    
    # Wait for container to be ready
    log "Waiting for container to initialize..."
    sleep 15
    
    # Build llama.cpp inside container
    log "Building llama.cpp inside container..."
    docker-compose -f docker-compose.local-llm.yml exec -T local-llm bash -c "
        cd /app/workspace && 
        wget -O llama.cpp.tar.gz https://github.com/ggml-org/llama.cpp/archive/refs/heads/master.tar.gz && 
        tar -xzf llama.cpp.tar.gz && 
        mv llama.cpp-master llama.cpp && 
        cd llama.cpp && 
        mkdir build && 
        cd build && 
        cmake .. && 
        make -j2
    "
    
    # Create symlink for the main binary
    docker-compose -f docker-compose.local-llm.yml exec -T local-llm bash -c "
        mkdir -p /app/workspace/projects/llama.cpp && 
        ln -sf /app/workspace/llama.cpp/build/bin/llama-cli /app/workspace/projects/llama.cpp/main
    "
    
    # Start Flask app
    log "Starting Flask API..."
    docker-compose -f docker-compose.local-llm.yml exec -d local-llm bash -c "
        cd /app/local_agent && 
        python3 app.py > /dev/null 2>&1 &
    "
    
    # Verify container is running
    if ! docker-compose -f docker-compose.local-llm.yml ps | grep -q "Up"; then
        error "Container failed to start"
        return 1
    fi
    
    success "Local LLM environment started successfully"
}

# Function to test environment
test_environment() {
    log "Testing local LLM environment..."
    
    # Test basic functionality
    if docker-compose -f docker-compose.local-llm.yml exec -T local-llm python3 --version &> /dev/null; then
        success "✓ Python environment is working"
    else
        warn "Python environment may have issues"
    fi
    
    # Test Flask installation
    if docker-compose -f docker-compose.local-llm.yml exec -T local-llm python3 -c "import flask; print('Flask OK')" &> /dev/null; then
        success "✓ Flask is installed"
    else
        warn "Flask may not be properly installed"
    fi
    
    # Test model file
    if docker-compose -f docker-compose.local-llm.yml exec -T local-llm test -f /app/models/model.gguf; then
        success "✓ Model file is accessible"
    else
        warn "Model file may not be accessible"
    fi
    
    # Test llama.cpp binary
    if docker-compose -f docker-compose.local-llm.yml exec -T local-llm test -f /app/workspace/projects/llama.cpp/main; then
        success "✓ llama.cpp binary is built and accessible"
    else
        warn "llama.cpp binary may not be properly built"
    fi
    
    # Test API endpoint
    sleep 5
    if curl -s -X POST -H "Content-Type: application/json" -d '{"prompt": "test"}' http://localhost:5001/api/agent > /dev/null; then
        success "✓ API endpoint is responding"
    else
        warn "API endpoint may not be responding"
    fi
    
    success "Environment testing completed"
}

# Function to display usage
show_usage() {
    cat << EOF
Local LLM Agent Setup

Usage: $0 [OPTIONS]

Options:
  --build-only        Only build the container
  --test             Run tests on existing setup
  --help             Show this help message

Features:
  • Local Phi-3 model inference with llama.cpp
  • Flask API for HTTP access (port 5001)
  • Command-line interfaces
  • Secure containerized environment
  • No Code dependencies

After setup, access the environment with:
  docker-compose -f docker-compose.local-llm.yml exec local-llm /bin/bash

Use the API:
  curl -X POST -H "Content-Type: application/json" \\
    -d '{"prompt": "Hello"}' http://localhost:5001/api/agent

Use CLI tools:
  ./ask_agent.sh "your question"
  ./cli_agent.py

To stop the environment:
  docker-compose -f docker-compose.local-llm.yml down

EOF
}

# Main function
main() {
    local build_only=false
    local test_only=false
    
    # Show banner
    show_banner
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build-only)
                build_only=true
                shift
                ;;
            --test)
                test_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate Docker
    validate_docker
    
    # Create directories
    create_directories
    
    if [[ "$test_only" == true ]]; then
        test_environment
        exit 0
    fi
    
    # Setup local agent
    setup_local_agent
    
    # Check model
    check_model
    
    if [[ "$build_only" == true ]]; then
        docker-compose -f docker-compose.local-llm.yml build --no-cache
        exit 0
    fi
    
    # Start environment
    start_environment
    
    # Test environment
    test_environment
    
    echo
    success "🚀 Local LLM environment setup finished successfully!"
    echo
    info "🔧 Access your local LLM environment with:"
    info "  docker-compose -f docker-compose.local-llm.yml exec local-llm /bin/bash"
    echo
    info "🎯 Test the API:"
    info "  curl -X POST -H \"Content-Type: application/json\" \\"
    info "    -d '{\"prompt\": \"Hello\"}' http://localhost:5001/api/agent"
    echo
    info "🌟 Use CLI tools:"
    info "  ./ask_agent.sh \"your question\""
    info "  ./cli_agent.py"
    echo
    info "🛑 Stop the environment with:"
    info "  docker-compose -f docker-compose.local-llm.yml down"
    echo
    success "🎉 Your local LLM agent is ready to use!"
}

# Execute main function
main "$@"