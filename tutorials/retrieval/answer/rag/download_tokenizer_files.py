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

from transformers import AutoTokenizer

LLM_MODEL_TOKENIZER = "mistralai/Mistral-7B-Instruct-v0.3"
LLM_MODEL_REVISION = "main"
HUGGINGFACE_API_TOKEN = "<YOUR_TOKEN>"

def get_tokenizer_files():
    """
    Accesses the AutoTokenizer from the transformers library to download files for later tokenization of provided text.
    """
    tokenizer = AutoTokenizer.from_pretrained(LLM_MODEL_TOKENIZER, revision=LLM_MODEL_REVISION).save_pretrained("./tokenizer_cache")

if HUGGINGFACE_API_TOKEN is not None:
    from huggingface_hub import login
    # Authenticate with Hugging Face
    login(HUGGINGFACE_API_TOKEN)

    get_tokenizer_files()
