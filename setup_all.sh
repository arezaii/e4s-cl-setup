#!/bin/bash
# setup_all.sh - Run complete E4S-CL setup process
# This script runs all setup steps in order for initial installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="${SCRIPT_DIR}/setup"

echo "E4S-CL Setup: venv → install → profile → libraries"
echo "After setup, update container image path manually."

read -p "Continue with setup? (y/N): " -r reply
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo "Starting setup..."

# Step 1: Create virtual environment
echo "[1/4] Creating Python venv..."
if ! "$SETUP_DIR/01_create_venv.sh"; then
    echo "Error: Virtual environment creation failed"
    exit 1
fi
echo "[OK] venv created"

# Step 2: Install E4S-CL
echo "[2/4] Installing E4S-CL..."
if ! "$SETUP_DIR/02_install_e4s.sh"; then
    echo "Error: E4S-CL installation failed"
    exit 1
fi
echo "[OK] E4S-CL installed"

# Step 3: Create profile
echo "[3/4] Creating E4S-CL profile..."
if ! "$SETUP_DIR/03_create_profile.sh"; then
    echo "Error: Profile creation failed"
    exit 1
fi
echo "[OK] profile created"

# Step 4: Setup libraries
echo "[4/4] Setting up libraries..."
if ! "$SETUP_DIR/04_setup_libraries.sh"; then
    echo "Error: Library setup failed"
    exit 1
fi
echo "[OK] libraries configured"

echo ""
echo "[OK] Setup complete! Next steps:"
echo "1. Set container: source .venv/bin/activate && e4s-cl profile edit --image /path/to/chapel-arkouda.sif"
echo "2. Test: source bin/setup_env.sh && e4s-cl profile show"
echo "3. Launch: ./bin/launch_arkouda.sh --nodes 1 --interactive"