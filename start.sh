#!/usr/bin/env bash
# Start llama.cpp (Vulkan) in a Podman container on a BC-250.
# Run from anywhere:  bash start.sh
#
# Optional settings (put them in front of the command):
#   MODEL=unsloth/Qwen3-VL-8B-Instruct-GGUF:Q6_K       which model to download and run
#   CTX=8192                                           context size (bigger = more memory)
#   BIND=127.0.0.1                                     use 0.0.0.0 to reach it from other devices
#   PORT=8080                                          port for the web page
# Example:  BIND=0.0.0.0 bash start.sh

set -e
cd "$(dirname "$0")"

MODEL="${MODEL:-unsloth/Qwen3-VL-8B-Instruct-GGUF:Q6_K}"
CTX="${CTX:-8192}"
BIND="${BIND:-127.0.0.1}"
PORT="${PORT:-8080}"

# Models are saved in ./models (ignored by git), so they survive container restarts.
mkdir -p models

# If an old copy is still running, replace it.
podman rm -f llama >/dev/null 2>&1 || true

podman run -d --rm --name llama \
  --device /dev/dri \
  --group-add keep-groups \
  -e LLAMA_CACHE=/models \
  -v "$PWD/models:/models" \
  -p "$BIND:$PORT:8080" \
  ghcr.io/ggml-org/llama.cpp:server-vulkan \
  -hf "$MODEL" \
  -ngl 99 -c "$CTX" -fa on \
  --cache-type-k q8_0 --cache-type-v q8_0

echo
echo "Container started. The first run downloads the model, so give it a few minutes."
echo "  Watch progress:  podman logs -f llama   (Ctrl+C to leave the log view)"
if [ "$BIND" = "127.0.0.1" ]; then
  echo "  Open:            http://localhost:$PORT"
else
  echo "  Open:            http://$(hostname -I | awk '{print $1}'):$PORT"
fi
echo "  Stop:            bash stop.sh"
