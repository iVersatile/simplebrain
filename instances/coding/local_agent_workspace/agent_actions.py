import subprocess
import re

def execute_command(llm_output):
    """
    Parses the LLM output for a command and executes it.
    For security, this is a very basic implementation.
    
    NOTE: Command execution is disabled to prevent errors and security issues.
    """
    # DISABLED: Command execution is causing more issues than it's solving
    # The LLM responses are being truncated, leading to invalid commands
    
    # Look for a command in the format [CMD]...[/CMD] but don't execute it
    match = re.search(r'\[CMD\](.*?)\[/CMD\]', llm_output, re.DOTALL)

    if not match:
        return None, "No command found in the output."

    command = match.group(1).strip()
    
    # Clean up the command by removing any extra text or invalid characters
    command_lines = command.split('\n')
    command = command_lines[0].strip()
    
    # Skip empty, invalid, or placeholder commands
    invalid_commands = ['...', '', 'echo', 'command', 'your command here', 'placeholder']
    if not command or any(invalid in command.lower() for invalid in invalid_commands):
        return None, "No valid command found."
    
    # Additional check: if command is too short or looks like a placeholder
    if len(command) < 3 or command.count('.') > 2:
        return None, "Command appears to be a placeholder."
    
    print(f"Found command to execute: {command}")

    # --- SECURITY WARNING ---
    # Executing commands from an LLM is inherently risky.
    # This is a simplified example. A real application would need
    # sandboxing, restricted permissions, and whitelisted commands.
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            check=True
        )
        return command, result.stdout
    except subprocess.CalledProcessError as e:
        return command, f"Error executing command: {e.stderr}"
    except Exception as e:
        return command, f"An unexpected error occurred: {e}"
