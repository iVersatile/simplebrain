# SimpleBrain - Local AI Assistant

A simplified, lightweight local LLM system optimized for offline AI assistance without cloud dependencies.

## 🚀 Quick Start

```bash
# Setup (one-time)
./setup_local_llm.sh

# Start your AI assistant
./automate_local_llm.sh start

# Use your AI assistant
./ask_agent.sh "What is machine learning?"
./cli_agent.py  # Interactive mode
```

## 🎯 Features

- **🧠 Local AI**: Multiple model support with llama.cpp inference
- **🔒 No Cloud Dependencies**: Runs entirely offline
- **⚡ Lightweight**: 4GB total footprint (vs 12GB complex systems)
- **🛡️ Secure**: Containerized with security hardening
- **🔧 Simple**: Easy to use and maintain
- **🔄 Multi-Model**: Switch between different AI models instantly

## 📁 Project Structure

```
SimpleBrain/
├── 🚀 Core Scripts
│   ├── setup_local_llm.sh          # One-time setup and container building
│   ├── automate_local_llm.sh       # Environment management
│   └── health_check_llm.sh         # System health monitoring
├── 💬 CLI Interfaces
│   ├── ask_agent.sh                # Quick question CLI
│   ├── cli_agent.py                # Interactive chat interface
│   └── llama_direct.sh             # Direct LLM access
├── 🐳 Configuration
│   ├── Dockerfile.local-llm        # Minimal container definition
│   └── docker-compose.local-llm.yml # Container orchestration
└── 📊 Data Directories
    ├── models/                     # AI model files (model.gguf)
    ├── workspace/                  # llama.cpp build directory
    └── local_agent_workspace/      # Flask API application
```

## 🔧 Usage Examples

### Basic Usage
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

### Management Commands
```bash
./automate_local_llm.sh install    # Install environment
./automate_local_llm.sh start      # Start AI assistant
./automate_local_llm.sh stop       # Stop AI assistant
./automate_local_llm.sh restart    # Restart AI assistant
./automate_local_llm.sh status     # Show status
./automate_local_llm.sh health     # Health check
./automate_local_llm.sh logs       # View logs
./automate_local_llm.sh clean      # Clean up
```

## 🌐 API Access

The system provides HTTP API at `http://localhost:5001/api/agent`

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "Hello"}' \
  http://localhost:5001/api/agent
```

## 🧠 Multi-Model Support

SimpleBrain supports multiple AI models that you can switch between instantly:

### Available Models

| Model | Size | Best For | Speed | Memory |
|-------|------|----------|--------|--------|
| **Phi-3 Mini** | 2.4GB | General tasks, Fast responses | ⚡⚡⚡ | 4GB |
| **Mistral 7B** | 4.1GB | Coding, Math, Reasoning | ⚡⚡ | 6GB |
| **Llama 3 8B** | 4.6GB | Quality conversations | ⚡⚡ | 8GB |
| **Code Llama** | 4.0GB | Programming tasks | ⚡⚡ | 6GB |

### 🔄 Model Switching

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

### 📥 Download Additional Models

```bash
cd models/

# Download Llama 3 8B
wget -O llama3-8b.gguf https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf

# Download Code Llama
wget -O codellama-7b.gguf https://huggingface.co/bartowski/CodeLlama-7B-Instruct-GGUF/resolve/main/CodeLlama-7B-Instruct-Q4_K_M.gguf

# Download Mistral 7B
wget -O mistral-7b.gguf https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
```

### 🎯 Model Recommendations

- **🏃 Quick Questions**: Use Phi-3 (fastest, smallest)
- **💻 Coding Help**: Use Mistral 7B or Code Llama
- **🧠 Deep Conversations**: Use Llama 3 8B (best quality)
- **⚡ Low Memory**: Use Phi-3 (only 4GB RAM needed)

## 📊 System Requirements

### Hardware
- **Memory**: 4GB+ RAM (6GB+ recommended)
- **Storage**: 6GB+ disk space
- **CPU**: 2+ cores (4+ recommended)
- **Architecture**: macOS/Linux (ARM64/x86_64)

### Software
- **Docker**: Latest version
- **Docker Compose**: v2.0+
- **Operating System**: macOS, Linux, or WSL2

## 🛡️ Security Features

### Container Security
- **Isolation**: Sandboxed Docker environment
- **Non-root execution**: Runs as `llmuser:1000`
- **Resource limits**: CPU, memory, and PID constraints
- **Network isolation**: Custom bridge network
- **Read-only filesystem**: Prevents unauthorized modifications

### Privacy Features
- **100% Offline**: No data sent to external services
- **Local Processing**: All AI inference happens locally
- **No Telemetry**: No usage tracking or analytics
- **Secure Storage**: Models and data stored locally

## 🔧 Technical Architecture

### Core Components
1. **🧠 Local LLM** - AI inference engine (Phi-3/Mistral/Llama)
2. **⚙️ llama.cpp** - High-performance inference backend
3. **🌐 Flask API** - HTTP interface for programmatic access
4. **🐳 Docker Container** - Isolated execution environment
5. **💻 CLI Tools** - Command-line interfaces for interaction

### Container Specifications
- **Base**: Ubuntu 22.04 (minimal)
- **User**: Non-root (`llmuser:1000`)
- **Memory**: 6GB limit, 2GB reserved
- **CPU**: 4 cores limit, 1 core reserved
- **Storage**: Read-only root filesystem
- **Network**: Isolated bridge network

## 🚀 Performance Optimizations

### System Benefits
- **67% smaller**: 4GB vs 12GB complex systems
- **Faster startup**: 30 seconds vs 2 minutes
- **Lower memory**: 2GB vs 6GB RAM usage
- **Fewer processes**: 3 vs 20+ running processes

### Maintenance Benefits
- **Simpler debugging**: Fewer components to troubleshoot
- **Easier updates**: Single LLM component to maintain
- **Cleaner logs**: Less noise in system logs
- **Faster backups**: Smaller configuration to backup

## 🛠️ Troubleshooting

### Common Issues
- **Port in use**: Check if port 5001 is available
- **Model not found**: Verify model file exists in `models/`
- **Memory issues**: Ensure sufficient RAM for selected model
- **Permission errors**: Check Docker permissions

### Debug Commands
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

## 📋 Migration Guide

### From Complex to SimpleBrain

1. **Stop existing environment**
   ```bash
   docker-compose down
   ```

2. **Use SimpleBrain setup**
   ```bash
   ./setup_local_llm.sh
   ```

3. **Start SimpleBrain**
   ```bash
   ./automate_local_llm.sh start
   ```

4. **Same CLI interfaces work**
   ```bash
   ./ask_agent.sh "your question"
   ./cli_agent.py
   ```

---

**SimpleBrain** - Your personal AI assistant, simplified and optimized! 🧠✨