import os
import subprocess

# IMPORTANT: The path to the llama.cpp executable and the model file.
# The user MUST set the MODEL_PATH environment variable inside the container.
LLAMA_PATH = "/app/workspace/projects/llama.cpp/main"
MODEL_PATH = os.environ.get("MODEL_PATH")

def get_llm_response(prompt):
    """
    Gets a response from the local LLM using llama.cpp.
    """
    if not MODEL_PATH:
        raise ValueError("MODEL_PATH environment variable not set. Please set it to the path of your .gguf model file.")

    if not os.path.exists(MODEL_PATH):
        return f"Error: Model file not found at {MODEL_PATH}"

    command = [
        LLAMA_PATH,
        "-m", MODEL_PATH,
        "-p", prompt,
        "-n", "256", # Increased token limit to allow complete responses
        "--temp", "0.7",
        "-c", "2048" # Context size
    ]

    try:
        print(f"Running command: {' '.join(command)}")
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"Error running llama.cpp: {e.stderr}"
    except FileNotFoundError:
        return f"Error: llama.cpp executable not found at {LLAMA_PATH}"
