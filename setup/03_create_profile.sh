#!/bin/bash
# 03_create_profile.sh - Create e4s-cl profile for chapel-arkouda
# This script creates a new e4s-cl profile with apptainer backend

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E4S_SETUP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${E4S_SETUP_DIR}/.venv"

# Check dependencies
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Error: Run ./setup/01_create_venv.sh first"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Verify e4s-cl is available
if ! command -v e4s-cl &>/dev/null; then
    echo "Error: Run ./setup/02_install_e4s.sh first"
    exit 1
fi

# Get profile name from user
DEFAULT_PROFILE="chapel-arkouda"
read -p "Enter profile name (default: $DEFAULT_PROFILE): " PROFILE_NAME
PROFILE_NAME="${PROFILE_NAME:-$DEFAULT_PROFILE}"

# Check if profile already exists
if e4s-cl profile show "$PROFILE_NAME" &>/dev/null; then
    echo "Profile '$PROFILE_NAME' exists"
    read -p "Recreate it? (y/N): " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        e4s-cl profile delete "$PROFILE_NAME" || true
    else
        e4s-cl profile select "$PROFILE_NAME"
        echo "[OK] Profile '$PROFILE_NAME' selected"
        echo "Next: ./setup/04_setup_libraries.sh"
        exit 0
    fi
fi

# Create and configure profile
echo "Creating profile '$PROFILE_NAME'..."
e4s-cl profile create "$PROFILE_NAME"
e4s-cl profile select "$PROFILE_NAME"
e4s-cl profile edit --backend apptainer

echo "[OK] Profile '$PROFILE_NAME' created with placeholder container path"
echo "Update container: e4s-cl profile edit --image /path/to/actual/chapel-arkouda.sif"
echo "Next: ./setup/04_setup_libraries.sh"