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
    -e "OPENAI_API_BASE_URLS=http://df-model-deepframe-dev:8000;http://brev-up8gmd44c:5566/v1;" \
    -e "OPENAI_API_KEYS=potato;potato" \
    -e "VIDEO_POINTER_ALLOWED_PATHS=/" \
    --name "$container_name" \
    "$image_name"

docker image prune -f


http://df-model-deepframe-dev:8000

df-model-gemma4-31b-it-nvfp4-dev

df-model-deepframe-dev
df-model-gemma4-31b-it-nvfp4-dev                              
df-model-gemma4-e2b-it-dev                              
df-model-gemma4-e4b-it-dev  