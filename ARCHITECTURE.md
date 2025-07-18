# SimpleBrain Architecture

## Overview

SimpleBrain is a self-contained, lightweight local AI assistant system designed for offline operation with minimal dependencies. It provides a complete AI inference stack using llama.cpp for local model execution and a Flask-based REST API for interaction.

## 🏗️ System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        SimpleBrain System                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  CLI Interfaces │  │   Flask API     │  │  Local Models   │  │
│  │                 │  │                 │  │                 │  │
│  │ • ask_agent.sh  │  │ • REST API      │  │ • Phi-3 Mini    │  │
│  │ • cli_agent.py  │  │ • Port 5001     │  │ • Mistral 7B    │  │
│  │ • llama_direct  │  │ • JSON I/O      │  │ • Llama 3 8B    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│           │                     │                     │         │
│           └─────────────────────┼─────────────────────┘         │
│                                 │                               │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    Docker Container                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │    Flask    │  │ llama.cpp   │  │    Security Layer   │  │  │
│  │  │  Web Server │  │  Inference  │  │                     │  │  │
│  │  │             │  │   Engine    │  │ • Non-root user     │  │  │
│  │  │ • HTTP API  │  │             │  │ • Read-only FS      │  │  │
│  │  │ • JSON      │  │ • GGUF      │  │ • Resource limits   │  │  │
│  │  │ • Routing   │  │ • CPU only  │  │ • Network isolation │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Input → CLI/API → Flask Router → LLM Interface → llama.cpp → Model
    ↓                                                                 ↓
Response ← JSON API ← Response Parser ← Command Executor ← LLM Output
```

## 🧩 Component Details

### 1. Container Infrastructure

**Base Image**: Ubuntu 22.04
- **Purpose**: Provides stable foundation with all required dependencies
- **Security**: Hardened with non-root user, read-only filesystem, resource limits
- **Isolation**: Custom bridge network with restricted inter-container communication

### 2. AI Inference Engine

**llama.cpp**
- **Purpose**: High-performance CPU-based LLM inference
- **Models**: Supports GGUF format quantized models
- **Features**: Multi-threading, memory mapping, optimized kernels
- **Integration**: Called via Python subprocess interface

### 3. Application Layer

**Flask Web Server**
- **Purpose**: HTTP API for AI interactions
- **Port**: 5001 (external) → 5000 (internal)
- **Endpoints**: `/api/agent` (POST)
- **Format**: JSON request/response

**Python Components**:
- `app.py`: Main Flask application
- `llm_interface.py`: LLM communication layer
- `agent_actions.py`: Command execution (disabled for security)
- `cli.py`: Command-line interface

### 4. Model Management

**Multi-Model Support**:
- Current model: `models/model.gguf` (symlink)
- Available models: `phi3-mini-4k.gguf`, `mistral-7b.gguf`, `llama3-8b.gguf`
- Switching: Automated via `switch_model.sh`

### 5. CLI Interfaces

**User-Facing Scripts**:
- `ask_agent.sh`: Single-question interface
- `cli_agent.py`: Interactive chat session
- `llama_direct.sh`: Direct model access

## 🔧 Technical Specifications

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 4GB | 8GB+ |
| CPU | 2 cores | 4+ cores |
| Storage | 6GB | 10GB+ |
| Network | None (offline) | Optional |

### Model Specifications

| Model | Size | RAM Usage | Context | Speed |
|-------|------|-----------|---------|-------|
| Phi-3 Mini | 2.4GB | 4GB | 4K tokens | Fast |
| Mistral 7B | 4.1GB | 6GB | 8K tokens | Medium |
| Llama 3 8B | 4.6GB | 8GB | 8K tokens | Slower |

### Security Architecture

**Container Security**:
- Non-root user (uid: 1000)
- Read-only root filesystem
- Dropped capabilities (CAP_DROP: ALL)
- Resource limits (CPU: 4 cores, RAM: 6GB)
- Network isolation (custom bridge)

**Data Security**:
- Model files: Read-only mounts
- Workspace: Restricted write access
- Temporary files: tmpfs with size limits
- Logging: Size-limited rotation

## 🔄 Operational Flow

### Startup Sequence

1. **Container Initialization**
   - Load Ubuntu 22.04 base image
   - Install dependencies (Python, build tools)
   - Create non-root user environment

2. **Service Preparation**
   - Mount volume directories
   - Verify model file existence
   - Initialize Flask application

3. **Runtime State**
   - Flask server listening on port 5000
   - llama.cpp ready for inference
   - CLI tools available for interaction

### Request Processing

1. **Input Reception**
   - CLI tool or HTTP request
   - JSON payload with prompt

2. **LLM Processing**
   - Prompt formatting and context addition
   - llama.cpp subprocess execution
   - Response generation with token limits

3. **Response Handling**
   - Command parsing (if applicable)
   - Security validation
   - JSON response formatting

## 📦 File Structure

```
simplebrain/
├── Dockerfile.local-llm           # Container definition
├── docker-compose.local-llm.yml   # Orchestration config
├── automate_local_llm.sh          # Main automation script
├── setup_local_llm.sh             # One-time setup
├── health_check_llm.sh            # Health monitoring
├── switch_model.sh                # Model switching
├── ask_agent.sh                   # Quick CLI interface
├── cli_agent.py                   # Interactive interface
├── llama_direct.sh                # Direct model access
├── models/                        # AI model files
│   ├── model.gguf                 # Current model (symlink)
│   ├── phi3-mini-4k.gguf          # Phi-3 Mini model
│   ├── mistral-7b.gguf            # Mistral 7B model
│   └── llama3-8b.gguf             # Llama 3 8B model
├── workspace/                     # llama.cpp build
│   ├── llama.cpp/                 # Source code
│   └── llama.cpp.tar.gz           # Source archive
├── local_agent_workspace/         # Flask application
│   ├── app.py                     # Main Flask app
│   ├── llm_interface.py           # LLM communication
│   ├── agent_actions.py           # Command handling
│   ├── cli.py                     # CLI interface
│   └── run_app.sh                 # Application launcher
├── README.md                      # User documentation
├── SIMPLIFIED_SYSTEM.md           # System details
└── ARCHITECTURE.md                # This file
```

## 🔐 Security Considerations

### Container Security

**Read-only Filesystem**:
- Root filesystem mounted read-only
- Writable areas limited to tmpfs
- Prevents persistence of malicious changes

**Resource Limits**:
- CPU: 4 cores maximum
- Memory: 6GB maximum
- PIDs: 300 maximum
- Prevents resource exhaustion attacks

**Network Isolation**:
- Custom bridge network
- Inter-container communication disabled
- Limited to necessary port exposure

### Application Security

**Command Execution**:
- Disabled by default for security
- Input validation and sanitization
- Restricted command whitelist (if enabled)

**Model Security**:
- Read-only model file access
- Validated model formats (GGUF)
- No external model downloads in runtime

## 🚀 Deployment Architecture

### Single-Host Deployment

```
Host System (macOS/Linux)
├── Docker Engine
└── SimpleBrain Container
    ├── Flask API Server
    ├── llama.cpp Engine
    └── Model Files
```

### Development Workflow

1. **Setup**: Run `setup_local_llm.sh`
2. **Development**: Use `automate_local_llm.sh start`
3. **Testing**: Access via CLI tools or HTTP API
4. **Monitoring**: Check health with `health_check_llm.sh`
5. **Shutdown**: Use `automate_local_llm.sh stop`

## 🔧 Configuration Management

### Environment Variables

```bash
PYTHONPATH=/app                    # Python module path
MODEL_PATH=/app/models/model.gguf  # Current model path
FLASK_ENV=development              # Flask environment
FLASK_APP=app.py                   # Flask application
```

### Volume Mounts

```yaml
./workspace → /app/workspace        # llama.cpp build (RW)
./models → /app/models              # Model files (RO)
./local_agent_workspace → /app/local_agent  # Flask app (RW)
```

## 📊 Performance Characteristics

### Inference Performance

- **Phi-3 Mini**: ~20-30 tokens/second
- **Mistral 7B**: ~10-15 tokens/second
- **Llama 3 8B**: ~8-12 tokens/second

### Memory Usage

- **Base container**: ~500MB
- **Plus model**: +2-5GB depending on model
- **Peak usage**: Model size + 1-2GB buffer

### Startup Time

- **Container start**: ~5-10 seconds
- **Model loading**: ~10-30 seconds
- **First inference**: ~2-5 seconds

## 🎯 Design Principles

### Simplicity
- Minimal dependencies
- Single-purpose components
- Clear separation of concerns

### Security
- Defense in depth
- Least privilege access
- Isolated execution environment

### Performance
- CPU-optimized inference
- Memory-efficient models
- Fast startup and response

### Maintainability
- Modular architecture
- Clear interfaces
- Comprehensive logging

---

**SimpleBrain Architecture** - Designed for simplicity, security, and performance! 🧠✨