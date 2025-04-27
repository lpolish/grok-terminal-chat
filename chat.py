import os
import sys
import json
import subprocess
import re
from openai import OpenAI

def load_context(context_file):
    try:
        with open(context_file, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []

def execute_command(command):
    print(f"\nWould you like to execute this command: {command}")
    confirmation = input("Enter 'yes' to proceed or anything else to cancel: ")
    if confirmation.lower() == 'yes':
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            return result.stdout if result.stdout else result.stderr
        except Exception as e:
            return f"Error executing command: {str(e)}"
    return "Command execution cancelled."

def chat(api_key, message, context_file):
    try:
        client = OpenAI(
            api_key=api_key,
            base_url="https://api.x.ai/v1"
        )

        messages = load_context(context_file)

        system_message = {
            "role": "system",
            "content": """You can help users interact with their system through commands.
            To execute a command, prefix it with 'EXECUTE: ' followed by the command.
            Example: 'EXECUTE: ls -l'
            Be cautious with system-modifying commands and always explain what a command will do before suggesting it."""
        }
        messages.insert(0, system_message)
        messages.append({"role": "user", "content": message})

        try:
            response = client.chat.completions.create(
                model="grok-2-1212",
                messages=messages,
                temperature=0.7
            )
            content = response.choices[0].message.content

            # First show the AI's response before executing any commands
            print(content)

            if "EXECUTE:" in content:
                command_match = re.search(r'EXECUTE:\s*(.+?)(?:\n|$)', content)
                if command_match:
                    command = command_match.group(1).strip()
                    output = execute_command(command)
                    content += f"\n\nCommand output:\n{output}"

            # Save updated context
            messages.append({"role": "assistant", "content": content})
            with open(context_file, 'w') as f:
                json.dump(messages[1:], f)

            # Only return the command output if there was one
            if "EXECUTE:" in content:
                return "\nCommand output:\n" + output
            return ""

        except Exception as e:
            return f"Error: {str(e)}"
    except KeyboardInterrupt:
        return "\nConversation interrupted. Goodbye!"

if __name__ == "__main__":
    try:
        if len(sys.argv) != 4:
            print("Usage: chat.py <api_key> <message> <context_file>")
            sys.exit(1)

        api_key = sys.argv[1]
        message = sys.argv[2]
        context_file = sys.argv[3]

        result = chat(api_key, message, context_file)
        if result:  # Only print if there's something to print
            print(result)
    except KeyboardInterrupt:
        print("\nGoodbye!")
        sys.exit(0)
