# AI Tools and Helper Scripts

Collection of installation scripts for running various AI tools locally, along with helper scripts for common AI-related tasks. Tested on Ubuntu.

## Installation Scripts

All installation scripts are located in the `install-scripts/` directory.

### ComfyUI (`install-scripts/comfyui-docker.sh`)
Stable Diffusion UI running on port 8188
```bash
./install-scripts/comfyui-docker.sh
```

### Ollama (`install-scripts/ollama.sh`)
Local LLMs installation with external access enabled
```bash
./install-scripts/ollama.sh
```

### Open WebUI (`install-scripts/openwebui-docker.sh`)
Web interface for Ollama on port 47586
```bash
./install-scripts/openwebui-docker.sh
```

## Helper Scripts

Helper scripts for common AI-related tasks are located in the `helper-scripts/` directory.

### Available Helper Scripts

- `file-to-transcript.sh` - Transcribe audio files using OpenAI or Groq
- `image-ocr.sh` - Extract text from images using OpenAI GPT-4 Vision
- `translate-audio.sh` - Record and translate audio using OpenAI/Groq

## Prerequisites

- Docker with NVIDIA Container Toolkit
- NVIDIA GPU
- Ubuntu (or similar Linux)

## Quick Start

```bash
git clone git@github.com:vlazic/ai.git
cd ai

# Run what you need
./install-scripts/ollama.sh            # Install Ollama
./install-scripts/openwebui-docker.sh  # Setup Ollama web UI
```

## Notes
- `./install-scripts/storage/` and `./install-scripts/safetensors-models/` are gitignored (except .gitkeep)
- All Docker containers use NVIDIA GPU
- Sample FRP client configuration is provided in `frpc.ini.sample` for remote access. Put it in `/etc/frp/frpc.ini` and run `sudo systemctl restart frpc` to apply changes.

## TODO

- [ ] Add Ollama proxy server for remote access [ParisNeo/ollama_proxy_server](https://github.com/ParisNeo/ollama_proxy_server)
