# SimpleBrain - Local AI Assistant

A simplified, lightweight local LLM system optimized for offline AI assistance without cloud dependencies. Now supports **multi-instance deployment** for running multiple AI models simultaneously.

## 🚀 Quick Start

### Single Instance (Traditional)

```bash
# Setup (one-time)
./setup_local_llm.sh

# Start your AI assistant
./automate_local_llm.sh start

# Use your AI assistant
./ask_agent.sh "What is machine learning?"
./cli_agent.py  # Interactive mode
```

### Multi-Instance (New!)

```bash
# Deploy multiple containers with different models
docker-compose -f docker-compose.multi-instance.yml up -d

# Use the smart client tools to target specific LLMs
./ask_llm.sh general "What is machine learning?"        # Phi-3 (Fast, general)
./ask_llm.sh coding "Write a Python function"           # Mistral-7B (Programming)
./ask_llm.sh chat "Tell me a story about robots"        # Llama-3 (Conversations)

# Interactive mode with LLM switching
python3 ask_llm.py --interactive

# Health check all instances
./ask_llm.sh health
```

## Features

- **🧠 Local AI**: Multiple model support with llama.cpp inference
- **🔒 No Cloud Dependencies**: Runs entirely offline
- **⚡ Lightweight**: 4GB total footprint (vs 12GB complex systems)
- **🛡️ Secure**: Containerized with security hardening
- **🔧 Simple**: Easy to use and maintain
- **🔄 Multi-Model**: Switch between different AI models instantly
- **🏗️ Multi-Instance**: Run multiple models simultaneously on different ports
- **🎯 Specialized Instances**: Dedicated containers for different use cases
- **🛠️ Smart Client Tools**: Intelligent LLM selection and interactive chat modes

## Project Structure

```
SimpleBrain/
├── Core Scripts
│   ├── setup_local_llm.sh                 # One-time setup and container building
│   ├── automate_local_llm.sh              # Environment management
│   ├── automate_multi_instance.sh         # Multi-instance management (NEW!)
│   └── health_check_llm.sh                # System health monitoring
├── CLI Interfaces
│   ├── ask_llm.sh                         # Multi-LLM client (NEW!)
│   ├── ask_llm.py                         # Multi-LLM Python client (NEW!)
│   ├── llama_direct_multi.sh              # Direct multi-LLM access (NEW!)
│   ├── ask_agent.sh                       # Single instance CLI
│   ├── cli_agent.py                       # Interactive chat interface
│   └── llama_direct.sh                    # Direct LLM access (single-instance only)
├── Configuration
│   ├── Dockerfile.local-llm               # Minimal container definition
│   ├── docker-compose.local-llm.yml       # Single instance orchestration
│   └── docker-compose.multi-instance.yml  # Multi-instance orchestration (NEW!)
├── Data Directories
│   ├── models/                            # AI model files (shared across instances)
│   ├── workspace/                         # llama.cpp build directory
│   ├── local_agent_workspace/             # Flask API application
│   └── instances/                         # Instance-specific configurations (NEW!)
│       ├── general/                       # General purpose instance
│       ├── coding/                        # Coding assistance instance
│       └── chat/                          # Conversational instance
└── Startup Scripts
    ├── startup.sh                         # Full-featured startup script
    └── startup_simple.sh                  # Lightweight startup script
```

## Multi-Instance Architecture

### Instance Configuration

| Instance | Port | Model | Size | Best For | Memory | Network |
|----------|------|-------|------|----------|--------|---------|
| **general** | 5001 | Phi-3 Mini 4K | 2.4GB | General tasks, Q&A | 4GB RAM | 172.25.1.0/24 |
| **coding** | 5002 | Mistral 7B | 4.1GB | Programming, debugging | 6GB RAM | 172.25.2.0/24 |
| **chat** | 5003 | Llama 3 8B | 4.6GB | Conversations, creative writing | 8GB RAM | 172.25.3.0/24 |

### Naming Convention

- **Docker Images**: `simplebrain-{model}:v1.0` (e.g., `simplebrain-phi3:v1.0`)
- **Containers**: `simplebrain-{instance}-{model}` (e.g., `simplebrain-coding-mistral`)
- **Networks**: `simplebrain-{instance}-net` (e.g., `simplebrain-coding-net`)
- **Directories**: `./instances/{instance}/` (e.g., `./instances/coding/`)

### Multi-Instance Directory Structure

```
simplebrain/
├── 📁 instances/
│   ├── 📁 general/          # Phi-3 instance
│   │   ├── workspace/       # llama.cpp build
│   │   ├── models/          # Model symlinks
│   │   └── local_agent_workspace/  # Flask app
│   ├── 📁 coding/           # Mistral instance
│   └── 📁 chat/             # Llama-3 instance
├── 📁 models/               # Shared model files
│   ├── phi3-mini-4k.gguf
│   ├── mistral-7b.gguf
│   └── llama3-8b.gguf
├── 🐳 docker-compose.multi-instance.yml
├── 🔧 automate_multi_instance.sh
├── 💬 ask_agent_multi.sh
└── ⚙️ setup_multi_instance.sh
```

### Network Isolation

Each instance runs in its own isolated Docker network for security:

### Multi-Instance Management

#### Docker Compose Commands

```bash
# Start all instances
docker-compose -f docker-compose.multi-instance.yml up -d

# Start specific instances
docker-compose -f docker-compose.multi-instance.yml up -d simplebrain-general-phi3 simplebrain-coding-mistral

# Check status
docker ps --filter "name=simplebrain"

# View logs
docker logs simplebrain-general-phi3
docker logs simplebrain-coding-mistral
docker logs simplebrain-chat-llama3

# Health checks
curl http://localhost:5001/health  # General instance
curl http://localhost:5002/health  # Coding instance  
curl http://localhost:5003/health  # Chat instance

# Stop all instances
docker-compose -f docker-compose.multi-instance.yml down
```

#### Management Script Commands

```bash
# Start specific instance
./automate_multi_instance.sh start general
./automate_multi_instance.sh start coding  
./automate_multi_instance.sh start chat

# Start all instances
./automate_multi_instance.sh start

# Stop specific instance
./automate_multi_instance.sh stop coding

# Stop all instances
./automate_multi_instance.sh stop

# Restart instance
./automate_multi_instance.sh restart general

# Show status
./automate_multi_instance.sh status

# Health check
./automate_multi_instance.sh health

# Show logs
./automate_multi_instance.sh logs coding

# List available instances
./automate_multi_instance.sh list

# Cleanup everything
./automate_multi_instance.sh cleanup
```

## Client Tools

SimpleBrain provides multiple client tools to interact with different LLM instances easily.

### Multi-LLM Client Tools (Recommended)

#### Shell Client (`ask_llm.sh`)

Target specific LLM instances for optimal results:

```bash
# General questions (Phi-3 - Fast)
./ask_llm.sh general "What is machine learning?"
./ask_llm.sh general "Explain quantum computing"

# Programming tasks (Mistral-7B - Best for code)
./ask_llm.sh coding "Write a Python sorting function"
./ask_llm.sh coding "Debug this JavaScript code"
./ask_llm.sh coding "Create a REST API endpoint"

# Conversations (Llama-3 8B - Best for chat)
./ask_llm.sh chat "Tell me a story about space exploration"
./ask_llm.sh chat "What's your opinion on artificial intelligence?"

# Health checks
./ask_llm.sh health                           # Check all instances
```

#### Python Client (`ask_llm.py`)

**Single Questions:**
```bash
python3 ask_llm.py general "What is AI?"
python3 ask_llm.py coding "Sort a list in Python"
python3 ask_llm.py chat "Write a haiku about technology"
```

**Interactive Mode with LLM Switching:**
```bash
python3 ask_llm.py --interactive

# Inside interactive mode:
💬 You (general): Hello
🤖 Response: Hello! I'm Phi-3...

💬 You (general): switch coding
Switched to coding (Mistral-7B)

💬 You (coding): Write a function to reverse a string
🤖 Response: Here's a Python function...

💬 You (coding): switch chat  
Switched to chat (Llama-3 8B)

💬 You (chat): Tell me about the future of AI
🤖 Response: The future of AI...
```

**Health Monitoring:**
```bash
python3 ask_llm.py --health                  # Check all instances
python3 ask_llm.py --health coding           # Check specific instance
```

#### Direct LLM Access (`llama_direct_multi.sh`)

Bypass the Flask API and talk directly to llama.cpp for faster responses:

```bash
# Direct access to specific models (fastest performance)
./llama_direct_multi.sh general "What is AI?"
./llama_direct_multi.sh coding "Write a sorting function"
./llama_direct_multi.sh chat "Tell me about quantum computing"

# Show available instances
./llama_direct_multi.sh help
```

**Sample Usage Output:**
```bash
$ ./llama_direct_multi.sh general "What is machine learning?"

🤖 Direct access to general instance
📦 Container: simplebrain-general-phi3
🧠 Model: /app/models/phi3-mini-4k.gguf
❓ Question: What is machine learning?

Machine learning is a subset of artificial intelligence that enables 
computers to learn and make decisions from data without being explicitly 
programmed for every task. It involves algorithms that can identify 
patterns, make predictions, and improve their performance over time 
through experience with data.

$ ./llama_direct_multi.sh coding "Write a Python function to reverse a string"

🤖 Direct access to coding instance
📦 Container: simplebrain-coding-mistral
🧠 Model: /app/models/mistral-7b.gguf
❓ Question: Write a Python function to reverse a string

Here's a Python function to reverse a string:

def reverse_string(s):
    return s[::-1]

# Alternative approaches:
def reverse_string_loop(s):
    reversed_str = ""
    for char in s:
        reversed_str = char + reversed_str
    return reversed_str

def reverse_string_builtin(s):
    return ''.join(reversed(s))

# Usage examples:
print(reverse_string("hello"))  # Output: "olleh"
```

**Benefits of Direct Access:**
- **Faster responses** - No Flask API overhead
- **Raw model output** - Unprocessed LLM responses
- **Debugging** - See model loading info and performance metrics
- **Testing** - Validate model behavior directly

#### Smart Auto-Selection Client (`ask_agent_multi.sh`)

Automatically selects the best LLM instance based on question content:

```bash
# Auto-select instance (smart routing)
./ask_agent_multi.sh "How do I debug Python code?"           # → coding
./ask_agent_multi.sh "Tell me about quantum computing"      # → general  
./ask_agent_multi.sh "Write me a poem about the ocean"      # → chat

# Target specific instance
./ask_agent_multi.sh coding "Explain async/await in Python"
./ask_agent_multi.sh chat "What's your favorite book?"
./ask_agent_multi.sh general "What causes rain?"
```

**Auto-Selection Logic:**
- **Coding keywords**: `code`, `python`, `function`, `debug`, `api`, `script` → **coding** instance
- **Creative keywords**: `story`, `creative`, `poem`, `chat`, `imagine` → **chat** instance  
- **Everything else** → **general** instance

### Instance Selection Guide

| Instance | Model | Best For | When to Use |
|----------|-------|----------|-------------|
| **general** | Phi-3 Mini 4K | Quick questions, facts, explanations | Fast responses needed, general knowledge |
| **coding** | Mistral-7B | Programming, debugging, technical tasks | Code generation, technical documentation |
| **chat** | Llama-3 8B | Conversations, creative writing | In-depth discussions, creative content |

### Legacy Single-Instance Tools

For backward compatibility with single-instance deployments:

```bash
# Single instance shell client (port 5001 only)
./ask_agent.sh "Your question"

# Interactive Python CLI (port 5001 only)
./cli_agent.py                               # Interactive mode
./cli_agent.py "Your question"               # Single question

# Direct LLM access (single-instance only)
./llama_direct.sh "Your question"           # Requires docker-compose.local-llm.yml
```

**Note:** `llama_direct.sh` only works with single-instance deployment and will show `service "local-llm" is not running` error with multi-instance setup. Use `llama_direct_multi.sh` instead for multi-instance environments.

## Usage Examples

### Multi-Instance Usage

```bash
# Deploy all instances
docker-compose -f docker-compose.multi-instance.yml up -d

# Use different LLMs for different tasks
./ask_llm.sh general "What's the capital of France?"
./ask_llm.sh coding "Create a binary search algorithm"
./ask_llm.sh chat "Write a short poem about coding"

# Interactive session with model switching
python3 ask_llm.py --interactive

# Monitor all instances
./ask_llm.sh health
```

### Single Instance Usage

```bash
# Start the system
./automate_local_llm.sh start

# Ask questions
./ask_agent.sh "Explain Python functions"

# Interactive chat
./cli_agent.py

# Direct LLM access
./llama_direct.sh "What is AI?"

# Check system health
./automate_local_llm.sh health

# Stop the system
./automate_local_llm.sh stop
```

### Multi-Instance Usage

```bash
# Deploy specialized instances
docker-compose -f docker-compose.multi-instance.yml up -d

# Use smart client tools for different tasks
./ask_llm.sh general "What is the weather like?"
./ask_llm.sh coding "Write a Python function to sort a list"
./ask_llm.sh chat "Tell me about the philosophy of consciousness"

# Interactive mode for extended conversations
python3 ask_llm.py --interactive

# Direct API access (advanced users)
curl -X POST http://localhost:5001/api/agent \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Your question"}'
```

### Management Commands

```bash
./automate_local_llm.sh install    # Install environment
./automate_local_llm.sh start      # Start single instance
./automate_local_llm.sh stop       # Stop single instance
./automate_local_llm.sh restart    # Restart single instance
./automate_local_llm.sh status     # Show status
./automate_local_llm.sh health     # Health check
./automate_local_llm.sh logs       # View logs
./automate_local_llm.sh clean      # Clean up
```

## API Access

### Single Instance API

The system provides HTTP API at `http://localhost:5001/api/agent`

### Multi-Instance APIs

Multiple specialized endpoints are available:

```bash
# General purpose (Phi-3)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "Hello"}' \
  http://localhost:5001/api/agent

# Coding assistance (Mistral-7B)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "Write a sorting algorithm"}' \
  http://localhost:5002/api/agent

# Conversational (Llama-3 8B)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "Discuss the meaning of life"}' \
  http://localhost:5003/api/agent
```

### Health Endpoints

```bash
curl http://localhost:5001/health  # General instance health
curl http://localhost:5002/health  # Coding instance health
curl http://localhost:5003/health  # Chat instance health
```

## Multi-Model Support

SimpleBrain supports multiple AI models that you can switch between or run simultaneously:

### Available Models

| Model | Size | Best For | Speed | Memory | Multi-Instance Port |
|-------|------|----------|--------|--------|--------------------|
| **Phi-3 Mini** | 2.4GB | General tasks, Fast responses | ⚡⚡⚡ | 4GB | 5001 |
| **Mistral 7B** | 4.1GB | Coding, Math, Reasoning | ⚡⚡ | 6GB | 5002 |
| **Llama 3 8B** | 4.6GB | Quality conversations | ⚡⚡ | 8GB | 5003 |
| **Code Llama** | 4.0GB | Programming tasks | ⚡⚡ | 6GB | Custom |

### Model Switching (Single Instance)

#### List Available Models

```bash
./switch_model.sh list
```

#### Switch to Different Model

```bash
# Switch to Mistral for coding
./switch_model.sh switch mistral-7b.gguf

# Switch to Llama 3 for conversations
./switch_model.sh switch llama3-8b.gguf

# Switch back to Phi-3 for speed
./switch_model.sh switch phi3-mini-4k.gguf
```

### Download Additional Models

```bash
cd models/

# Download Llama 3 8B
wget -O llama3-8b.gguf https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf

# Download Code Llama
wget -O codellama-7b.gguf https://huggingface.co/bartowski/CodeLlama-7B-Instruct-GGUF/resolve/main/CodeLlama-7B-Instruct-v0.3-Q4_K_M.gguf

# Download Mistral 7B
wget -O mistral-7b.gguf https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
```

### Model Recommendations

- **🏃 Quick Questions**: Use Phi-3 (port 5001) - fastest, smallest
- **💻 Coding Help**: Use Mistral 7B (port 5002) or Code Llama
- **🧠 Deep Conversations**: Use Llama 3 8B (port 5003) - best quality
- **⚡ Low Memory**: Use Phi-3 (only 4GB RAM needed)
- **🔧 Development**: Run all instances simultaneously for different tasks

## System Requirements

### Hardware Requirements

| Configuration | General Only | General + Coding | All Instances |
|---------------|-------------|------------------|---------------|
| **RAM** | 4GB+ | 8GB+ | 12GB+ |
| **CPU** | 2+ cores | 4+ cores | 6+ cores |
| **Storage** | 6GB | 12GB | 18GB |

**Recommended System Specifications:**
- **Memory**: 4GB+ RAM for single instance, 12GB+ for all instances
- **Storage**: 15GB+ free disk space (for all models and containers)
- **CPU**: 2+ cores (8+ recommended for multi-instance)
- **Architecture**: macOS/Linux (ARM64/x86_64)

### Software Requirements

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Operating System**: macOS, Linux, or WSL2
- **curl**: For CLI tools
- **Python 3**: For JSON parsing in scripts

## Security Features

### Container Security

- **Isolation**: Sandboxed Docker environment per instance
- **Non-root execution**: Runs as `llmuser:1000`
- **Resource limits**: CPU, memory, and PID constraints per instance
- **Network isolation**: Custom bridge networks with inter-container communication disabled
- **Read-only filesystem**: Prevents unauthorized modifications
- **Capability dropping**: All unnecessary Linux capabilities removed

#### Resource Allocation Per Instance

**General Instance (Phi-3)**:
- CPU: 2 cores max, 0.5 reserved
- Memory: 4GB max, 1GB reserved  
- Network: `172.25.1.0/24`

**Coding Instance (Mistral)**:
- CPU: 3 cores max, 1 reserved
- Memory: 6GB max, 2GB reserved
- Network: `172.25.2.0/24`

**Chat Instance (Llama-3)**:
- CPU: 4 cores max, 1.5 reserved
- Memory: 8GB max, 3GB reserved
- Network: `172.25.3.0/24`

### Privacy Features

- **100% Offline**: No data sent to external services
- **Local Processing**: All AI inference happens locally
- **No Telemetry**: No usage tracking or analytics
- **Secure Storage**: Models and data stored locally
- **Instance Isolation**: Different instances cannot access each other's data

### Security Considerations

#### Network Security
- Each instance runs on isolated Docker networks
- Inter-container communication disabled
- Only necessary ports exposed to host

#### Container Security  
- Non-root user execution (UID 1000)
- All capabilities dropped
- Read-only root filesystem
- Resource limits prevent DoS
- No privileged mode

#### Data Security
- Model files mounted read-only
- Workspace directories have restricted access
- Temporary files use size-limited tmpfs
- Log rotation prevents disk filling

## Technical Architecture

### Core Components

1. **🧠 Local LLM** - AI inference engine (Phi-3/Mistral/Llama)
2. **⚙️ llama.cpp** - High-performance inference backend
3. **🌐 Flask API** - HTTP interface for programmatic access
4. **🐳 Docker Container** - Isolated execution environment per instance
5. **💻 CLI Tools** - Command-line interfaces for interaction
6. **🔗 Multi-Instance Orchestration** - Docker Compose coordination

### Container Specifications (Per Instance)

- **Base**: Ubuntu 22.04 (minimal)
- **User**: Non-root (`llmuser:1000`)
- **Memory**: Variable by instance (4GB-8GB limit)
- **CPU**: Variable by instance (2-4 cores limit)
- **Storage**: Read-only root filesystem
- **Network**: Isolated bridge network per instance

### Multi-Instance Network Architecture

```
Host System (macOS/Linux)
├── Port 5001 → General Instance (Phi-3)     [172.25.1.0/24]
├── Port 5002 → Coding Instance (Mistral-7B) [172.25.2.0/24]
└── Port 5003 → Chat Instance (Llama-3 8B)   [172.25.3.0/24]
```

## Performance Optimizations

### System Benefits

- **67% smaller per instance**: 4GB vs 12GB complex systems
- **Faster startup**: 30 seconds vs 2 minutes per instance
- **Lower memory per instance**: 2-8GB vs 12GB+ RAM usage
- **Fewer processes**: 3 vs 20+ running processes per instance
- **Horizontal scaling**: Add instances as needed

### Multi-Instance Benefits

- **Task specialization**: Optimal model for each task type
- **Parallel processing**: Handle multiple requests simultaneously
- **Resource optimization**: Scale individual instances based on load
- **Fault isolation**: One instance failure doesn't affect others

### Maintenance Benefits

- **Simpler debugging**: Fewer components per instance to troubleshoot
- **Easier updates**: Update individual instances independently
- **Cleaner logs**: Instance-specific logging
- **Faster backups**: Instance-specific configuration backup

### Instance Selection Strategy

Choose instances based on your primary use case:

**For Development Work**:
```bash
# Start coding + general instances
./automate_multi_instance.sh start coding
./automate_multi_instance.sh start general
```

**For Creative Tasks**:
```bash  
# Start chat + general instances
./automate_multi_instance.sh start chat
./automate_multi_instance.sh start general
```

**For Mixed Workloads**:
```bash
# Start all instances (requires 12GB+ RAM)
./automate_multi_instance.sh start
```

### Resource Monitoring

```bash
# Check container resource usage
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check instance health
./automate_multi_instance.sh health

# Monitor logs for performance issues
./automate_multi_instance.sh logs coding
```

## Troubleshooting

### Single Instance Issues

- **Port in use**: Check if port 5001 is available
- **Model not found**: Verify model file exists in `models/`
- **Memory issues**: Ensure sufficient RAM for selected model
- **Permission errors**: Check Docker permissions

### Multi-Instance Issues

**Port Already in Use**:
```bash
# Check what's using the port
lsof -i :5001
sudo netstat -tulpn | grep :5001

# Kill conflicting process or use different ports
```

**Out of Memory**:
```bash
# Check memory usage
free -h
docker stats

# Stop unnecessary instances
./automate_multi_instance.sh stop chat  # Largest instance
```

**Container Won't Start**:
```bash
# Check logs for errors  
./automate_multi_instance.sh logs general

# Rebuild if needed
docker-compose -f docker-compose.multi-instance.yml build --no-cache
```

**Model Download Failed**:
```bash
# Re-download specific model
rm models/mistral-7b.gguf
./setup_multi_instance.sh  # Will re-download missing models
```

### Debug Commands

#### Single Instance

```bash
# Check container status
./automate_local_llm.sh status

# View detailed logs
./automate_local_llm.sh logs

# Health check
./automate_local_llm.sh health

# Test API connectivity
curl http://localhost:5001/api/agent
```

#### Multi-Instance

```bash
# Check all instances
docker ps --filter "name=simplebrain"

# View instance logs
docker logs simplebrain-general-phi3
docker logs simplebrain-coding-mistral
docker logs simplebrain-chat-llama3

# Health checks
curl http://localhost:5001/health
curl http://localhost:5002/health
curl http://localhost:5003/health

# Resource usage
docker stats --filter "name=simplebrain"

# Network inspection
docker network ls | grep simplebrain
docker network inspect simplebrain-general-net

# Full system health check
./automate_multi_instance.sh health

# Check specific instance
curl -s http://localhost:5001 && echo "✓ General OK" || echo "✗ General Failed"
curl -s http://localhost:5002 && echo "✓ Coding OK" || echo "✗ Coding Failed"  
curl -s http://localhost:5003 && echo "✓ Chat OK" || echo "✗ Chat Failed"

# Check Docker resources
docker system df
docker system events --since '1h' --filter container=simplebrain
```

## Migration Guide

### Switching Between Deployment Modes

#### From Single Instance to Multi-Instance

**Step 1: Stop Single Instance**
```bash
# Stop the single instance
./automate_local_llm.sh stop

# Or using docker-compose directly
docker-compose -f docker-compose.local-llm.yml down
```

**Step 2: Start Multi-Instance**
```bash
# Start all multi-instance containers
docker-compose -f docker-compose.multi-instance.yml up -d

# Or start specific instances only
docker-compose -f docker-compose.multi-instance.yml up -d simplebrain-general-phi3 simplebrain-coding-mistral
```

**Step 3: Verify Multi-Instance is Running**
```bash
# Check all instances are running
docker ps --filter "name=simplebrain"

# Health check all instances
./ask_llm.sh health
```

**Step 4: Use Multi-Instance Client Tools**
```bash
# Use the multi-instance clients
./ask_llm.sh general "What is AI?"
./ask_llm.sh coding "Write a Python function"
python3 ask_llm.py --interactive
```

#### From Multi-Instance to Single Instance

**Step 1: Stop Multi-Instance Containers**
```bash
# Stop all multi-instance containers
docker-compose -f docker-compose.multi-instance.yml down

# Or stop using the management script
./automate_multi_instance.sh stop
```

**Step 2: Start Single Instance**
```bash
# Start single instance
./automate_local_llm.sh start

# Or using docker-compose directly
docker-compose -f docker-compose.local-llm.yml up -d
```

**Step 3: Verify Single Instance is Running**
```bash
# Check single instance is running
docker ps --filter "name=local-llm"

# Health check
./automate_local_llm.sh health
```

**Step 4: Use Single Instance Client Tools**
```bash
# Use the single-instance clients
./ask_agent.sh "What is AI?"
./cli_agent.py
./llama_direct.sh "Your question"
```

#### Key Differences Between Modes

**Port Usage:**
- **Single Instance**: Only uses port `5001`
- **Multi-Instance**: Uses ports `5001`, `5002`, `5003` for different models

**Client Tools:**
- **Single Instance**: Use `ask_agent.sh`, `cli_agent.py`, `llama_direct.sh`
- **Multi-Instance**: Use `ask_llm.sh`, `ask_llm.py`, `llama_direct_multi.sh`

**Docker Compose Files:**
- **Single Instance**: `docker-compose.local-llm.yml`
- **Multi-Instance**: `docker-compose.multi-instance.yml`

**Resource Usage:**
- **Single Instance**: ~4GB RAM, 1 model active
- **Multi-Instance**: ~12GB RAM, multiple models active simultaneously

#### Quick Status Check

To see which mode you're currently in:

```bash
# Check what's running
docker ps --filter "name=simplebrain" --filter "name=local-llm"

# If you see 'local-llm' → Single Instance Mode
# If you see 'simplebrain-*' containers → Multi-Instance Mode
```

### From Single to Multi-Instance (Legacy)

**Step 1: Ensure you have sufficient resources**

```bash
# Check available memory (need 12GB+ for all instances)
free -h
```

**Step 2: Deploy multi-instance setup**

```bash
docker-compose -f docker-compose.multi-instance.yml up -d
```

**Step 3: Test all instances**

```bash
curl http://localhost:5001/health
curl http://localhost:5002/health  
curl http://localhost:5003/health
```

**Step 4: Use specialized endpoints**

```bash
# General tasks → port 5001
# Coding tasks → port 5002
# Conversations → port 5003
```

### From Complex to SimpleBrain

**Step 1: Stop existing environment**

```bash
docker-compose down
```

**Step 2: Use SimpleBrain setup**

```bash
./setup_local_llm.sh
```

**Step 3: Choose deployment type**

```bash
# Single instance
./automate_local_llm.sh start

# OR Multi-instance
docker-compose -f docker-compose.multi-instance.yml up -d
```

**Step 4: Same CLI interfaces work**

```bash
./ask_agent.sh "your question"
./cli_agent.py
```

## Advanced Usage

### Scaling and Customization

#### Adding New Instances

1. **Update Configuration**:
   ```bash
   # Add to automate_multi_instance.sh INSTANCES array
   ["custom"]="5004:custom-model.gguf:4G:custom tasks"
   ```

2. **Update Docker Compose**:
   ```yaml
   # Add new service to docker-compose.multi-instance.yml
   simplebrain-custom-model:
     # ... configuration similar to existing services
   ```

3. **Create Instance Directory**:
   ```bash
   ./automate_multi_instance.sh start custom
   ```

#### Custom Model Support

1. **Download Model**:
   ```bash
   wget -O models/custom-model.gguf https://example.com/model.gguf
   ```

2. **Create Instance**:
   ```bash
   mkdir -p instances/custom/{workspace,models,local_agent_workspace}
   cp -r local_agent_workspace/* instances/custom/local_agent_workspace/
   ln -sf ../../models/custom-model.gguf instances/custom/models/
   ```

3. **Update Configuration**:
   - Add instance to `INSTANCES` array in automation script
   - Add service to Docker Compose file
   - Update CLI auto-selection logic

#### Custom Instance Configuration

You can modify `docker-compose.multi-instance.yml` to:

- Add more instances with different models
- Adjust resource limits per instance
- Change port mappings
- Modify network configurations

### Load Balancing

For production use, consider adding a load balancer in front of instances:

```bash
# Example with nginx
upstream simplebrain_general {
    server localhost:5001;
}
upstream simplebrain_coding {
    server localhost:5002;
}
upstream simplebrain_chat {
    server localhost:5003;
}
```

### Monitoring

Monitor all instances with a single dashboard:

```bash
# Resource monitoring
docker stats --filter "name=simplebrain" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Health monitoring
for port in 5001 5002 5003; do
  echo "Port $port: $(curl -s http://localhost:$port/health | jq -r .status)"
done
```

## Web Interface

### LLM Showcase (Browser GUI)

SimpleBrain includes a web-based chat interface for easy interaction with your local AI models through any modern web browser.

#### Architecture & Features

**Core Components:**
- **Frontend**: Single-page HTML application with vanilla JavaScript
- **Backend**: Direct REST API calls to SimpleBrain instances
- **Models**: Support for Phi3 (port 5001) and Mistral (port 5002)
- **Real-time Chat**: Interactive conversation interface with message history
- **Health Monitoring**: Built-in connectivity testing for all models

**Key Features:**
- 🌐 **Browser-based**: No additional software installation required
- 🔄 **Model Switching**: Dynamic selection between available AI models
- 💬 **Chat Interface**: Clean, responsive conversation UI
- 🔍 **Health Checks**: Real-time model availability testing
- 📱 **Responsive Design**: Works on desktop and mobile browsers
- ⚡ **Direct API Access**: No proxy or intermediate services

#### Usage Examples

**Basic Setup:**

```bash
# 1. Start your SimpleBrain instances
docker-compose -f docker-compose.multi-instance.yml up -d

# 2. Verify models are running
./ask_llm.sh health

# 3. Open the web interface
# Option A: Direct file access
open llm-showcase.html

# Option B: Local HTTP server (recommended for CORS compatibility)
python3 -m http.server 8000
# Then visit: http://localhost:8000/llm-showcase.html
```

**Interactive Usage:**

1. **Model Selection**: Choose between Phi3 (General) or Mistral (Coding)
2. **Chat Interface**: Type questions and press Enter or click Send
3. **Health Check**: Click the green "Health Check" button to test connectivity
4. **Clear Chat**: Reset conversation history anytime

**Example Conversations:**

```
User: What is machine learning?
Phi3 (General): Machine learning is a subset of artificial intelligence that enables computers to learn and make decisions from data...

User: [Switch to Mistral (Coding)]
User: Write a Python function to sort a list
Mistral (Coding): Here's a Python function to sort a list:

def sort_list(data, reverse=False):
    return sorted(data, reverse=reverse)

# Usage examples:
numbers = [3, 1, 4, 1, 5]
print(sort_list(numbers))  # [1, 1, 3, 4, 5]
```

#### Troubleshooting

**Common Issues & Solutions:**

**1. "Failed to fetch" Error**
```
Symptom: Connection failed - Failed to fetch
Cause:   CORS restrictions in browser
Solution:
# Use local HTTP server instead of file:// protocol
python3 -m http.server 8000
# Access via: http://localhost:8000/llm-showcase.html
```

**2. "Connection failed" Messages**
```
Symptom: ❌ Phi3 (General): Connection failed
Cause:   SimpleBrain services not running
Solution:
# Check service status
./ask_llm.sh health
docker ps --filter "name=simplebrain"

# Start services if needed
docker-compose -f docker-compose.multi-instance.yml up -d
```

**3. HTTP Error Codes**
```
Symptom: ⚠️ Mistral (Coding): HTTP 500
Cause:   Model loading or API errors
Solution:
# Check container logs
docker logs simplebrain-coding-mistral

# Restart problematic service
docker restart simplebrain-coding-mistral
```

**4. Browser Compatibility Issues**
```
Symptom: Interface not loading properly
Cause:   Outdated browser or JavaScript disabled
Solution:
# Use modern browsers: Chrome 80+, Firefox 75+, Safari 13+
# Ensure JavaScript is enabled
# Clear browser cache and reload
```

**Advanced Troubleshooting:**

**Network Connectivity Testing:**
```bash
# Test API endpoints directly
curl http://localhost:5001/health  # Phi3
curl http://localhost:5002/health  # Mistral

# Test API functionality
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "Hello"}' \
  http://localhost:5001/api/agent
```

**CORS Configuration:**
```bash
# For production deployment, consider nginx proxy:
location /api/ {
    proxy_pass http://localhost:5001/;
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    add_header Access-Control-Allow-Headers "Content-Type";
}
```

**Performance Optimization:**
```bash
# Check model resource usage
docker stats --filter "name=simplebrain"

# Monitor response times in browser developer tools
# Network tab shows API call timing
```

#### Technical Implementation

**Frontend Architecture:**
- Pure HTML5/CSS3/JavaScript (no frameworks)
- Responsive design with CSS Flexbox
- Fetch API for HTTP requests
- DOM manipulation for real-time updates

**API Integration:**
- RESTful communication with SimpleBrain APIs
- JSON request/response handling  
- Error handling and user feedback
- Automatic health monitoring on page load

**Security Considerations:**
- Client-side only (no server-side code)
- Direct localhost API calls
- No external dependencies or CDNs
- CORS-aware implementation

#### Customization Options

**Adding New Models:**
```javascript
// Update modelSelect options in llm-showcase.html
<option value="5003">Llama3 (Chat)</option>

// Add to health check models array
const models = [
    { port: '5001', name: 'Phi3 (General)' },
    { port: '5002', name: 'Mistral (Coding)' },
    { port: '5003', name: 'Llama3 (Chat)' }
];
```

**Styling Customization:**
```css
/* Modify colors, fonts, layout in <style> section */
.message.user { background: #E3F2FD; }     /* User messages */
.message.assistant { background: #F5F5F5; }  /* AI responses */
button { background: #007AFF; }              /* Button colors */
```

**Feature Extensions:**
- Message export functionality
- Conversation persistence
- Multiple chat sessions
- File upload support
- Voice input/output
- Custom system prompts

#### Integration with CLI Tools

The web interface complements CLI tools perfectly:

```bash
# Use CLI for scripting and automation
./ask_llm.sh coding "Generate unit tests for this function"

# Use web interface for:
# - Interactive exploration
# - Quick model testing  
# - Non-technical users
# - Visual conversation history
```

#### Deployment Options

**Development:**
```bash
# Simple file access (may have CORS issues)
open llm-showcase.html
```

**Local Testing:**
```bash
# Python HTTP server
python3 -m http.server 8000

# Node.js HTTP server  
npx http-server . -p 8000

# PHP HTTP server
php -S localhost:8000
```

**Production:**
```nginx
# Nginx configuration example
server {
    listen 80;
    root /path/to/simplebrain;
    index llm-showcase.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:5001/;
        add_header Access-Control-Allow-Origin *;
    }
}
```

## Quick Reference

### Essential Commands

| Command | Description |
|---------|-------------|
| `docker-compose -f docker-compose.multi-instance.yml up -d` | Start all instances |
| `./ask_llm.sh health` | Health check all instances |
| `./ask_llm.sh general "question"` | Ask Phi-3 (fast, general) |
| `./ask_llm.sh coding "question"` | Ask Mistral-7B (programming) |
| `./ask_llm.sh chat "question"` | Ask Llama-3 (conversations) |
| `python3 ask_llm.py --interactive` | Interactive mode with LLM switching |
| `docker ps --filter "name=simplebrain"` | Check running containers |
| `docker-compose -f docker-compose.multi-instance.yml down` | Stop all instances |

### Client Tools Quick Start

| Tool | Best For | Example |
|------|----------|---------|
| `ask_llm.sh` | Quick questions, scripting | `./ask_llm.sh coding "Fix this Python code"` |
| `ask_llm.py` | Interactive sessions | `python3 ask_llm.py --interactive` |
| `ask_agent.sh` | Legacy single instance | `./ask_agent.sh "General question"` |
| `cli_agent.py` | Legacy interactive | `./cli_agent.py` |

### Port Reference

| Port | Instance | Model | Use Case |
|------|----------|-------|----------|
| 5001 | General | Phi-3 Mini 4K | Quick questions, general tasks |
| 5002 | Coding | Mistral-7B | Programming, code review |
| 5003 | Chat | Llama-3 8B | Conversations, analysis |

---

**SimpleBrain** - Your personal AI assistant, simplified and optimized for both single and multi-instance deployment! 🧠✨

*Now featuring multi-instance architecture for specialized AI workloads!*