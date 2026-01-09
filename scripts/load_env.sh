#!/bin/bash
# Helper script to load environment variables from .env file

# Function to load .env file
load_env_file() {
    local env_file="${1:-.env}"
    
    if [ ! -f "$env_file" ]; then
        echo "⚠️  Warning: $env_file not found. Using default values (if any)." >&2
        return 1
    fi
    
    # Read .env file and export variables
    # This handles comments and empty lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Export the variable
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes if present
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # Export the variable
            export "$key=$value"
        fi
    done < "$env_file"
    
    return 0
}

# Load .env file if it exists
if [ -f ".env" ]; then
    load_env_file ".env"
    echo "✅ Loaded secrets from .env file"
else
    echo "⚠️  .env file not found. Some secrets may use default values."
fi

