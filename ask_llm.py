#!/usr/bin/env python3

import requests
import json
import sys
import argparse

# LLM Instance Configuration
INSTANCES = {
    'general': {
        'port': 5001,
        'model': 'Phi-3 Mini 4K',
        'description': 'Fast general tasks and questions'
    },
    'coding': {
        'port': 5002,
        'model': 'Mistral-7B',
        'description': 'Programming and development tasks'
    },
    'chat': {
        'port': 5003,
        'model': 'Llama-3 8B',
        'description': 'Conversations and creative writing'
    }
}

# Colors for terminal output
class Colors:
    CYAN = '\033[0;36m'
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'

def check_health(instance_name=None):
    """Check health of LLM instances"""
    print(f"{Colors.CYAN}🔍 Checking LLM instance health...{Colors.NC}\n")
    
    instances_to_check = [instance_name] if instance_name else INSTANCES.keys()
    
    for name in instances_to_check:
        if name not in INSTANCES:
            print(f"{Colors.RED}Error: Unknown instance '{name}'{Colors.NC}")
            continue
            
        config = INSTANCES[name]
        port = config['port']
        model = config['model']
        
        try:
            response = requests.get(f'http://localhost:{port}/health', timeout=5)
            if response.status_code == 200:
                data = response.json()
                status = data.get('status', 'unknown')
                model_type = data.get('environment', {}).get('model_type', 'unknown')
                print(f"{Colors.BLUE}{name.title()} ({model}) - Port {port}:{Colors.NC}")
                print(f"  Status: {status}, Model: {model_type}")
            else:
                print(f"{Colors.BLUE}{name.title()} ({model}) - Port {port}:{Colors.NC}")
                print(f"  Status: HTTP {response.status_code}")
        except requests.exceptions.RequestException:
            print(f"{Colors.BLUE}{name.title()} ({model}) - Port {port}:{Colors.NC}")
            print(f"  Status: offline or error")
        print()

def ask_llm(instance_name, question):
    """Send question to specific LLM instance"""
    if instance_name not in INSTANCES:
        print(f"{Colors.RED}Error: Invalid instance '{instance_name}'{Colors.NC}")
        print(f"Available instances: {', '.join(INSTANCES.keys())}")
        sys.exit(1)
    
    config = INSTANCES[instance_name]
    port = config['port']
    model = config['model']
    
    print(f"{Colors.CYAN}🤖 Asking {model} ({instance_name}):{Colors.NC} {question}")
    print(f"{Colors.BLUE}📡 Connecting to port {port}...{Colors.NC}\n")
    
    try:
        response = requests.post(
            f'http://localhost:{port}/api/agent',
            headers={'Content-Type': 'application/json'},
            json={'prompt': question},
            timeout=60  # Longer timeout for model processing
        )
        
        if response.status_code == 200:
            data = response.json()
            llm_response = data.get('llm_response', 'No response received')
            
            print(f"{Colors.GREEN}🤖 Response:{Colors.NC}")
            print(llm_response)
            
            # Show command execution if any
            executed_command = data.get('executed_command')
            command_result = data.get('command_result', '')
            
            if executed_command and executed_command != 'None':
                print(f"\n{Colors.YELLOW}🔧 Command executed:{Colors.NC} {executed_command}")
                if command_result:
                    print(f"{Colors.BLUE}📋 Result:{Colors.NC}")
                    print(command_result)
        else:
            print(f"{Colors.RED}Error: HTTP {response.status_code}{Colors.NC}")
            print(response.text)
            
    except requests.exceptions.Timeout:
        print(f"{Colors.RED}Error: Request timed out{Colors.NC}")
        print(f"{Colors.YELLOW}The model may be loading or processing. Try again in a moment.{Colors.NC}")
    except requests.exceptions.RequestException as e:
        print(f"{Colors.RED}Connection error: {e}{Colors.NC}")
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}JSON error: {e}{Colors.NC}")

def interactive_mode():
    """Start interactive chat with LLM selection"""
    print(f"{Colors.CYAN}🤖 SimpleBrain Multi-LLM Interactive Chat{Colors.NC}")
    print("Available instances: " + ", ".join(INSTANCES.keys()))
    print("Type 'switch <instance>' to change LLM, 'health' to check status, or 'quit' to exit")
    print("=" * 60)
    
    current_instance = 'general'  # Default instance
    
    try:
        while True:
            try:
                user_input = input(f"\n💬 You ({current_instance}): ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    print("👋 Goodbye!")
                    break
                
                if user_input.lower() == 'health':
                    check_health()
                    continue
                
                if user_input.lower().startswith('switch '):
                    new_instance = user_input[7:].strip()
                    if new_instance in INSTANCES:
                        current_instance = new_instance
                        model = INSTANCES[current_instance]['model']
                        print(f"{Colors.GREEN}Switched to {current_instance} ({model}){Colors.NC}")
                    else:
                        print(f"{Colors.RED}Invalid instance. Available: {', '.join(INSTANCES.keys())}{Colors.NC}")
                    continue
                
                if not user_input:
                    continue
                
                ask_llm(current_instance, user_input)
                
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                break
                
    except Exception as e:
        print(f"Error: {e}")

def show_help():
    """Show usage information"""
    print(f"{Colors.CYAN}SimpleBrain Multi-LLM Client{Colors.NC}\n")
    
    print(f"{Colors.BLUE}Available LLM instances:{Colors.NC}")
    for name, config in INSTANCES.items():
        print(f"{Colors.CYAN}  {name:<8}{Colors.NC} (Port: {Colors.YELLOW}{config['port']}{Colors.NC}) - {config['model']} - {config['description']}")
    
    print(f"\n{Colors.BLUE}Usage:{Colors.NC}")
    print(f"  python3 ask_llm.py <instance> \"question\"")
    print(f"  python3 ask_llm.py --health [instance]")
    print(f"  python3 ask_llm.py --interactive")
    
    print(f"\n{Colors.BLUE}Examples:{Colors.NC}")
    print(f"  python3 ask_llm.py general \"What is machine learning?\"")
    print(f"  python3 ask_llm.py coding \"Write a Python sorting function\"")
    print(f"  python3 ask_llm.py chat \"Tell me a story about robots\"")

def main():
    parser = argparse.ArgumentParser(description='SimpleBrain Multi-LLM Client', add_help=False)
    parser.add_argument('instance', nargs='?', help='LLM instance name')
    parser.add_argument('question', nargs='?', help='Question to ask')
    parser.add_argument('--health', nargs='?', const='all', help='Check health of instances')
    parser.add_argument('--interactive', '-i', action='store_true', help='Start interactive mode')
    parser.add_argument('--help', '-h', action='store_true', help='Show help')
    
    args = parser.parse_args()
    
    if args.help or (not args.instance and not args.health and not args.interactive):
        show_help()
        return
    
    if args.health:
        if args.health == 'all':
            check_health()
        else:
            check_health(args.health)
        return
    
    if args.interactive:
        interactive_mode()
        return
    
    if args.instance and args.question:
        ask_llm(args.instance, args.question)
    else:
        print(f"{Colors.RED}Error: Both instance and question are required{Colors.NC}")
        show_help()

if __name__ == "__main__":
    main()