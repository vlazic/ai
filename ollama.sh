#!/usr/bin/env bash

# install ollama
curl https://ollama.ai/install.sh | sh

# Create override directory and file
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment=OLLAMA_HOST=0.0.0.0
EOF

# Reload systemd and restart ollama
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Verify the override
echo "Verifying environment variables:"
systemctl show ollama | grep Environment
