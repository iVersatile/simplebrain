from flask import Flask, request, jsonify
import os
import sys
import llm_interface
import agent_actions

app = Flask(__name__)

# Add health check endpoint
@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint to verify the API is running"""
    return jsonify({
        "status": "healthy",
        "service": "SimpleBrain LLM API",
        "version": "1.0"
    })

@app.route('/health', methods=['GET'])
def detailed_health():
    """Detailed health check including model availability"""
    model_path = os.environ.get("MODEL_PATH")
    llama_path = "/app/workspace/projects/llama.cpp/main"
    
    health_status = {
        "status": "healthy",
        "service": "SimpleBrain LLM API",
        "model_path": model_path,
        "model_exists": os.path.exists(model_path) if model_path else False,
        "llama_executable": llama_path,
        "llama_exists": os.path.exists(llama_path),
        "environment": {
            "instance_name": os.environ.get("INSTANCE_NAME", "unknown"),
            "model_type": os.environ.get("MODEL_TYPE", "unknown"),
            "api_port": os.environ.get("API_PORT", "5000")
        }
    }
    
    # Set overall status based on critical components
    if not health_status["model_exists"] or not health_status["llama_exists"]:
        health_status["status"] = "unhealthy"
        return jsonify(health_status), 503
    
    return jsonify(health_status)

@app.route('/api/agent', methods=['POST'])
def handle_agent_prompt():
    try:
        data = request.get_json()
        if not data or 'prompt' not in data:
            return jsonify({"error": "Prompt not provided"}), 400

        prompt = data['prompt']
        
        # Input validation
        if not prompt.strip():
            return jsonify({"error": "Empty prompt provided"}), 400
        
        if len(prompt) > 10000:  # Reasonable limit
            return jsonify({"error": "Prompt too long (max 10000 characters)"}), 400

        # Add a simple instruction wrapper for the LLM
        full_prompt = (
            "You are a helpful AI assistant. Your goal is to answer the user's question clearly and concisely. "
            f"User request: {prompt}\n\nAssistant:"
        )

        # Get the raw response from the LLM
        try:
            llm_response = llm_interface.get_llm_response(full_prompt)
        except Exception as e:
            app.logger.error(f"LLM interface error: {e}")
            return jsonify({"error": f"LLM processing failed: {str(e)}"}), 500

        # For security, disable command execution by returning None
        executed_command = None
        command_result = "Command execution disabled for security"

        return jsonify({
            "llm_response": llm_response,
            "executed_command": executed_command,
            "command_result": command_result
        })
    
    except Exception as e:
        app.logger.error(f"Unexpected error in handle_agent_prompt: {e}")
        return jsonify({"error": "Internal server error"}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    # Check critical environment variables
    model_path = os.environ.get("MODEL_PATH")
    if not model_path:
        print("ERROR: MODEL_PATH environment variable not set", file=sys.stderr)
        sys.exit(1)
    
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found at {model_path}", file=sys.stderr)
        sys.exit(1)
    
    # Start Flask app with production settings
    app.run(
        host='0.0.0.0', 
        port=int(os.environ.get('API_PORT', 5000)), 
        debug=False,  # Security fix: disabled debug mode
        threaded=True  # Enable threading for better performance
    )