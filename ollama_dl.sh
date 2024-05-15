#!/usr/bin/env bash

set -euo pipefail

model_name="$1"

if [[ -z "$model_name" ]]; then
    echo "Usage: $0 <model_name>"
    exit 1
fi

mkdir -p models

echo "Getting manifest for $model_name"
digest=$(curl -fsSL \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    "https://registry.ollama.ai/v2/library/$model_name/manifests/latest" \
    | jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest')

dl_url="https://registry.ollama.ai/v2/library/$model_name/blobs/$digest" 
out_fname="models/$model_name.gguf"

if [[ -f "$out_fname" ]]; then
    echo "Verifying checksum"
    hash=$(echo "$digest" | cut -d: -f2)
    echo "$hash  models/$model_name.gguf" | sha256sum -c > /dev/null && {
        echo "$model_name is already downloaded"
        exit 0
    } || echo "Checksum verification failed, redownloading"
fi

echo "Downloading $model_name from $dl_url"
curl -L -H 'Accept: application/vnd.ollama.image.model' "$dl_url" -o "$out_fname"

echo "Verifying checksum"
hash=$(echo "$digest" | cut -d: -f2)
echo "$hash  models/$model_name.gguf" | sha256sum -c

echo "Downloaded $model_name to $out_fname"