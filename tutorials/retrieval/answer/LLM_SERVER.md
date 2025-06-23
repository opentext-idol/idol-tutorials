# Set up an LLM server

Set up [LLaMA.cpp](https://github.com/ggml-org/llama.cpp) as an easy example of a local LLM Server, with optional GPU acceleration.

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

Move the downloaded LLM files:

```sh
mv /mnt/c/Users/$USER/Downloads/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf /opt/idol/llama/models/
mv /mnt/c/Users/$USER/Downloads/Llama-3.2-3B-Instruct-Q4_K_M.gguf /opt/idol/llama/models/
mv /mnt/c/Users/$USER/Downloads/Llama-3.2-1B-Instruct-Q4_K_M.gguf /opt/idol/llama/models/
```

Enter the following into your `docker-compose.yml` file:

```yml
services:
  llamacpp-server:
    image: ghcr.io/ggml-org/llama.cpp:server
    ports:
      - 8888:8080
    volumes:
      - ./models:/models
    environment:
      # LLAMA_ARG_MODEL: /models/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
      # LLAMA_ARG_MODEL: /models/Llama-3.2-3B-Instruct-Q4_K_M.gguf
      LLAMA_ARG_MODEL: /models/Llama-3.2-1B-Instruct-Q4_K_M.gguf
      LLAMA_ARG_ENDPOINT_METRICS: 1 # to disable, either remove or set to 0
```

> NOTE: Uncomment your preferred model from the three above for your first tests.
>
> For full information about "LLaMA.cpp" server, see the [documentation on GitHub](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md).

## Start the LLM Server

Run the server with Docker compose:

```sh
docker compose up -d
```

![llama-up](./figs/llama-up.png)

Monitor the logs with:

```sh
docker compose logs -f llamacpp-server
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
        "id": "/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
        "object": "model",
        "created": 1738350532,
        "owned_by": "llamacpp",
        "meta": {
          "vocab_type": 2,
          "n_vocab": 128256,
          "n_ctx_train": 131072,
          "n_embd": 2048,
          "n_params": 1498483200,
          "size": 1015334912
        }
      }
    ]
  }
  ```

- Prompt a response, for example ask a question:
  
  `curl http://localhost:8888/v1/completions -d '{"prompt": "Provide a concise factual response. Please keep your answer under 10 words. Question: Who is the head of state of the United Kingdom?"}' | jq`

  ```json
  {
    "content": " The answer is: Queen Elizabeth II.",
    "id_slot": 0,
    "stop": true,
    "model": "/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    ...
  }
  ```

  LLMs do not always give the correct answer. This is one reason why we want to use RAG and provide relevant context with a question:
  
  `curl http://localhost:8888/v1/completions -d '{"prompt": "King Charles III succeeded his mother on her death in September 2022. Please keep your answer under 10 words. Question: Who is the head of state of the United Kingdom?"}' | jq`
  
  ```json
  {
    "content": " \n\nAnswer: King Charles III.",
    "id_slot": 0,
    "stop": true,
    "model": "/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
    ...
  }
  ```

- Get metrics (in Prometheus compatible format):
  
  `curl http://localhost:8888/metrics`
  
  ```ini
  # HELP llamacpp:prompt_tokens_total Number of prompt tokens processed.
  # TYPE llamacpp:prompt_tokens_total counter
  llamacpp:prompt_tokens_total 105
  # HELP llamacpp:prompt_seconds_total Prompt process time
  # TYPE llamacpp:prompt_seconds_total counter
  llamacpp:prompt_seconds_total 0.536
  # HELP llamacpp:tokens_predicted_total Number of generation tokens processed.
  # TYPE llamacpp:tokens_predicted_total counter
  llamacpp:tokens_predicted_total 52
  ...
  ```

> INFO: Try out the included UI on <http://localhost:8888/index-new.html>.

## Explore alternative LLMs

You should now have three models downloaded:

- Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
- Llama-3.2-3B-Instruct-Q4_K_M.gguf
- Llama-3.2-1B-Instruct-Q4_K_M.gguf

> REMINDER: The "7B", "3B" and "1B" in the model names stand for the seven, three or one billion parameters of these models. Bigger models, with more parameters, should have the capacity to generate more accurate responses but are more intensive to compute.

### Run with a different model

1. Uncomment your chosen model in the `docker-compose.yml` file:

    ```yml
    services:
      llamacpp-server:
        ...
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

Model | Prompt TPS | Predicted TPS
--- | --- | ---
Llama 1B | 157.1 | 55.3
Llama 3B | 50.9 | 21.9
Mistral 7B | 20.6 | 11.6

> TABLE: Processing speed (prompt and predicted tokens per second) observed for three LLMs.

Those tests were performed with a range of questions, including:

**Question**: "Who was the first man on the moon?"

- **Mistral 7B**: " The first man on the moon was Neil Armstrong, who landed on the lunar surface on July 20, 1969, as part of the Apollo 11 mission. Armstrong famously declared, \"That's one small step for man, one giant leap for mankind.\"" (`8.4s`)

- **Llama 3B**: "Neil Armstrong was the first man to set foot on the moon on July 20, 1969, during the Apollo 11 mission." (`2.7s`)

- **Llama 1B**: "Neil Armstrong was the first man to walk on the moon, on July 20, 1969, during the Apollo 11 mission." (`1.0s`)

> TIP: Try out your own questions to judge which model's answers you find most useful. Compare with other LLMs online, *e.g.* OpenAI's `gpt-4o-mini` model responds to the same question with, "The first man on the moon was Neil Armstrong, who set foot on the lunar surface on July 20, 1969, during NASA's Apollo 11 mission."

## Optionally enable GPU acceleration

If you have access to a GPU, optionally follow [these steps](./LLM_SERVER_GPU.md) to set up GPU acceleration for your server.

> NOTE: Unless you have access to a large GPU, this is unlikely to result in a significant speed up.

## Next step

You now have a responsive, local LLM server, with your choice of model. Return to the [tutorial](./PART_II.md#download-local-tokenizer-files) to continue.
