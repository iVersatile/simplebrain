#!/bin/bash

set -euo pipefail

# SimpleBrain Multi-Instance Setup Script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/setup_multi.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Instance configuration
declare -A INSTANCES=(
    ["general"]="phi3-mini-4k.gguf"
    ["coding"]="mistral-7b.gguf"
    ["chat"]="llama3-8b.gguf"
)

# Model URLs
declare -A MODEL_URLS=(
    ["phi3-mini-4k.gguf"]="https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
    ["mistral-7b.gguf"]="https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
    ["llama3-8b.gguf"]="https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf"
)

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
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} SimpleBrain Multi-Instance Setup${NC}"
    echo -e "${CYAN}================================================${NC}"
}

# Function to check system requirements
check_requirements() {
    info "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker-compose --version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check available memory
    local available_memory
    case "$(uname)" in
        "Darwin")
            available_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
            available_memory=$((available_memory * 4096 / 1024 / 1024 / 1024))
            ;;
        "Linux")
            available_memory=$(free -g | awk '/^Mem:/{print $7}')
            ;;
        *)
            available_memory=8  # Assume sufficient memory
            ;;
    esac
    
    if [[ $available_memory -lt 8 ]]; then
        warn "Available memory (${available_memory}GB) might be insufficient for all instances"
        warn "Consider running fewer instances simultaneously"
    fi
    
    # Check available disk space
    local available_space
    available_space=$(df -h "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G.*//')
    
    if [[ $available_space -lt 15 ]]; then
        warn "Available disk space (${available_space}GB) might be insufficient for all models"
    fi
    
    success "System requirements check passed"
}

# Function to create directory structure
create_directories() {
    info "Creating multi-instance directory structure..."
    
    # Create base instances directory
    mkdir -p "${SCRIPT_DIR}/instances"
    
    # Create instance-specific directories
    for instance in "${!INSTANCES[@]}"; do
        local instance_dir="${SCRIPT_DIR}/instances/${instance}"
        
        info "Setting up instance: $instance"
        
        # Create directories
        mkdir -p "${instance_dir}"/{workspace,models,local_agent_workspace}
        
        # Copy original workspace if it exists
        if [[ -d "${SCRIPT_DIR}/workspace" ]]; then
            cp -r "${SCRIPT_DIR}/workspace/"* "${instance_dir}/workspace/" 2>/dev/null || true
        fi
        
        # Copy and customize local_agent_workspace
        if [[ -d "${SCRIPT_DIR}/local_agent_workspace" ]]; then
            cp -r "${SCRIPT_DIR}/local_agent_workspace/"* "${instance_dir}/local_agent_workspace/"
            
            # Customize app.py for production (fix debug mode issue)
            sed -i.bak 's/debug=True/debug=False/g' "${instance_dir}/local_agent_workspace/app.py" || true
            
            # Remove backup file
            rm -f "${instance_dir}/local_agent_workspace/app.py.bak"
        fi
        
        success "Instance '$instance' directories created"
    done
    
    success "Directory structure created successfully"
}

# Function to download models
download_models() {
    info "Downloading AI models..."
    
    # Create central models directory if it doesn't exist
    mkdir -p "${SCRIPT_DIR}/models"
    
    for model_file in "${!MODEL_URLS[@]}"; do
        local model_path="${SCRIPT_DIR}/models/${model_file}"
        local model_url="${MODEL_URLS[$model_file]}"
        
        if [[ -f "$model_path" ]]; then
            info "Model $model_file already exists, skipping download"
            continue
        fi
        
        info "Downloading $model_file..."
        info "This may take a while (models are 2-5GB each)..."
        
        # Download with progress bar
        if command -v wget &> /dev/null; then
            wget --progress=bar:force -O "$model_path" "$model_url" 2>&1 | \
                stdbuf -o0 grep -o "[0-9]*%" | \
                while read percentage; do
                    echo -ne "\r${BLUE}Progress: $percentage${NC}"
                done
            echo
        elif command -v curl &> /dev/null; then
            curl -L --progress-bar -o "$model_path" "$model_url"
        else
            error "Neither wget nor curl found. Please install one of them."
            exit 1
        fi
        
        # Verify download
        if [[ -f "$model_path" ]] && [[ $(stat -f%z "$model_path" 2>/dev/null || stat -c%s "$model_path" 2>/dev/null || echo 0) -gt 1000000 ]]; then
            success "Downloaded $model_file successfully"
        else
            error "Failed to download $model_file or file is too small"
            rm -f "$model_path"
            exit 1
        fi
    done
    
    # Create symlinks in each instance directory
    for instance in "${!INSTANCES[@]}"; do
        local instance_models_dir="${SCRIPT_DIR}/instances/${instance}/models"
        local required_model="${INSTANCES[$instance]}"
        
        # Create symlink to the required model
        ln -sf "${SCRIPT_DIR}/models/${required_model}" "${instance_models_dir}/"
        
        # Also create symlinks to all other models for flexibility
        for model_file in "${!MODEL_URLS[@]}"; do
            if [[ "$model_file" != "$required_model" ]]; then
                ln -sf "${SCRIPT_DIR}/models/${model_file}" "${instance_models_dir}/"
            fi
        done
        
        info "Model symlinks created for instance: $instance"
    done
    
    success "All models downloaded and configured"
}

# Function to build Docker images
build_images() {
    info "Building Docker images..."
    
    # Build the base image
    docker-compose -f docker-compose.multi-instance.yml build
    
    success "Docker images built successfully"
}

# Function to create convenience scripts
create_scripts() {
    info "Creating convenience scripts..."
    
    # Create a simple status checker script
    cat > "${SCRIPT_DIR}/status.sh" << 'EOF'
#!/bin/bash
./automate_multi_instance.sh status
EOF
    chmod +x "${SCRIPT_DIR}/status.sh"
    
    # Create a quick start script
    cat > "${SCRIPT_DIR}/quick_start.sh" << 'EOF'
#!/bin/bash
echo "🚀 Starting all SimpleBrain instances..."
./automate_multi_instance.sh start
echo ""
echo "✅ All instances should be starting up!"
echo "📊 Check status with: ./status.sh"
echo "💬 Ask questions with: ./ask_agent_multi.sh \"your question\""
EOF
    chmod +x "${SCRIPT_DIR}/quick_start.sh"
    
    # Create a quick stop script  
    cat > "${SCRIPT_DIR}/quick_stop.sh" << 'EOF'
#!/bin/bash
echo "🛑 Stopping all SimpleBrain instances..."
./automate_multi_instance.sh stop
echo "✅ All instances stopped!"
EOF
    chmod +x "${SCRIPT_DIR}/quick_stop.sh"
    
    success "Convenience scripts created"
}

# Function to run initial tests
run_tests() {
    info "Running initial tests..."
    
    # Start one instance for testing
    info "Starting general instance for testing..."
    ./automate_multi_instance.sh start general
    
    # Wait a bit for startup
    sleep 10
    
    # Test the instance
    if curl -s --max-time 10 "http://localhost:5001" >/dev/null 2>&1; then
        success "Test instance is responding!"
        
        # Stop test instance
        ./automate_multi_instance.sh stop general
    else
        warn "Test instance is not responding - you may need to debug"
    fi
    
    success "Initial tests completed"
}

# Function to show completion message
show_completion() {
    header
    echo
    success "🎉 SimpleBrain Multi-Instance setup completed successfully!"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "1. ${GREEN}Start all instances:${NC}     ./quick_start.sh"
    echo -e "2. ${GREEN}Check status:${NC}           ./status.sh"
    echo -e "3. ${GREEN}Ask questions:${NC}          ./ask_agent_multi.sh \"What is AI?\""
    echo -e "4. ${GREEN}Manage instances:${NC}       ./automate_multi_instance.sh help"
    echo
    echo -e "${BLUE}Available instances:${NC}"
    for instance in "${!INSTANCES[@]}"; do
        case "$instance" in
            "general") port="5001"; desc="General purpose tasks" ;;
            "coding") port="5002"; desc="Programming and development" ;;
            "chat") port="5003"; desc="Conversations and creative writing" ;;
        esac
        printf "${CYAN}  %-12s${NC} (Port: ${YELLOW}%s${NC}) - %s\n" "$instance" "$port" "$desc"
    done
    echo
    echo -e "${YELLOW}💡 Tip:${NC} You can run specific instances individually:"
    echo -e "   ./automate_multi_instance.sh start coding"
    echo
}

# Main setup function
main() {
    header
    echo
    
    log "Starting SimpleBrain Multi-Instance setup..."
    
    check_requirements
    create_directories
    download_models
    build_images
    create_scripts
    run_tests
    
    show_completion
}

# Handle help flags
if [[ "${1:-}" =~ ^(-h|--help|help)$ ]]; then
    header
    echo
    echo -e "${BLUE}SimpleBrain Multi-Instance Setup Script${NC}"
    echo
    echo "This script will:"
    echo "• Check system requirements"
    echo "• Create directory structure for multiple instances"  
    echo "• Download required AI models (phi3, mistral, llama3)"
    echo "• Build Docker images"
    echo "• Create convenience scripts"
    echo "• Run initial tests"
    echo
    echo -e "${YELLOW}Warning:${NC} This will download several GB of model files"
    echo
    echo -e "${BLUE}Usage:${NC} $0"
    exit 0
fi

# Run main setup
main "$@"