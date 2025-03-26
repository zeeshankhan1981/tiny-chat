#!/bin/bash

# Create directory if it doesn't exist
mkdir -p PocketGPT/Resources

# Download Tiny Llama model
curl -L https://huggingface.co/eachadea/tinyllama-1.1b-chat-v1.0/resolve/main/tinyllama-1.1b-chat-v1.0-q2_k.gguf --output PocketGPT/Resources/tinyllama-1.1b-chat-v1.0-q2_k.gguf

echo "Tiny Llama model downloaded successfully!"
