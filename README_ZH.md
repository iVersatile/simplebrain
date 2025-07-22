# SimpleBrain - 本地 AI 助手

一个简化、轻量级的本地大语言模型系统，专为离线AI助手优化，无需云端依赖。现在支持**多实例部署**，可同时运行多个AI模型。

## 🚀 快速开始

### 单实例部署（传统模式）

```bash
# 设置（一次性）
./setup_local_llm.sh

# 启动你的AI助手
./automate_local_llm.sh start

# 使用你的AI助手
./ask_agent.sh "什么是机器学习？"
./cli_agent.py  # 交互模式
```

### 多实例部署（全新！）

```bash
# 部署多个不同模型的容器
docker-compose -f docker-compose.multi-instance.yml up -d

# 使用智能客户端工具定向特定LLM
./ask_llm.sh general "什么是机器学习？"        # Phi-3 (快速，通用)
./ask_llm.sh coding "写一个Python函数"           # Mistral-7B (编程)
./ask_llm.sh chat "告诉我一个关于机器人的故事"        # Llama-3 (对话)

# LLM切换的交互模式
python3 ask_llm.py --interactive

# 检查所有实例健康状态
./ask_llm.sh health
```

## 特性

- **🧠 本地AI**: 通过llama.cpp推理支持多模型
- **🔒 无云端依赖**: 完全离线运行
- **⚡ 轻量级**: 4GB总占用空间（对比复杂系统的12GB）
- **🛡️ 安全**: 容器化安全加固
- **🔧 简单**: 易于使用和维护
- **🔄 多模型**: 即时切换不同AI模型
- **🏗️ 多实例**: 在不同端口同时运行多个模型
- **🎯 专用实例**: 针对不同用例的专用容器
- **🛠️ 智能客户端工具**: 智能LLM选择和交互式聊天模式

## 项目结构

```
SimpleBrain/
├── 核心脚本
│   ├── setup_local_llm.sh                 # 一次性设置和容器构建
│   ├── automate_local_llm.sh              # 环境管理
│   ├── automate_multi_instance.sh         # 多实例管理 (新增!)
│   └── health_check_llm.sh                # 系统健康监控
├── CLI 接口
│   ├── ask_llm.sh                         # 多LLM客户端 (新增!)
│   ├── ask_llm.py                         # 多LLM Python客户端 (新增!)
│   ├── llama_direct_multi.sh              # 直接多LLM访问 (新增!)
│   ├── ask_agent.sh                       # 单实例CLI
│   ├── cli_agent.py                       # 交互式聊天界面
│   └── llama_direct.sh                    # 直接LLM访问 (仅单实例)
├── 配置
│   ├── Dockerfile.local-llm               # 最小化容器定义
│   ├── docker-compose.local-llm.yml       # 单实例编排
│   └── docker-compose.multi-instance.yml  # 多实例编排 (新增!)
├── 数据目录
│   ├── models/                            # AI模型文件 (实例间共享)
│   ├── workspace/                         # llama.cpp构建目录
│   ├── local_agent_workspace/             # Flask API应用程序
│   └── instances/                         # 实例特定配置 (新增!)
│       ├── general/                       # 通用目的实例
│       ├── coding/                        # 编程协助实例
│       └── chat/                          # 对话实例
└── 启动脚本
    ├── startup.sh                         # 全功能启动脚本
    └── startup_simple.sh                  # 轻量级启动脚本
```

## 多实例架构

### 实例配置

| 实例 | 端口 | 模型 | 大小 | 最适合 | 内存 | 网络 |
|----------|------|-------|------|----------|--------|---------|
| **general** | 5001 | Phi-3 Mini 4K | 2.4GB | 通用任务，问答 | 4GB RAM | 172.25.1.0/24 |
| **coding** | 5002 | Mistral 7B | 4.1GB | 编程，调试 | 6GB RAM | 172.25.2.0/24 |
| **chat** | 5003 | Llama 3 8B | 4.6GB | 对话，创意写作 | 8GB RAM | 172.25.3.0/24 |

### 命名约定

- **Docker镜像**: `simplebrain-{model}:v1.0` (如 `simplebrain-phi3:v1.0`)
- **容器**: `simplebrain-{instance}-{model}` (如 `simplebrain-coding-mistral`)
- **网络**: `simplebrain-{instance}-net` (如 `simplebrain-coding-net`)
- **目录**: `./instances/{instance}/` (如 `./instances/coding/`)

### 多实例目录结构

```
simplebrain/
├── 📁 instances/
│   ├── 📁 general/          # Phi-3 实例
│   │   ├── workspace/       # llama.cpp 构建
│   │   ├── models/          # 模型符号链接
│   │   └── local_agent_workspace/  # Flask 应用
│   ├── 📁 coding/           # Mistral 实例
│   └── 📁 chat/             # Llama-3 实例
├── 📁 models/               # 共享模型文件
│   ├── phi3-mini-4k.gguf
│   ├── mistral-7b.gguf
│   └── llama3-8b.gguf
├── 🐳 docker-compose.multi-instance.yml
├── 🔧 automate_multi_instance.sh
├── 💬 ask_agent_multi.sh
└── ⚙️ setup_multi_instance.sh
```

### 网络隔离

每个实例在自己的隔离Docker网络中运行以确保安全。

### 多实例管理

#### Docker Compose 命令

```bash
# 启动所有实例
docker-compose -f docker-compose.multi-instance.yml up -d

# 启动特定实例
docker-compose -f docker-compose.multi-instance.yml up -d simplebrain-general-phi3 simplebrain-coding-mistral

# 检查状态
docker ps --filter "name=simplebrain"

# 查看日志
docker logs simplebrain-general-phi3
docker logs simplebrain-coding-mistral
docker logs simplebrain-chat-llama3

# 健康检查
curl http://localhost:5001/health  # 通用实例
curl http://localhost:5002/health  # 编程实例  
curl http://localhost:5003/health  # 聊天实例

# 停止所有实例
docker-compose -f docker-compose.multi-instance.yml down
```

#### 管理脚本命令

```bash
# 启动特定实例
./automate_multi_instance.sh start general
./automate_multi_instance.sh start coding  
./automate_multi_instance.sh start chat

# 启动所有实例
./automate_multi_instance.sh start

# 停止特定实例
./automate_multi_instance.sh stop coding

# 停止所有实例
./automate_multi_instance.sh stop

# 重启实例
./automate_multi_instance.sh restart general

# 显示状态
./automate_multi_instance.sh status

# 健康检查
./automate_multi_instance.sh health

# 显示日志
./automate_multi_instance.sh logs coding

# 列出可用实例
./automate_multi_instance.sh list

# 清理所有内容
./automate_multi_instance.sh cleanup
```

## 客户端工具

SimpleBrain提供多种客户端工具，可轻松与不同LLM实例交互。

### 多LLM客户端工具（推荐）

#### Shell客户端 (`ask_llm.sh`)

针对特定LLM实例以获得最佳结果：

```bash
# 通用问题 (Phi-3 - 快速)
./ask_llm.sh general "什么是机器学习？"
./ask_llm.sh general "解释量子计算"

# 编程任务 (Mistral-7B - 最适合代码)
./ask_llm.sh coding "写一个Python排序函数"
./ask_llm.sh coding "调试这个JavaScript代码"
./ask_llm.sh coding "创建一个REST API端点"

# 对话 (Llama-3 8B - 最适合聊天)
./ask_llm.sh chat "告诉我一个关于太空探索的故事"
./ask_llm.sh chat "你对人工智能的看法是什么？"

# 健康检查
./ask_llm.sh health                           # 检查所有实例
```

#### Python客户端 (`ask_llm.py`)

**单个问题:**
```bash
python3 ask_llm.py general "什么是AI？"
python3 ask_llm.py coding "用Python排序列表"
python3 ask_llm.py chat "写一首关于技术的俳句"
```

**LLM切换的交互模式:**
```bash
python3 ask_llm.py --interactive

# 在交互模式内:
💬 You (general): 你好
🤖 Response: 你好! 我是Phi-3...

💬 You (general): switch coding
切换到 coding (Mistral-7B)

💬 You (coding): 写一个反转字符串的函数
🤖 Response: 这是一个Python函数...

💬 You (coding): switch chat  
切换到 chat (Llama-3 8B)

💬 You (chat): 告诉我AI的未来
🤖 Response: AI的未来...
```

**健康监控:**
```bash
python3 ask_llm.py --health                  # 检查所有实例
python3 ask_llm.py --health coding           # 检查特定实例
```

#### 直接LLM访问 (`llama_direct_multi.sh`)

绕过Flask API，直接与llama.cpp通信以获得更快响应：

```bash
# 直接访问特定模型 (最快性能)
./llama_direct_multi.sh general "什么是AI？"
./llama_direct_multi.sh coding "写一个排序函数"
./llama_direct_multi.sh chat "告诉我量子计算"

# 显示可用实例
./llama_direct_multi.sh help
```

**直接访问的优势:**
- **更快响应** - 无Flask API开销
- **原始模型输出** - 未处理的LLM响应
- **调试** - 查看模型加载信息和性能指标
- **测试** - 直接验证模型行为

#### 智能自动选择客户端 (`ask_agent_multi.sh`)

根据问题内容自动选择最佳LLM实例：

```bash
# 自动选择实例 (智能路由)
./ask_agent_multi.sh "我如何调试Python代码？"           # → coding
./ask_agent_multi.sh "告诉我量子计算"      # → general  
./ask_agent_multi.sh "给我写一首关于海洋的诗"      # → chat

# 指定特定实例
./ask_agent_multi.sh coding "解释Python中的async/await"
./ask_agent_multi.sh chat "你最喜欢的书是什么？"
./ask_agent_multi.sh general "什么导致下雨？"
```

**自动选择逻辑:**
- **编程关键词**: `code`, `python`, `function`, `debug`, `api`, `script` → **coding** 实例
- **创意关键词**: `story`, `creative`, `poem`, `chat`, `imagine` → **chat** 实例  
- **其他所有内容** → **general** 实例

### 实例选择指南

| 实例 | 模型 | 最适合 | 何时使用 |
|----------|-------|----------|-------------|
| **general** | Phi-3 Mini 4K | 快速问题，事实，解释 | 需要快速响应，通用知识 |
| **coding** | Mistral-7B | 编程，调试，技术任务 | 代码生成，技术文档 |
| **chat** | Llama-3 8B | 对话，创意写作 | 深入讨论，创意内容 |

## 网页界面

### LLM展示台（浏览器GUI）

SimpleBrain包含一个基于网页的聊天界面，可通过任何现代网页浏览器轻松与本地AI模型交互。

#### 架构与特性

**核心组件:**
- **前端**: 使用纯JavaScript的单页HTML应用
- **后端**: 直接REST API调用SimpleBrain实例
- **模型**: 支持Phi3 (端口5001) 和 Mistral (端口5002)
- **实时聊天**: 带消息历史的交互式对话界面
- **健康监控**: 内置所有模型的连接测试

**主要特性:**
- 🌐 **基于浏览器**: 无需安装额外软件
- 🔄 **模型切换**: 在可用AI模型间动态选择
- 💬 **聊天界面**: 清洁、响应式的对话UI
- 🔍 **健康检查**: 实时模型可用性测试
- 📱 **响应式设计**: 在桌面和移动浏览器上工作
- ⚡ **直接API访问**: 无代理或中间服务

#### 使用示例

**基本设置:**

```bash
# 1. 启动你的SimpleBrain实例
docker-compose -f docker-compose.multi-instance.yml up -d

# 2. 验证模型正在运行
./ask_llm.sh health

# 3. 打开网页界面
# 选项A: 直接文件访问
open llm-showcase.html

# 选项B: 本地HTTP服务器 (推荐用于CORS兼容性)
python3 -m http.server 8000
# 然后访问: http://localhost:8000/llm-showcase.html
```

**交互式使用:**

1. **模型选择**: 在Phi3 (通用) 或 Mistral (编程) 间选择
2. **聊天界面**: 输入问题并按Enter或点击发送
3. **健康检查**: 点击绿色"健康检查"按钮测试连接
4. **清除聊天**: 随时重置对话历史

#### 故障排除

**常见问题与解决方案:**

**1. "Failed to fetch" 错误**
```
症状: Connection failed - Failed to fetch
原因: 浏览器中的CORS限制
解决方案:
# 使用本地HTTP服务器而非file://协议
python3 -m http.server 8000
# 通过访问: http://localhost:8000/llm-showcase.html
```

**2. "连接失败" 消息**
```
症状: ❌ Phi3 (General): Connection failed
原因: SimpleBrain服务未运行
解决方案:
# 检查服务状态
./ask_llm.sh health
docker ps --filter "name=simplebrain"

# 如有需要启动服务
docker-compose -f docker-compose.multi-instance.yml up -d
```

## API访问

### 单实例API

系统在 `http://localhost:5001/api/agent` 提供HTTP API

### 多实例API

多个专用端点可用：

```bash
# 通用目的 (Phi-3)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "你好"}' \
  http://localhost:5001/api/agent

# 编程协助 (Mistral-7B)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "写一个排序算法"}' \
  http://localhost:5002/api/agent

# 对话 (Llama-3 8B)
curl -X POST -H "Content-Type: application/json" \
  -d '{"prompt": "讨论生命的意义"}' \
  http://localhost:5003/api/agent
```

### 健康端点

```bash
curl http://localhost:5001/health  # 通用实例健康
curl http://localhost:5002/health  # 编程实例健康
curl http://localhost:5003/health  # 聊天实例健康
```

## 多模型支持

SimpleBrain支持多个AI模型，你可以在它们之间切换或同时运行：

### 可用模型

| 模型 | 大小 | 最适合 | 速度 | 内存 | 多实例端口 |
|-------|------|----------|--------|--------|--------------------|
| **Phi-3 Mini** | 2.4GB | 通用任务，快速响应 | ⚡⚡⚡ | 4GB | 5001 |
| **Mistral 7B** | 4.1GB | 编程，数学，推理 | ⚡⚡ | 6GB | 5002 |
| **Llama 3 8B** | 4.6GB | 高质量对话 | ⚡⚡ | 8GB | 5003 |
| **Code Llama** | 4.0GB | 编程任务 | ⚡⚡ | 6GB | 自定义 |

### 模型切换（单实例）

#### 列出可用模型

```bash
./switch_model.sh list
```

#### 切换到不同模型

```bash
# 切换到Mistral进行编程
./switch_model.sh switch mistral-7b.gguf

# 切换到Llama 3进行对话
./switch_model.sh switch llama3-8b.gguf

# 切换回Phi-3以获得速度
./switch_model.sh switch phi3-mini-4k.gguf
```

### 下载额外模型

```bash
cd models/

# 下载Llama 3 8B
wget -O llama3-8b.gguf https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf

# 下载Code Llama
wget -O codellama-7b.gguf https://huggingface.co/bartowski/CodeLlama-7B-Instruct-GGUF/resolve/main/CodeLlama-7B-Instruct-v0.3-Q4_K_M.gguf

# 下载Mistral 7B
wget -O mistral-7b.gguf https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
```

### 模型推荐

- **🏃 快速问题**: 使用Phi-3 (端口5001) - 最快，最小
- **💻 编程帮助**: 使用Mistral 7B (端口5002) 或 Code Llama
- **🧠 深度对话**: 使用Llama 3 8B (端口5003) - 最佳质量
- **⚡ 低内存**: 使用Phi-3 (仅需4GB RAM)
- **🔧 开发**: 同时运行所有实例以处理不同任务

## 系统需求

### 硬件需求

| 配置 | 仅通用 | 通用 + 编程 | 所有实例 |
|---------------|-------------|------------------|---------------|
| **RAM** | 4GB+ | 8GB+ | 12GB+ |
| **CPU** | 2+ 核心 | 4+ 核心 | 6+ 核心 |
| **存储** | 6GB | 12GB | 18GB |

**推荐系统规格:**
- **内存**: 单实例4GB+ RAM，所有实例12GB+
- **存储**: 15GB+ 可用磁盘空间（用于所有模型和容器）
- **CPU**: 2+ 核心（多实例推荐8+）
- **架构**: macOS/Linux (ARM64/x86_64)

### 软件需求

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **操作系统**: macOS, Linux, 或 WSL2
- **curl**: 用于CLI工具
- **Python 3**: 用于脚本中的JSON解析

## 安全特性

### 容器安全

- **隔离**: 每个实例的沙盒Docker环境
- **非root执行**: 作为 `llmuser:1000` 运行
- **资源限制**: 每个实例的CPU、内存和PID约束
- **网络隔离**: 自定义桥接网络，禁用容器间通信
- **只读文件系统**: 防止未经授权的修改
- **能力丢弃**: 移除所有不必要的Linux能力

#### 每实例资源分配

**通用实例 (Phi-3)**:
- CPU: 最大2核心，保留0.5
- 内存: 最大4GB，保留1GB  
- 网络: `172.25.1.0/24`

**编程实例 (Mistral)**:
- CPU: 最大3核心，保留1
- 内存: 最大6GB，保留2GB
- 网络: `172.25.2.0/24`

**聊天实例 (Llama-3)**:
- CPU: 最大4核心，保留1.5
- 内存: 最大8GB，保留3GB
- 网络: `172.25.3.0/24`

### 隐私特性

- **100% 离线**: 不向外部服务发送数据
- **本地处理**: 所有AI推理在本地进行
- **无遥测**: 无使用跟踪或分析
- **安全存储**: 模型和数据本地存储
- **实例隔离**: 不同实例无法访问彼此的数据

## 技术架构

### 核心组件

1. **🧠 本地LLM** - AI推理引擎 (Phi-3/Mistral/Llama)
2. **⚙️ llama.cpp** - 高性能推理后端
3. **🌐 Flask API** - 程序化访问的HTTP接口
4. **🐳 Docker容器** - 每个实例的隔离执行环境
5. **💻 CLI工具** - 交互的命令行接口
6. **🔗 多实例编排** - Docker Compose协调

### 容器规格（每实例）

- **基础**: Ubuntu 22.04 (最小化)
- **用户**: 非root (`llmuser:1000`)
- **内存**: 按实例变化 (4GB-8GB限制)
- **CPU**: 按实例变化 (2-4核心限制)
- **存储**: 只读根文件系统
- **网络**: 每个实例的隔离桥接网络

### 多实例网络架构

```
主机系统 (macOS/Linux)
├── 端口 5001 → 通用实例 (Phi-3)     [172.25.1.0/24]
├── 端口 5002 → 编程实例 (Mistral-7B) [172.25.2.0/24]
└── 端口 5003 → 聊天实例 (Llama-3 8B)   [172.25.3.0/24]
```

## 性能优化

### 系统优势

- **每实例小67%**: 4GB vs 复杂系统的12GB
- **更快启动**: 每实例30秒 vs 2分钟
- **每实例更低内存**: 2-8GB vs 12GB+ RAM使用
- **更少进程**: 每实例3个 vs 20+个运行进程
- **横向扩展**: 根据需要添加实例

### 多实例优势

- **任务专业化**: 每种任务类型的最优模型
- **并行处理**: 同时处理多个请求
- **资源优化**: 基于负载扩展单个实例
- **故障隔离**: 一个实例故障不影响其他实例

### 维护优势

- **更简单调试**: 每个实例更少组件需要故障排除
- **更容易更新**: 独立更新单个实例
- **更清洁的日志**: 实例特定日志
- **更快备份**: 实例特定配置备份

## 故障排除

### 单实例问题

- **端口正在使用**: 检查端口5001是否可用
- **找不到模型**: 验证模型文件存在于 `models/`
- **内存问题**: 确保所选模型有足够RAM
- **权限错误**: 检查Docker权限

### 多实例问题

**端口已在使用**:
```bash
# 检查什么在使用端口
lsof -i :5001
sudo netstat -tulpn | grep :5001

# 终止冲突进程或使用不同端口
```

**内存不足**:
```bash
# 检查内存使用
free -h
docker stats

# 停止不必要的实例
./automate_multi_instance.sh stop chat  # 最大实例
```

**容器无法启动**:
```bash
# 检查错误日志  
./automate_multi_instance.sh logs general

# 如有需要重新构建
docker-compose -f docker-compose.multi-instance.yml build --no-cache
```

## 快速参考

### 基本命令

| 命令 | 描述 |
|---------|-------------|
| `docker-compose -f docker-compose.multi-instance.yml up -d` | 启动所有实例 |
| `./ask_llm.sh health` | 所有实例健康检查 |
| `./ask_llm.sh general "问题"` | 询问Phi-3 (快速，通用) |
| `./ask_llm.sh coding "问题"` | 询问Mistral-7B (编程) |
| `./ask_llm.sh chat "问题"` | 询问Llama-3 (对话) |
| `python3 ask_llm.py --interactive` | LLM切换的交互模式 |
| `docker ps --filter "name=simplebrain"` | 检查运行中的容器 |
| `docker-compose -f docker-compose.multi-instance.yml down` | 停止所有实例 |

### 客户端工具快速入门

| 工具 | 最适合 | 示例 |
|------|----------|---------|
| `ask_llm.sh` | 快速问题，脚本 | `./ask_llm.sh coding "修复这个Python代码"` |
| `ask_llm.py` | 交互会话 | `python3 ask_llm.py --interactive` |
| `ask_agent.sh` | 传统单实例 | `./ask_agent.sh "通用问题"` |
| `cli_agent.py` | 传统交互 | `./cli_agent.py` |

### 端口参考

| 端口 | 实例 | 模型 | 用例 |
|------|----------|-------|----------|
| 5001 | General | Phi-3 Mini 4K | 快速问题，通用任务 |
| 5002 | Coding | Mistral-7B | 编程，代码审查 |
| 5003 | Chat | Llama-3 8B | 对话，分析 |

---

**SimpleBrain** - 你的个人AI助手，简化并优化用于单实例和多实例部署！ 🧠✨

*现在具有专业AI工作负载的多实例架构功能!*