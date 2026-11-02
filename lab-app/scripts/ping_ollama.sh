#!/usr/bin/env bash
# Setup — Send a test "ping" prompt to Ollama to confirm the port-forward and model work
#
# Usage:
#   ./ping_ollama.sh
#   OPENAI_BASE_URL=https://your-fortiaigate-host/v1 ./ping_ollama.sh

OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://localhost:11434/v1}"
MODEL="${MODEL:-qwen2.5:3b}"

response=$(curl -s --max-time 120 "${OPENAI_BASE_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}]}")

if [ -z "$response" ]; then
  echo "No response from ${OPENAI_BASE_URL}. Is the Ollama port-forward running?" >&2
  exit 1
fi

echo "$response" | jq -r '.choices[0].message.content'
