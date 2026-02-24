#!/bin/bash
# Simple Arkouda server launcher using e4s-cl

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E4S_SETUP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${E4S_SETUP_DIR}/.venv"

# Default values
NODES="${NODES:-1}"
CPUS_PER_TASK="${CPUS_PER_TASK:-256}"
PARTITION="${PARTITION:-}"
ACCOUNT="${ACCOUNT:-}"
TIME_LIMIT="${TIME_LIMIT:-2:00:00}"
CHPL_RT_MAX_HEAP_SIZE="${CHPL_RT_MAX_HEAP_SIZE:-64g}"
LOG_LEVEL="${LOG_LEVEL:-LogLevel.ERROR}"
TRACE="${TRACE:-false}"
JOB_NAME="${JOB_NAME:-arkouda-server}"
OUTPUT_FILE="${OUTPUT_FILE:-}"
INTERACTIVE=false

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [options]

Simple Arkouda server launcher using e4s-cl.

Options:
    -N, --nodes COUNT          Number of nodes (default: 1)
    -c, --cpus-per-task COUNT  CPUs per task (default: 256)
    -p, --partition NAME       SLURM partition (optional)
    -A, --account NAME         SLURM account/project (optional)
    -t, --time TIME           Time limit (default: 2:00:00)
    --heap-size SIZE          Chapel heap size (default: 64g)
    --log-level LEVEL         Arkouda log level (default: LogLevel.ERROR)
    --trace BOOL              Enable tracing (default: false)
    -J, --job-name NAME       SLURM job name (default: arkouda-server)
    -o, --output FILE         Output file for logs (optional)
    --interactive             Run interactively (no sbatch)
    --help                    Show this help message

Examples:
    $0 -N 2 --heap-size 128g
    $0 --interactive -N 1
    $0 -N 4 -c 128 -p compute
    $0 -N 2 -A myproject -p gpu
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -N|--nodes)
            NODES="$2"
            shift 2
            ;;
        -c|--cpus-per-task)
            CPUS_PER_TASK="$2"
            shift 2
            ;;
        -p|--partition)
            PARTITION="$2"
            shift 2
            ;;
        -A|--account)
            ACCOUNT="$2"
            shift 2
            ;;
        -t|--time)
            TIME_LIMIT="$2"
            shift 2
            ;;
        --heap-size)
            CHPL_RT_MAX_HEAP_SIZE="$2"
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --trace)
            TRACE="$2"
            shift 2
            ;;
        -J|--job-name)
            JOB_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "Launching Arkouda server..."

# Setup environment
APPTAINER_SETUP="/lus/bnchlu1/rezaii/apptainer.sh"
if [[ -f "$APPTAINER_SETUP" ]]; then
    source "$APPTAINER_SETUP"
fi

if [[ ! -d "$VENV_DIR" ]]; then
    echo "Error: Virtual environment not found at $VENV_DIR"
    echo "Run setup scripts first"
    exit 1
fi

source "$VENV_DIR/bin/activate"

if ! command -v e4s-cl &>/dev/null; then
    echo "Error: e4s-cl not found. Run setup scripts first"
    exit 1
fi

CURRENT_PROFILE=$(e4s-cl profile show 2>/dev/null | awk -F': ' '/^Profile name/ {print $2; exit}' || echo "")
if [[ -z "$CURRENT_PROFILE" ]]; then
    echo "Error: No e4s-cl profile selected"
    echo "Run: e4s-cl profile select <name>"
    exit 1
fi

echo "Profile: $CURRENT_PROFILE"
echo "Config: nodes=$NODES, cpus=$CPUS_PER_TASK, heap=$CHPL_RT_MAX_HEAP_SIZE"

# Build srun arguments
SRUN_ARGS=(
    "--job-name=${JOB_NAME}"
    "--nodes=${NODES}"
    "--ntasks=${NODES}"
    "--cpus-per-task=${CPUS_PER_TASK}"
    "--exclusive"
    "--time=${TIME_LIMIT}"
    "--kill-on-bad-exit"
)

if [[ -n "$PARTITION" ]]; then
    SRUN_ARGS+=("--partition=${PARTITION}")
fi

if [[ -n "$ACCOUNT" ]]; then
    SRUN_ARGS+=("--account=${ACCOUNT}")
fi

if [[ -n "$OUTPUT_FILE" ]]; then
    SRUN_ARGS+=("--output=${OUTPUT_FILE}")
fi

# Build environment export string
ENV_VARS="ALL,CHPL_LAUNCHER_MEM=unset,CHPL_RT_MAX_HEAP_SIZE=${CHPL_RT_MAX_HEAP_SIZE}"
ENV_VARS="${ENV_VARS},FI_MR_KEY_SIZE=8,FI_CXI_MR_KEY_SIZE=8,FI_PROVIDER=cxi"

# Build Arkouda arguments
ARKOUDA_ARGS=(
    "-nl" "${NODES}"
    "--logLevel=${LOG_LEVEL}"
    "--trace=${TRACE}"
)

if [[ "$INTERACTIVE" == "true" ]]; then
    # Run interactively
    echo "Running interactively..."
    echo ""

    exec e4s-cl -q launch srun \
        "${SRUN_ARGS[@]}" \
        "--export=${ENV_VARS}" \
        -- arkouda_server_real \
        "${ARKOUDA_ARGS[@]}"
else
    # Submit batch job
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SBATCH_SCRIPT="/tmp/arkouda_${JOB_NAME}_${TIMESTAMP}.sbatch"

    cat > "$SBATCH_SCRIPT" << EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --nodes=${NODES}
#SBATCH --ntasks=${NODES}
#SBATCH --cpus-per-task=${CPUS_PER_TASK}
#SBATCH --exclusive
#SBATCH --time=${TIME_LIMIT}
$(if [[ -n "$PARTITION" ]]; then echo "#SBATCH --partition=${PARTITION}"; fi)
$(if [[ -n "$ACCOUNT" ]]; then echo "#SBATCH --account=${ACCOUNT}"; fi)
$(if [[ -n "$OUTPUT_FILE" ]]; then echo "#SBATCH --output=${OUTPUT_FILE}"; else echo "#SBATCH --output=arkouda_${JOB_NAME}_%j.out"; fi)

# Setup environment
source ${APPTAINER_SETUP}
source ${VENV_DIR}/bin/activate

# Launch Arkouda server
e4s-cl -q launch srun \\
    --job-name=${JOB_NAME} \\
    --nodes=${NODES} \\
    --ntasks=${NODES} \\
    --cpus-per-task=${CPUS_PER_TASK} \\
    --exclusive \\
    --time=${TIME_LIMIT} \\
$(if [[ -n "$PARTITION" ]]; then echo "    --partition=${PARTITION} \\"; fi)
$(if [[ -n "$ACCOUNT" ]]; then echo "    --account=${ACCOUNT} \\"; fi)
$(if [[ -n "$OUTPUT_FILE" ]]; then echo "    --output=${OUTPUT_FILE} \\"; else echo "    --output=arkouda_${JOB_NAME}_%j.out \\"; fi)
    --export=${ENV_VARS} \\
    -- arkouda_server_real \\
    -nl ${NODES} \\
    --logLevel=${LOG_LEVEL} \\
    --trace=${TRACE}
EOF

    echo "Submitting batch job..."
    JOB_ID=$(sbatch --parsable "$SBATCH_SCRIPT")
    echo "Job ID: $JOB_ID"
    echo "Monitor: squeue -j $JOB_ID"

    # Clean up sbatch script
    (sleep 60 && rm -f "$SBATCH_SCRIPT") &
fi