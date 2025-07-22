import requests
import json

API_URL = "http://127.0.0.1:5000/api/agent"

def main():
    """
    Main loop to send prompts to the agentic backend.
    """
    print("Local Agentic AI Assistant CLI")
    print("Enter 'exit' to quit.")
    print("-" * 30)

    while True:
        try:
            prompt = input("You: ")
            if prompt.lower() == 'exit':
                break

            response = requests.post(API_URL, json={"prompt": prompt})
            response.raise_for_status() # Raise an exception for bad status codes

            data = response.json()

            print("\n" + "="*20 + " Agent Response " + "="*20)
            print(f"LLM says: {data.get('llm_response')}")
            if data.get('executed_command'):
                print("-" * 20)
                print(f"Executed Command: {data['executed_command']}")
                print(f"Command Result:\n{data['command_result']}")
            print("="*58 + "\n")

        except requests.exceptions.RequestException as e:
            print(f"\nError connecting to the agent backend: {e}")
            print("Is the Flask server running?")
        except Exception as e:
            print(f"\nAn unexpected error occurred: {e}")

if __name__ == '__main__':
    main()

