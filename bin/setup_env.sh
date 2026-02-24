#!/bin/bash
# setup_env.sh - Set up environment for e4s-cl usage
# Source this script to activate the e4s-cl environment

# Determine the script directory
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Script is being executed
    echo "This script should be sourced, not executed directly."
    echo "Usage: source $0"
    exit 1
fi

E4S_SETUP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${E4S_SETUP_DIR}/.venv"

echo "=== Setting up E4S-CL Environment ==="

# Check if virtual environment exists
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Error: Virtual environment not found at $VENV_DIR"
    echo "Please run the setup scripts first:"
    echo "  cd $E4S_SETUP_DIR"
    echo "  ./setup/01_create_venv.sh"
    echo "  ./setup/02_install_e4s.sh"
    echo "  ./setup/03_create_profile.sh"
    echo "  ./setup/04_setup_libraries.sh"
    return 1
fi

# Activate virtual environment
echo "Activating virtual environment: $VENV_DIR"
source "$VENV_DIR/bin/activate"

# Verify e4s-cl is available
if ! command -v e4s-cl &>/dev/null; then
    echo "Error: e4s-cl not found in virtual environment"
    echo "Please run ./setup/02_install_e4s.sh"
    return 1
fi

# Check if a profile is selected
CURRENT_PROFILE=$(e4s-cl profile show 2>/dev/null | awk -F': ' '/^Profile name/ {print $2; exit}' || echo "")
if [[ -z "$CURRENT_PROFILE" ]]; then
    echo ""
    echo "Warning: No e4s-cl profile is currently selected"
    echo "Available profiles:"
    e4s-cl profile list
    echo ""
    echo "To select a profile, run:"
    echo "  e4s-cl profile select <profile-name>"
    echo ""
else
    echo "Current e4s-cl profile: $CURRENT_PROFILE"
    
    # Show container image status
    CONTAINER_IMAGE=$(e4s-cl profile show 2>/dev/null | grep "Container image:" | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' || echo "")
    if [[ -n "$CONTAINER_IMAGE" ]]; then
        if [[ "$CONTAINER_IMAGE" == "/path/to/your/"* ]]; then
            echo ""
            echo "[WARNING] Container image path appears to be a placeholder"
            echo "   Current: $CONTAINER_IMAGE"
            echo "   Please update with: e4s-cl profile edit --container-image /actual/path/to/chapel-arkouda.sif"
        else
            echo "Container image: $CONTAINER_IMAGE"
            if [[ -f "$CONTAINER_IMAGE" ]]; then
                echo "[OK] Container image file exists"
            else
                echo "[WARNING] Container image file not found: $CONTAINER_IMAGE"
            fi
        fi
    fi
fi

echo ""
echo "[SUCCESS] E4S-CL environment ready!"
echo ""
echo "Available commands:"
echo "  e4s-cl profile show    - Show current profile"
echo "  e4s-cl profile list    - List all profiles"  
echo "  e4s-cl launch          - Launch commands in container"
echo ""
echo "To launch Arkouda server, use: ./launch_arkouda.sh [options]"

# Set up some helpful aliases
alias e4s-status='e4s-cl profile show'
alias e4s-list='e4s-cl profile list'

# Export useful environment variables
export E4S_SETUP_DIR
export E4S_VENV_DIR="$VENV_DIR"
export E4S_PROFILE="$CURRENT_PROFILE"