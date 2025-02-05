# Set up an LLM server with GPU acceleration

Reconfigure the [LLaMA.cpp](https://github.com/ggerganov/llama.cpp) server for GPU acceleration.

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
+   image: ghcr.io/ggerganov/llama.cpp:server-cuda
-   image: ghcr.io/ggerganov/llama.cpp:server
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
$ docker logs llama-llamacpp-server-1 -f
...
ggml_cuda_init: found 1 CUDA devices:
  Device 0: NVIDIA T600 Laptop GPU, compute capability 7.5, VMM: yes
llm_load_tensors: ggml ctx size =    0.27 MiB
llm_load_tensors: offloading 12 repeating layers to GPU
llm_load_tensors: offloaded 12/33 layers to GPU
llm_load_tensors:        CPU buffer size =  4169.52 MiB
llm_load_tensors:      CUDA0 buffer size =  2362.81 MiB
```

## Optimization

These `.gguf`-format, quantized LLMs allow for partial "offloading" of processing from CPU to GPU. The more GPU memory you have available, the more processing "layers" you can offload to speed up the LLM response.

### Measurements

Running a series of test prompts with **Mistral 7B**, I see the following speeds (predicted tokens per second), when changing the number of GPU layers configured:

`LLAMA_ARG_N_GPU_LAYERS` | Mistral 7B | Llama 3B | Llama 1B
--- | --- | --- | ---
3 | 6.8 | 18.0 | 30.9
6 | 10.3 | 20.3 | 35.0
12 | 12.8 | 22.4 | 41.9
24 | 12.8 | 22.1 | 50.6
48 | 11.3 | 24.0 | 50.2

> TABLE: Predicted tokens per second observed for three LLMs with different GPU settings.

### Discussion

For comparison, we can compare the best speed with GPU from the above table against the observed predicted token rates for these same models running with CPU only:

Mode | Mistral 7B | Llama 3B | Llama 1B
--- | --- | --- | ---
GPU (best) | 12.8 | 24.0 | 50.6
CPU only | 11.6 | 24.2 | 58.9
Change | +10% | -1% | -14%

> TABLE: Predicted tokens per second observed for three LLMs with GPU enabled and CPU only, with percentage change in speed from enabling GPU.

So, there is no evidence that enabling GPU speeds up these models on the author's system.

## Next step

You may (or may not) now have a more responsive local LLM server. Return to the [tutorial](./PART_II.md#get-an-answer-from-a-sample-document) to continue.
