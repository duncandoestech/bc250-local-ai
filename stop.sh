#!/usr/bin/env bash
# Stop the AI container and give the GPU and memory back to your games.
#   bash stop.sh                   stop the container
#   bash stop.sh --delete-models   stop it and also delete the downloaded models

cd "$(dirname "$0")"

if podman stop llama >/dev/null 2>&1; then
  echo "Stopped. The GPU and memory are free again."
else
  echo "The container was not running."
fi

if [ "$1" = "--delete-models" ]; then
  rm -rf models
  echo "Deleted the downloaded models."
fi
