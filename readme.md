# Add AI to your BC-250 (without losing gaming)

A quick start guide to running an LLM on your BC-250 **without** losing the ability to play games like you did before.

We'll use SSH to remote into your BC-250, build a container that runs the AI, and open a local web page to chat with it. When you're done, you stop the container and everything goes back to normal.

> This guide has 3 parts. A lot of us keep our BC-250s tucked away in hard-to-reach places, so you only need to do a few steps at the BC-250 itself. Everything else happens remotely over SSH.

> **Heads up:** this setup is meant for your home network. It has no password on the web page, so don't forward port 8080 to the internet.

## Part A - Done on your BC-250
*(This is a lot easier with a keyboard and mouse.)*

1. Switch to Desktop Mode (this takes you to the Linux desktop).
   - Click the Steam menu at the bottom right > Power > Switch to Desktop Mode.
2. Open **Konsole** (the terminal app) from the application menu.
3. Create a password for the `deck` user (the SteamOS default user). You'll use it to SSH in.
   ```bash
   passwd
   ```
   > Nothing shows on screen while you type a password. That's normal, it is still typing.
4. Make sure SSH is enabled.
   ```bash
   sudo systemctl enable --now sshd
   ```
5. Get your IP address. Write it down, you'll need it on your computer.
   ```bash
   ip -br a
   ```
   > This prints a few lines. Ignore the `lo` line. Look for the one that says `UP` with an address like `192.168.1.50/24`. The part before the `/` is your IP.

## Part B - Move to your computer and play with some AI

1. Open PowerShell (Windows) or Terminal (Mac) and SSH into your BC-250.
   - **Windows:** press the Windows key, type `powershell`, and open it.
   - **Mac:** press Cmd+Space, type `terminal`, and open it.
   - Then run the command below, changing the IP to yours.
   ```bash
   ssh deck@YOUR_IP_ADDRESS
   ```
   > The first time, it asks if you trust the connection. Type `yes` and press enter. Then enter the password you made in Part A (remember, nothing shows as you type).

   Your terminal should now say something like `(deck@steamdeck ~)$`. That means you're remotely controlling your BC-250.

2. Create a Vulkan container with Podman and download your first model (`Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M`, about 5 GB). Copy the code below, paste it into your BC-250 terminal, and press enter.
   ```bash
   cd ~
   mkdir -p models
   podman run -d --rm --name llama \
     --device /dev/dri \
     --group-add keep-groups \
     -e LLAMA_CACHE=/models \
     -v "$PWD/models:/models" \
     -p 8080:8080 \
     ghcr.io/ggml-org/llama.cpp:server-vulkan \
     -hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M \
     -ngl 99 -c 8192 -fa on \
     --cache-type-k q8_0 --cache-type-v q8_0
   ```
   This builds your container and downloads the model. The first run takes a while.

3. Watch the logs.
   ```bash
   podman logs -f llama
   ```
   Wait until the log says the server is listening on port 8080. Then press `Ctrl+C` to leave the log view (the container keeps running).

4. Open your web browser and go to your model!
   ```
   http://YOUR_IP_ADDRESS:8080
   ```

### What did that command just do?

- *cd ~:* moves to your home folder so the `models` folder lands somewhere predictable.
- *mkdir -p models:* creates the folder where the model file will be saved. `-p` means no error if it already exists.
- *-d:* runs it in the background so you get your terminal back.
- *--rm:* deletes the container when it stops. That's the cleanup, and the model files stay in your folder.
- *--name llama:* gives the container a name, so you can run `podman stop llama` or `podman logs llama`.
- *--device /dev/dri:* passes the GPU into the container. Without it, the container can't see the BC-250.
- *--group-add keep-groups:* keeps your user's group memberships inside the container, which is what gives it permission to use the GPU device.
- *-e LLAMA_CACHE=/models:* tells llama.cpp to store downloaded models in `/models` inside the container.
- *-v "$PWD/models:/models":* links that `/models` to the `models` folder on your machine, so downloads persist after the container is gone.
- *-p 8080:8080:* makes the server's web page reachable on port 8080 from other devices.
- *ghcr.io/ggml-org/llama.cpp:server-vulkan:* the official llama.cpp server build with Vulkan support. It's the same Vulkan stack you already use on the host.
- *-hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M:* downloads the model from Hugging Face on first run. `Q4_K_M` picks the quantization (a 4-bit compression).
- *-ngl 99:* puts all model layers on the GPU. Any number at or above the layer count means "all of them".
- *-c 8192:* the context window, meaning how much text the model can hold in mind at once. Larger values use more memory.
- *-fa on:* turns on flash attention, which uses less memory and runs faster.
- *--cache-type-k q8_0 --cache-type-v q8_0:* compresses the model's working memory (the KV cache) to 8-bit, roughly halving what it takes versus the default.

> **Stability warning:** the BC-250 has 16 GB of memory shared between the CPU and GPU. A bigger model or a larger `-c` value can use it all and freeze the desktop. If that happens, SSH in and run `podman stop llama`.

## Part C - Stop the AI and go back to gaming

1. Stop the container. This frees the GPU and memory.
   ```bash
   podman stop llama
   ```
2. (Optional) Free the disk space by deleting the downloaded models.
   ```bash
   rm -rf ~/models
   ```
3. Switch back to Gaming Mode: Steam menu > Power > Switch to Gaming Mode. Play something!