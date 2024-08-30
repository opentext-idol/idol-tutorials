# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
#
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE
import os

from typing import Tuple

import requests

from transformers import AutoTokenizer

LLM_ENDPOINT = os.getenv('IDOL_LLM_ENDPOINT') or 'http://localhost:8888/v1/chat/completions'
LLM_MODEL_QUANTIZED = os.getenv('IDOL_LLM_MODEL_QUANTIZED') or '/models/model-name.gguf'
LLM_MODEL = os.getenv('IDOL_LLM_MODEL') or 'model-provider/model-name'
LLM_MODEL_REVISION = os.getenv('IDOL_LLM_MODEL_REVISION') or 'main'

# Set this environment variable if you don't want to use a cached tokenizer.
# The cache location can be configured via the HF_HOME environment variable.
HUGGINGFACE_API_TOKEN = os.getenv('IDOL_HUGGINGFACE_API_TOKEN')
if HUGGINGFACE_API_TOKEN is not None:
    from huggingface_hub import login
    # Authenticate with Hugging Face
    login(HUGGINGFACE_API_TOKEN)

def generate(prompt: str) -> str:
    '''
    Calls out to a server endpoint to obtain a generated response from
    the provided prompt
    - https://platform.openai.com/docs/api-reference/chat/create
    '''
    context, question = prompt.split('Question:')

    url = LLM_ENDPOINT
    headers = {'Content-Type': 'application/json'}
    data = {
        "max_tokens": 256,
        "messages": [
            { "role": "system", "content": context.strip() },
            { "role": "user", "content": question.strip() }
        ],
        "model": LLM_MODEL_QUANTIZED,
        "n": 1,
        "temperature": 0
    }

    response = requests.post(url, headers=headers, json=data, timeout=300)
    response.raise_for_status()

    if 'choices' not in (response_json := response.json()):
        raise RuntimeError(f"Unable to find 'choices' in response:\n{response.text}")

    if len(choices := response_json['choices']) == 0:
        raise RuntimeError(f"'choices' is invalid in response:\n{response.text}")

    if 'message' not in (first_choice := choices[0]):
        raise RuntimeError(f"'message' not found in first 'choices' element in response:\n{response.text}")

    if 'content' not in (first_choice_message := first_choice['message']):
        raise RuntimeError(f"'content' not found in 'message' element in response:\n{response.text}")

    return first_choice_message['content']


def get_token_count(text: str, token_limit: int) -> Tuple[str, int]:
    '''
    Uses the AutoTokenizer from the transformers library to tokenize the provided text,
    truncate it if its token count exceeds token_limit, and return the number of tokens
    (including special tokens) in the original text.
    '''
    tokenizer = AutoTokenizer.from_pretrained(LLM_MODEL, revision=LLM_MODEL_REVISION)

    # Tokenize the text with special tokens, see https://github.com/mistralai/mistral-common/blob/ce444e276f348e03ae9bf6b6e9b73f3dde1793a2/src/mistral_common/tokens/tokenizers/sentencepiece.py#L191
    chat_completion_tokenized = tokenizer.encode(f'[INST] {text} [/INST]', add_special_tokens=True)

    original_token_count = len(chat_completion_tokenized)

    truncated_text = text
    if original_token_count > token_limit:
        # This will just tokenize the raw text (i.e. without special tokens).
        tokenized_text_no_specials = tokenizer.encode(text, add_special_tokens=False)
        special_token_count = original_token_count - len(tokenized_text_no_specials)

        # Need to ensure that <raw_text_tokenized_count> + <special_token_count> <= token_limit, but we want at least one.
        truncated_text_token_limit = max(token_limit - special_token_count, 1)
        truncated_text_tokenized = tokenized_text_no_specials[:truncated_text_token_limit]
        truncated_text = tokenizer.decode(truncated_text_tokenized, clean_up_tokenization_spaces=True)

    return truncated_text, original_token_count
