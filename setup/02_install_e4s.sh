#!/bin/bash
# 02_install_e4s.sh - Install e4s-cl into the Python virtual environment
# This script downloads and installs e4s-cl from the official repository

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

# Check if e4s-cl is already installed
if command -v e4s-cl &>/dev/null; then
    EXISTING_VERSION=$(e4s-cl --version 2>/dev/null || echo "unknown")
    echo "e4s-cl already installed ($EXISTING_VERSION)"
    read -p "Reinstall/update? (y/N): " -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "Keeping existing e4s-cl installation."
        exit 0
    fi
fi

# Install e4s-cl from GitHub repository
echo "Installing e4s-cl..."

# Install dependencies first
pip install --quiet requests packaging

# Create temporary directory and clone repository
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Cloning e4s-cl repository..."
if command -v git &>/dev/null; then
    git clone https://github.com/E4S-Project/e4s-cl.git
    cd e4s-cl
    pip install .
else
    echo "Error: Git not available. Please install git first."
    exit 1
fi

# Clean up
cd "$E4S_SETUP_DIR"
rm -rf "$TEMP_DIR"

# Verify installation
if command -v e4s-cl &>/dev/null; then
    E4S_VERSION=$(e4s-cl --version 2>/dev/null || echo "installed")
    echo "[OK] e4s-cl installed ($E4S_VERSION)"
else
    echo "Error: e4s-cl installation failed"
    exit 1
fi

echo "Next: ./setup/03_create_profile.sh"