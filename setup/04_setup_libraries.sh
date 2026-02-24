#!/bin/bash
# 04_setup_libraries.sh - Add necessary host libraries to e4s-cl profile
# This script detects and adds system libraries needed for Chapel/Arkouda networking

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

if ! command -v e4s-cl &>/dev/null; then
    echo "Error: Run ./setup/02_install_e4s.sh first"
    exit 1
fi

CURRENT_PROFILE=$(e4s-cl profile show 2>/dev/null | awk -F': ' '/^Profile name/ {print $2; exit}' || echo "")
if [[ -z "$CURRENT_PROFILE" ]]; then
    echo "Error: Run ./setup/03_create_profile.sh first"
    exit 1
fi

echo "Setting up libraries for profile: $CURRENT_PROFILE"

# Function to add library if it exists
add_library() {
    local lib_path="$1"
    local description="$2"

    if [[ -e "$lib_path" ]]; then
        if e4s-cl profile edit --add-libraries "$lib_path" &>/dev/null; then
            echo "  + $description"
        else
            echo "  ! Failed: $description"
        fi
        return 0
    fi
    return 1
}

# Function to add directory if it exists
add_directory() {
    local dir_path="$1"
    local description="$2"
    
    if [[ -e "$dir_path" ]]; then
        if e4s-cl profile edit --add-files "$dir_path" &>/dev/null; then
            echo "  + $description"
        else
            echo "  ! Failed: $description"
        fi
        return 0
    fi
    return 1
}

echo "Detecting and adding system libraries..."

# Cray libfabric (critical for OFI)
LIBFABRIC_PATH=""
if ls /opt/cray/libfabric/*/lib*/libfabric.so.1 2>/dev/null 1>&2; then
    LIBFABRIC_PATH=$(ls /opt/cray/libfabric/*/lib*/libfabric.so.1 2>/dev/null | sort -V | tail -1)
fi
if [[ -n "$LIBFABRIC_PATH" ]]; then
    add_library "$LIBFABRIC_PATH" "Cray libfabric for OFI networking"
    # Also add the lib directory
    LIBFABRIC_DIR=$(dirname "$LIBFABRIC_PATH")
    add_directory "$LIBFABRIC_DIR" "Cray libfabric library directory"
fi

# CXI library for Slingshot network
CXI_PATH=""
if ls /usr/lib*/libcxi.so.1 2>/dev/null 1>&2; then
    CXI_PATH=$(ls /usr/lib*/libcxi.so.1 2>/dev/null | sort -V | tail -1)
elif ls /usr/lib*/libcxi.so 2>/dev/null 1>&2; then
    CXI_PATH=$(ls /usr/lib*/libcxi.so 2>/dev/null | sort -V | tail -1)
fi
if [[ -n "$CXI_PATH" ]]; then
    add_library "$CXI_PATH" "CXI library for Slingshot networking"
fi

# Netlink library
NETLINK_PATH=""
if ls /usr/lib*/libnl-3.so.200 2>/dev/null 1>&2; then
    NETLINK_PATH=$(ls /usr/lib*/libnl-3.so.200 2>/dev/null | sort -V | tail -1)
elif ls /usr/lib*/libnl-3.so 2>/dev/null 1>&2; then
    NETLINK_PATH=$(ls /usr/lib*/libnl-3.so 2>/dev/null | sort -V | tail -1)
fi
if [[ -n "$NETLINK_PATH" ]]; then
    add_library "$NETLINK_PATH" "Netlink library for network configuration"
fi

# Process Management Interface (PMI) Libraries

# PMI2 libraries - find the newest version available
PMI_DIR=""
if ls -d /opt/cray/pe/pmi/*/lib 2>/dev/null 1>&2; then
    PMI_DIR=$(ls -d /opt/cray/pe/pmi/*/lib 2>/dev/null | sort -V | tail -1)
fi
if [[ -n "$PMI_DIR" ]] && [[ -f "$PMI_DIR/libpmi2.so.0.6.0" ]]; then
    add_directory "$PMI_DIR" "PMI library directory (newest version)"
    add_library "$PMI_DIR/libpmi2.so.0.6.0" "PMI2 library"
    add_library "$PMI_DIR/libpmi2.so.0" "PMI2 library (symlink)"
fi

# SLURM System Integration

add_directory "/etc/slurm" "SLURM configuration directory"
add_directory "/run/munge" "Munge authentication socket directory"
add_directory "/usr/lib64/slurm" "SLURM library directory"
add_directory "/var/spool/slurm" "SLURM spool directory"

# Additional system libraries

# System-specific paths that might be needed
ADDITIONAL_PATHS=(
    "/usr/lib64/libpthread.so.0"
    "/usr/lib64/librt.so.1"
    "/usr/lib64/libdl.so.2"
)

for path in "${ADDITIONAL_PATHS[@]}"; do
    if [[ -e "$path" ]]; then
        add_library "$path" "System library: $(basename "$path")"
    fi
done

echo "[OK] Library setup complete for: $CURRENT_PROFILE"
echo "Update container: e4s-cl profile edit --container-image /path/to/chapel-arkouda.sif"