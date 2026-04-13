#!/bin/bash

image_name="open-webui-dev"
container_name="open-webui-dev"
host_port=3000
container_port=8080

docker stop "$container_name" &>/dev/null || true
docker rm "$container_name" &>/dev/null || true
docker image rm "$image_name" &>/dev/null || true

docker build -t "$image_name" .

# docker run -p "$host_port":"$container_port" \
#     --add-host=host.docker.internal:host-gateway \
#     -v "${image_name}:/app/backend/data" \
#     --name "$container_name" \
#     "$image_name"

docker run --network=host \
    -v "${image_name}:/app/backend/data" \
    -v /home/edison/Documents:/home/edison/Documents:ro \
    -e OLLAMA_BASE_URL=http://127.0.0.1:9000/v1 \
    -e DEFAULT_MODELS=Qwen/Qwen3.5-27B \
    -e VIDEO_POINTER_ALLOWED_PATHS=/ \
    --name "$container_name" \
    "$image_name"

docker image prune -f