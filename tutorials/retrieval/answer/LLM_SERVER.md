# Set up an LLM server

Set up [LLaMA.cpp](https://github.com/ggerganov/llama.cpp) as an easy example of a local LLM Server, with optional GPU acceleration.

---

- [LLaMA.cpp server with Docker](#llamacpp-server-with-docker)
- [Start the LLM Server](#start-the-llm-server)
- [Call the LLM Server](#call-the-llm-server)
- [Explore alternative LLMs](#explore-alternative-llms)
  - [Run with a different model](#run-with-a-different-model)
  - [Comparing models](#comparing-models)
- [Optionally enable GPU acceleration](#optionally-enable-gpu-acceleration)
- [Next step](#next-step)

---

## LLaMA.cpp server with Docker

From the Ubuntu command line on WSL, create a new project folder structure:

```sh
mkdir -p /opt/idol/llama/models
touch /opt/idol/llama/docker-compose.yml
```

Move the downloaded LLM file:

```sh
mv /mnt/c/Users/$USER/Downloads/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf /opt/idol/llama/models/
```

Enter the following into your `docker-compose.yml` file:

```yml
services:
  llamacpp-server:
    image: ghcr.io/ggerganov/llama.cpp:server
    ports:
      - 8888:8080
    volumes:
      - ./models:/models
    environment:
      LLAMA_ARG_MODEL: /models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
      LLAMA_ARG_ENDPOINT_METRICS: 1 # to disable, either remove or set to 0
```

> NOTE: For complete information about LLaMA.cpp server, see the [documentation on GitHub](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md).

## Start the LLM Server

Run the server with Docker compose:

```sh
docker compose up -d
```

![llama-up](./figs/llama-up.png)

Monitor the logs with:

```sh
docker logs llama-llamacpp-server-1 -f
```

Press `Ctrl+C` to stop following the logs.

## Call the LLM Server

From your Ubuntu command prompt on WSL, run the following requests:

- Health check:
  
  `curl http://localhost:8888/health`

  ```json
  {"status":"ok"}
  ```

  > TIP: Install a JSON formatter to better display the server responses. See this [tip](../../appendix/TIPS.md#json-formatting) for details.

- Check the model is loaded:
  
  `curl http://localhost:8888/v1/models | jq`

  ```json
  {
    "object": "list",
    "data": [
      {
        "id": "/models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf",
        "object": "model",
        "created": 1724969284,
        "owned_by": "llamacpp",
        "meta": {
          "vocab_type": 1,
          "n_vocab": 32768,
          "n_ctx_train": 32768,
          "n_embd": 4096,
          "n_params": 7248023552,
          "size": 4372054016
        }
      }
    ]
  }
  ```

- Prompt a response, for example ask a question:
  
  `curl http://localhost:8888/v1/completions -d '{"prompt": "Provide a concise factual response. Please keep your answer under 10 words. Question: Who is the head of state of the United Kingdom?"}' | jq`

  ```json
  {
    "content": "\n\nAnswer: Queen Elizabeth II.",
    "id_slot": 0,
    "stop": true,
    "model": "/models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf",
    ...
  }
  ```

  LLMs do not always give the correct answer. This is one reason why we want to use RAG and provide relevant context with a question:
  
  `curl http://localhost:8888/v1/completions -d '{"prompt": "Charles III succeeded his mother on her death in September 2022. Please keep your answer under 10 words. Question: Who is the head of state of the United Kingdom?"}' | jq`
  
  ```json
  {
    "content": "\n\nCharles III, King of the United Kingdom.",
    "id_slot": 0,
    "stop": true,
    "model": "/models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf",
    ...
  }
  ```

- Get metrics (in Prometheus compatible format):
  
  `curl http://localhost:8888/metrics`
  
  ```ini
  # HELP llamacpp:prompt_tokens_total Number of prompt tokens processed.
  # TYPE llamacpp:prompt_tokens_total counter
  llamacpp:prompt_tokens_total 73
  # HELP llamacpp:prompt_seconds_total Prompt process time
  # TYPE llamacpp:prompt_seconds_total counter
  llamacpp:prompt_seconds_total 3.623
  ...
  ```

- Try out the included UI on <http://localhost:8888/index-new.html>.

## Explore alternative LLMs

Other models to consider for your local demo environment include:

- [Llama-3.2-3B-Instruct-GGUF](https://huggingface.co/lmstudio-community/Llama-3.2-3B-Instruct-GGUF), *e.g.* download [Llama-3.2-3B-Instruct-Q4_K_M.gguf](https://huggingface.co/lmstudio-community/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf?download=true)
- [Llama-3.2-1B-Instruct-GGUF](https://huggingface.co/lmstudio-community/Llama-3.2-1B-Instruct-GGUF), *e.g.* download [Llama-3.2-1B-Instruct-Q4_K_M.gguf](https://huggingface.co/lmstudio-community/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf?download=true)

> NOTE: The "3B" and "1B" in the model names stand for three billion and one billion parameters.  Bigger models, with more parameters should have the capacity to generate more accurate responses. These are both small compared to seven billion for Mistral 7B.

### Run with a different model

1. Move the downloaded LLM files:

    ```sh
    mv /mnt/c/Users/$USER/Downloads/Llama-3.2-3B-Instruct-Q4_K_M.gguf /opt/idol/llama/models/
    mv /mnt/c/Users/$USER/Downloads/Llama-3.2-1B-Instruct-Q4_K_M.gguf /opt/idol/llama/models/
    ```

1. Update your `docker-compose.yml` file:

    ```yml
    services:
      llamacpp-server:
        image: ghcr.io/ggerganov/llama.cpp:server
        ports:
          - 8888:8080
        volumes:
          - ./models:/models
        environment:
          # LLAMA_ARG_MODEL: /models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
          LLAMA_ARG_MODEL: /models/Llama-3.2-3B-Instruct-Q4_K_M.gguf
          # LLAMA_ARG_MODEL: /models/Llama-3.2-1B-Instruct-Q4_K_M.gguf
          LLAMA_ARG_ENDPOINT_METRICS: 1  # to disable, either remove or set to 0
    ```

1. Restart the LLM server:

    ```sh
    docker compose down
    docker compose up -d
    ```

### Comparing models

Tests show the following speed comparison:

Model | Predicted tokens / second
--- | ---
Mistral 7B | 11.6
Llama 3B | 24.2
Llama 1B | 58.9

Being smaller, they may give less useful answers than Mistral 7B but for my test questions they all seem capable of providing good answers. For example:

**Question**: "Who was the first man on the moon?"

- **Mistral 7B**: " The first man on the moon was Neil Armstrong, who landed on the lunar surface on July 20, 1969, as part of the Apollo 11 mission. Armstrong famously declared, \"That's one small step for man, one giant leap for mankind.\"" (`8.4s`)

- **Llama 3B**: "Neil Armstrong was the first man to set foot on the moon on July 20, 1969, during the Apollo 11 mission." (`2.7s`)

- **Llama 1B**: "Neil Armstrong was the first man to walk on the moon, on July 20, 1969, during the Apollo 11 mission." (`1.0s`)

## Optionally enable GPU acceleration

If you have access to a GPU, optionally follow [these steps](./LLM_SERVER_GPU.md) to set up GPU acceleration for your server.

> IMPORTANT: Unless you have access to a large GPU, this is unlikely to result in a significant speed up.

## Next step

You now have a responsive, local LLM server. Return to the [tutorial](./PART_II.md#download-local-tokenizer-files) to continue.
