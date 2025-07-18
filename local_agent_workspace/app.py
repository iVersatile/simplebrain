from flask import Flask, request, jsonify
import llm_interface
import agent_actions

app = Flask(__name__)

@app.route('/api/agent', methods=['POST'])
def handle_agent_prompt():
    data = request.get_json()
    if not data or 'prompt' not in data:
        return jsonify({"error": "Prompt not provided"}), 400

    prompt = data['prompt']

    # Add a simple instruction wrapper for the LLM
    full_prompt = (
        "You are a helpful AI assistant. Your goal is to answer the user's question or "
        "execute a command to satisfy their request. If a shell command is needed, "
        "provide it inside [CMD]...[/CMD] tags.\n\n"
        f"User request: {prompt}\n\nAssistant:"
    )

    # Get the raw response from the LLM
    llm_response = llm_interface.get_llm_response(full_prompt)

    # Try to execute a command from the response
    executed_command, command_result = agent_actions.execute_command(llm_response)

    return jsonify({
        "llm_response": llm_response,
        "executed_command": executed_command,
        "command_result": command_result
    })

if __name__ == '__main__':
    # Running with host=0.0.0.0 makes it accessible outside the container
    app.run(host='0.0.0.0', port=5000, debug=True)

