# E4S-CL Setup for Chapel-Arkouda

## Quick Setup

Run this command once:

```bash
cd e4s-cl-setup
./setup_all.sh
```

Update container image path:
```bash
source .venv/bin/activate
e4s-cl profile edit --container-image /path/to/your/chapel-arkouda.sif
```

## Launch Arkouda

```bash
# Setup environment
source bin/setup_env.sh

# Launch server (using short forms)
./bin/launch_arkouda.sh -N 2 -A myproject

# With partition and QOS
./bin/launch_arkouda.sh -N 4 -A myproject -p compute -q high-priority

# Interactive mode
./bin/launch_arkouda.sh --interactive -N 1 -A myproject

# Using long forms (also supported)
./bin/launch_arkouda.sh --nodes 2 --account myproject
```

## Options for server startup

| Option | Short | Description |
|--------|-------|-------------|
| `--nodes N` | `-N` | Number of nodes (default: 1) |
| `--cpus-per-task N` | `-c` | CPUs per task (default: 256) |
| `--account NAME` | `-A` | SLURM account |
| `--partition NAME` | `-p` | SLURM partition |
| `--qos NAME` | `-q` | SLURM quality of service |
| `--time TIME` | `-t` | Job time limit (default: 2:00:00) |
| `--job-name NAME` | `-J` | SLURM job name (default: arkouda-server) |
| `--output FILE` | `-o` | Output file for logs |
| `--heap-size SIZE` | | Chapel heap size (default: 64g) |
| `--log-level LEVEL` | | Arkouda log level (default: LogLevel.ERROR) |
| `--trace BOOL` | | Enable tracing (default: false) |
| `--interactive` | | Run in foreground |