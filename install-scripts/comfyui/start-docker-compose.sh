#!/usr/bin/env bash

# if htpasswd file is not present, create it
if [ ! -f ./htpasswd ]; then
    echo "htpasswd file not found, creating one"
    echo "admin:$(openssl passwd -apr1)" > htpasswd
fi

docker compose -f docker-compose-comfyui.yaml up -d
