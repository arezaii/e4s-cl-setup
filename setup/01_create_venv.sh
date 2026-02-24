#!/bin/bash
# 01_create_venv.sh - Create Python virtual environment for e4s-cl
# This script detects the system Python version and creates a virtual environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E4S_SETUP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${E4S_SETUP_DIR}/.venv"

# Check if virtual environment already exists
if [[ -d "$VENV_DIR" ]]; then
    echo "Virtual environment exists at: $VENV_DIR"
    read -p "Recreate it? (y/N): " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_DIR"
    else
        echo "Using existing venv. To activate: source $VENV_DIR/bin/activate"
        exit 0
    fi
fi

# Detect Python version
PYTHON_CMD=""

# Try different Python commands in order of preference
for py_cmd in python3.14 python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3 python; do
    if command -v "$py_cmd" &>/dev/null; then
        PYTHON_VERSION=$("$py_cmd" --version 2>&1 | awk '{print $2}')
        PYTHON_CMD="$py_cmd"
        break
    fi
done

if [[ -z "$PYTHON_CMD" ]]; then
    echo "Error: No suitable Python installation found"
    echo "Please ensure Python 3.8 or newer is installed"
    exit 1
fi

# Check Python version is suitable (3.8+)
PYTHON_MAJOR=$("$PYTHON_CMD" -c "import sys; print(sys.version_info.major)")
PYTHON_MINOR=$("$PYTHON_CMD" -c "import sys; print(sys.version_info.minor)")

if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 8 ]]; then
    echo "Error: Python 3.8+ required. Found Python $PYTHON_MAJOR.$PYTHON_MINOR"
    exit 1
fi

# Create virtual environment
echo "Creating venv with Python $PYTHON_MAJOR.$PYTHON_MINOR..."
"$PYTHON_CMD" -m venv "$VENV_DIR"

# Activate and upgrade pip
source "$VENV_DIR/bin/activate"
pip install --upgrade pip wheel setuptools >/dev/null

echo "[OK] Virtual environment ready at: $VENV_DIR"
echo "Next: ./setup/02_install_e4s.sh"