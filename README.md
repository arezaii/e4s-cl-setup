# E4S-CL Setup for Chapel-Arkouda

## Quick Setup

Run these commands once:

```bash
cd e4s-setup
./setup/01_create_venv.sh
./setup/02_install_e4s.sh
./setup/03_create_profile.sh
./setup/04_setup_libraries.sh
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

# Launch server
./bin/launch_arkouda.sh --nodes 2 --account myproject

# Interactive mode
./bin/launch_arkouda.sh --interactive --nodes 1 --account myproject
```

## Options

| Option | Description |
|--------|-------------|
| `--nodes N` | Number of nodes |
| `--account NAME` | SLURM account |
| `--partition NAME` | SLURM partition |
| `--time TIME` | Job time limit |
| `--heap-size SIZE` | Chapel heap size |
| `--interactive` | Run in foreground |