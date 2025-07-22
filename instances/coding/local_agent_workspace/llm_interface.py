import os
import subprocess
import sys

# Configuration paths - made more flexible
LLAMA_PATHS = [
    "/app/workspace/projects/llama.cpp/main",
    "/app/workspace/llama.cpp/main", 
    "/app/workspace/llama.cpp/build/bin/main",
    "/usr/local/bin/llama-main",
    "llama-main"
]

MODEL_PATH = os.environ.get("MODEL_PATH")

def find_llama_executable():
    """Find the llama.cpp executable in common locations"""
    for path in LLAMA_PATHS:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    
    # Try to find in PATH
    try:
        result = subprocess.run(["which", "llama-main"], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
        
    return None

def get_llm_response(prompt):
    """
    Gets a response from the local LLM using llama.cpp.
    """
    # Validate environment
    if not MODEL_PATH:
        return "Error: MODEL_PATH environment variable not set. Please configure the model path."

    if not os.path.exists(MODEL_PATH):
        return f"Error: Model file not found at {MODEL_PATH}. Please check the model path and ensure the model file exists."

    # Find the llama.cpp executable
    llama_path = find_llama_executable()
    if not llama_path:
        return f"Error: llama.cpp executable not found. Searched paths: {', '.join(LLAMA_PATHS)}"

    # Build command with safer parameters
    command = [
        llama_path,
        "-m", MODEL_PATH,
        "-p", prompt,
        "-n", "512",  # Increased token limit for better responses
        "--temp", "0.7",
        "-c", "2048",  # Context size
        "--no-display-prompt",  # Don't echo the prompt back
        "-b", "1",  # Batch size
        "-t", "4",  # Number of threads
        "--silent-prompt"  # Reduce output noise
    ]

    try:
        print(f"Running llama.cpp: {llama_path} with model {MODEL_PATH}", file=sys.stderr)
        
        # Run with timeout to prevent hanging
        result = subprocess.run(
            command, 
            capture_output=True, 
            text=True, 
            check=False,  # Don't raise exception on non-zero exit
            timeout=60  # 60 second timeout
        )
        
        # Check for successful execution
        if result.returncode == 0:
            response = result.stdout.strip()
            if response:
                return response
            else:
                return "Error: LLM produced no output. This might indicate a model loading issue."
        else:
            error_msg = result.stderr.strip() if result.stderr else "Unknown error"
            return f"Error running llama.cpp (exit code {result.returncode}): {error_msg}"
            
    except subprocess.TimeoutExpired:
        return "Error: LLM request timed out. The model might be too large or the request too complex."
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr.strip() if e.stderr else str(e)
        return f"Error running llama.cpp: {error_msg}"
    except FileNotFoundError:
        return f"Error: llama.cpp executable not found at {llama_path}"
    except Exception as e:
        return f"Unexpected error in LLM interface: {str(e)}"

def test_llm_setup():
    """Test function to validate LLM setup"""
    issues = []
    
    # Check MODEL_PATH
    if not MODEL_PATH:
        issues.append("MODEL_PATH environment variable not set")
    elif not os.path.exists(MODEL_PATH):
        issues.append(f"Model file not found: {MODEL_PATH}")
    else:
        # Check file size (models should be at least 100MB)
        try:
            size = os.path.getsize(MODEL_PATH)
            if size < 100 * 1024 * 1024:  # 100MB
                issues.append(f"Model file seems too small: {size} bytes")
        except OSError as e:
            issues.append(f"Cannot access model file: {e}")
    
    # Check llama.cpp executable
    llama_path = find_llama_executable()
    if not llama_path:
        issues.append("llama.cpp executable not found")
    else:
        # Test if executable runs
        try:
            result = subprocess.run([llama_path, "--help"], 
                                  capture_output=True, timeout=5)
            if result.returncode != 0:
                issues.append("llama.cpp executable doesn't run properly")
        except Exception as e:
            issues.append(f"Cannot execute llama.cpp: {e}")
    
    return issues

if __name__ == "__main__":
    # Test setup when run directly
    print("Testing LLM setup...")
    issues = test_llm_setup()
    
    if issues:
        print("Issues found:")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("LLM setup looks good!")
        
        # Test a simple prompt
        print("\nTesting simple prompt...")
        response = get_llm_response("Hello, please say hi back.")
        print(f"Response: {response}")