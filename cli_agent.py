#!/usr/bin/env python3

import requests
import json
import sys
import readline  # For better input handling

def ask_agent(prompt):
    """Send prompt to local LLM agent and return response"""
    try:
        response = requests.post(
            'http://localhost:5001/api/agent',
            headers={'Content-Type': 'application/json'},
            json={'prompt': prompt},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            return data['llm_response'], data.get('executed_command'), data.get('command_result')
        else:
            return f"Error: HTTP {response.status_code}", None, None
            
    except requests.exceptions.RequestException as e:
        return f"Connection error: {e}", None, None
    except json.JSONDecodeError as e:
        return f"JSON error: {e}", None, None

def main():
    print("🤖 Local LLM Agent CLI")
    print("Type 'quit', 'exit', or press Ctrl+C to exit")
    print("=" * 50)
    
    if len(sys.argv) > 1:
        # Single question mode
        prompt = ' '.join(sys.argv[1:])
        response, cmd, result = ask_agent(prompt)
        print(f"\n💬 You: {prompt}")
        print(f"🤖 Agent: {response}")
        if cmd and cmd != "None":
            print(f"🔧 Command: {cmd}")
            print(f"📋 Result: {result}")
        return
    
    # Interactive mode
    try:
        while True:
            try:
                prompt = input("\n💬 You: ").strip()
                
                if prompt.lower() in ['quit', 'exit', 'q']:
                    print("👋 Goodbye!")
                    break
                    
                if not prompt:
                    continue
                
                print("🤖 Agent: ", end="", flush=True)
                response, cmd, result = ask_agent(prompt)
                print(response)
                
                if cmd and cmd != "None":
                    print(f"🔧 Command executed: {cmd}")
                    if result:
                        print(f"📋 Result: {result}")
                        
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                break
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()