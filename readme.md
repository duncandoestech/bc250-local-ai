# Add AI to your BC-250 (without losing gaming)

A quick start guide to running an LLM on your BC-250 **without** losing the ability to play games like you did before.

Everything happens right on the BC-250's desktop. No SSH, no second computer. You'll download this repo, run one script that starts an AI in a container, and chat with it in a web browser. When you're done, you stop the container and everything goes back to normal.

## Before you start

You need a BC-250 running SteamOS with Podman and Git installed, and about 6 GB of free disk space. Check from Konsole (steps below):

```bash
podman --version
git --version
df -h ~
```

## Part A - Start the AI

1. Switch to Desktop Mode (this takes you to the Linux desktop).
   - Click the Steam menu at the bottom right > Power > Switch to Desktop Mode.
2. Open **Konsole** (the terminal app) from the application menu.
3. Download this repo into your home folder.
   ```bash
   cd ~
   git clone https://github.com/duncandoestech/bc250-local-ai.git
   cd bc250-local-ai
   ```
4. Run the start script. It builds the container and downloads your first model (`Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M`, about 5 GB). The first run takes a while.
   ```bash
   bash start.sh
   ```
5. Watch the logs until the server is ready.
   ```bash
   podman logs -f llama
   ```
   Wait until the log says the server is listening on port 8080, then press `Ctrl+C` to leave the log view (the container keeps running).
6. Open a web browser on the BC-250 and go to your model!
   ```
   http://localhost:8080
   ```

## Part B - Stop the AI and go back to gaming

1. Stop the container. This frees the GPU and memory.
   ```bash
   bash stop.sh
   ```
2. (Optional) Free the disk space by deleting the downloaded models too.
   ```bash
   bash stop.sh --delete-models
   ```
3. Switch back to Gaming Mode: Steam menu > Power > Switch to Gaming Mode. Play something!

> **Stability warning:** the BC-250 has 16 GB of memory shared between the CPU and GPU, and the desktop uses some of it too. A bigger model or a larger context (`CTX`) can use it all and freeze the desktop. If that happens, wait a bit, or switch to a text console and run `bash stop.sh`.

## What does start.sh actually do?

The heart of the script is this command:

```bash
podman run -d --rm --name llama \
  --device /dev/dri \
  --group-add keep-groups \
  -e LLAMA_CACHE=/models \
  -v "$PWD/models:/models" \
  -p 127.0.0.1:8080:8080 \
  ghcr.io/ggml-org/llama.cpp:server-vulkan \
  -hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M \
  -ngl 99 -c 8192 -fa on \
  --cache-type-k q8_0 --cache-type-v q8_0
```

- *-d:* runs it in the background so you get your terminal back.
- *--rm:* deletes the container when it stops. That's the cleanup, and the model files stay in your folder.
- *--name llama:* gives the container a name, so you can run `podman stop llama` or `podman logs llama`.
- *--device /dev/dri:* passes the GPU into the container. Without it, the container can't see the BC-250.
- *--group-add keep-groups:* keeps your user's group memberships inside the container, which is what gives it permission to use the GPU device.
- *-e LLAMA_CACHE=/models:* tells llama.cpp to store downloaded models in `/models` inside the container.
- *-v "$PWD/models:/models":* links that `/models` to the `models` folder in this repo, so downloads persist after the container is gone.
- *-p 127.0.0.1:8080:8080:* makes the server's web page reachable on port 8080, from this computer only.
- *ghcr.io/ggml-org/llama.cpp:server-vulkan:* the official llama.cpp server build with Vulkan support. It's the same Vulkan stack you already use on the host.
- *-hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M:* downloads the model from Hugging Face on first run. `Q4_K_M` picks the quantization (a 4-bit compression).
- *-ngl 99:* puts all model layers on the GPU. Any number at or above the layer count means "all of them".
- *-c 8192:* the context window, meaning how much text the model can hold in mind at once. Larger values use more memory.
- *-fa on:* turns on flash attention, which uses less memory and runs faster.
- *--cache-type-k q8_0 --cache-type-v q8_0:* compresses the model's working memory (the KV cache) to 8-bit, roughly halving what it takes versus the default.

The script wraps that command with a few extras: it moves into the repo folder, creates the `models` folder, replaces any older copy of the container, and prints the address to open.

## Settings you can change

Put these in front of the command. They're all optional.

| Setting | Default | What it does |
|---|---|---|
| `MODEL` | `Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M` | Which model to download and run |
| `CTX` | `8192` | Context size. Bigger uses more memory |
| `PORT` | `8080` | Port for the web page |
| `BIND` | `127.0.0.1` | Who can reach it. `0.0.0.0` means other devices on your network |

Example:

```bash
CTX=4096 bash start.sh
```

## Want to use it from another computer?

By default only the BC-250 itself can reach the web page. To open it from your laptop or phone on the same network:

1. Start it with `BIND=0.0.0.0 bash start.sh`. The script prints the address to open.
2. Or find the IP yourself with `ip -br a` (look for the line with `UP` and an address like `192.168.1.50/24`) and browse to `http://YOUR_IP_ADDRESS:8080`.

> **Heads up:** the web page has no password. Only do this on your home network, and never forward port 8080 to the internet.
