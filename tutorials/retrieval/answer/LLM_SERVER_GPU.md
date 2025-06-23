# Set up an LLM server with GPU acceleration

Reconfigure the [LLaMA.cpp](https://github.com/ggml-org/llama.cpp) server for GPU acceleration.

---

- [Can I benefit from GPU acceleration?](#can-i-benefit-from-gpu-acceleration)
- [Nvidia Container Toolkit](#nvidia-container-toolkit)
- [Configure Docker for GPU](#configure-docker-for-gpu)
- [Modify container settings](#modify-container-settings)
- [Optimization](#optimization)
  - [Measurements](#measurements)
  - [Discussion](#discussion)
- [Next step](#next-step)

---

## Can I benefit from GPU acceleration?

It depends on how much memory your GPU card has and which LLM you want to use.

For the author, using a laptop with a built-in Nvidia T600 card (4 GB memory) and running our chosen quantized LLMs, no significant speed improvement is observed. See detailed notes on speed [below](#optimization).

However, if you have access to a larger GPU card and want to run LLMs with a larger footprint, the following steps may be of use.

## Nvidia Container Toolkit

If you choose to explore GPU acceleration, first upgrade CUDA for Windows, from <https://developer.nvidia.com/cuda-downloads>.

> NOTE: CUDA (Compute Unified Device Architecture) from Nvidia enables general purpose computing on GPUs, which can perform efficient parallel processing to dramatically speed up machine learning algorithms.

Next, install the the container toolkit on Ubuntu under WSL, as instructed in the [official documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html):

1. Download the repository settings for Nvidia:

    ```sh
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    ```

1. Connect to the new repository:

    ```sh
    sudo apt-get update
    ```

1. Install the toolkit:

    ```sh
    sudo apt-get install -y nvidia-container-toolkit
    ```

## Configure Docker for GPU

Configure the Container Toolkit for Docker, then restart the Docker service:

```sh
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker.service
```

## Modify container settings

Update your `docker-compose.yml` file:

```diff
services:
  llamacpp-server:
+   deploy:
+     resources:
+       reservations:
+         devices:
+           - driver: nvidia
+             capabilities: [gpu]
-   image: ghcr.io/ggml-org/llama.cpp:server
+   image: ghcr.io/ggml-org/llama.cpp:server-cuda
    ports:
      - 8888:8080
    volumes:
      - ./models:/models
    environment:
      LLAMA_ARG_MODEL: /models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
      LLAMA_ARG_ENDPOINT_METRICS: 1  # to disable, either remove or set to 0
+     LLAMA_ARG_N_GPU_LAYERS: 6
```

> NOTE: See the [optimization](#optimization) discussion below for more information on the `LLAMA_ARG_N_GPU_LAYERS` parameter.

To apply a settings change in your `docker-compose.yml` file, you must redeploy the container:

```sh
docker compose down
docker compose up -d
```

Watch the logs to look for the following lines to tell you the GPU is in use:

```sh
$ docker compose logs
...
llamacpp-server-1  | ggml_cuda_init: found 1 CUDA devices:
llamacpp-server-1  |   Device 0: NVIDIA T600 Laptop GPU, compute capability 7.5, VMM: yes
llamacpp-server-1  | llm_load_tensors: ggml ctx size =    0.27 MiB
llamacpp-server-1  | llm_load_tensors: offloading 12 repeating layers to GPU
llamacpp-server-1  | llm_load_tensors: offloaded 12/33 layers to GPU
llamacpp-server-1  | llm_load_tensors:        CPU buffer size =  4169.52 MiB
llamacpp-server-1  | llm_load_tensors:      CUDA0 buffer size =  2362.81 MiB
```

## Optimization

These `.gguf`-format, quantized LLMs allow for partial "offloading" of processing from CPU to GPU. The more GPU memory you have available, the more processing "layers" you can offload to speed up the LLM response.

### Measurements

Best speed (prompt and predicted tokens per second) for each model with associated `LLAMA_ARG_N_GPU_LAYERS` setting.

Model | Layers offloaded to GPU | Prompt TPS | Predicted TPS
--- | --- | --- | ---
Llama 1B | 16 of 16 (100%) | 209.7 | 54.5
Llama 3B | 21 of 28 (75%) | 95.4 | 26.2
Mistral 7B | 19 of 32 (60%) | 40.2 | 14.4

> TABLE: Processing speed (prompt and predicted tokens per second) observed for three LLMs with GPU enabled.

For comparison, the same speeds running with CPU only:

Model | Prompt TPS | Predicted TPS
--- | --- | ---
Llama 1B | 157.1 | 55.3
Llama 3B | 50.9 | 21.9
Mistral 7B | 20.6 | 11.6

> TABLE: Processing speed (prompt and predicted tokens per second) observed for three LLMs without GPU enabled.

### Discussion

For comparison, we can look at the relative speed increase from enabling GPU by comparing the above two tables:

GPU (best) / CPU only | Prompt TPS | Predicted TPS
--- | --- | ---
Llama 1B | 133% | 99%
Llama 3B | 187% | 120%
Mistral 7B | 195% | 124%

> TABLE: Relative change observed in processing speed (prompt and predicted tokens per second) observed for three LLMs with GPU enabled.

So, on this laptop, the best speed is for Llama 1B, where there is limited speed-up thanks to enabling GPU. If you prefer to use a larger model, GPU can give a more significant increase in speed.

## Next step

You may (or may not) now have a more responsive local LLM server. Return to the [tutorial](./PART_II.md#get-an-answer-from-a-sample-document) to continue.
