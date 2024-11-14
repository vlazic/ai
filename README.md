# Local AI Tools Setup

Collection of scripts for running various AI tools locally. Tested on Ubuntu.

## Scripts

### ComfyUI (`comfyui-docker.sh`)
Stable Diffusion UI running on port 8188
```bash
./comfyui-docker.sh
```

### Ollama (`ollama.sh`)
Local LLMs installation with external access enabled
```bash
./ollama.sh
```

### Open WebUI (`openwebui-docker.sh`)
Web interface for Ollama on port 47586
```bash
./openwebui-docker.sh
```

## Prerequisites

- Docker with NVIDIA Container Toolkit
- NVIDIA GPU
- Ubuntu (or similar Linux)

## Quick Start

```bash
git clone git@github.com:vlazic/ai.git
cd ai

# Run what you need
./ollama.sh          # Install Ollama
./openwebui-docker.sh  # Setup Ollama web UI
```

## Notes
- `storage/` and `safetensors-models/` are gitignored (except .gitkeep)
- All Docker containers use NVIDIA GPU

