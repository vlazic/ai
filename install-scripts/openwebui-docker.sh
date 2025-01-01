#!/usr/bin/env bash

docker stop open-webui
docker rm open-webui

docker run -d \
  -p 47586:8080 \
  --gpus all \
  -v open-webui:/app/backend/data \
  -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api \
  --add-host=host.docker.internal:host-gateway \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:cuda
