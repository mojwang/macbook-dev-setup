#!/usr/bin/env bash
# Ad-hoc local-Gemma query helper. Called by the /ask-gemma slash
# command (see .claude/commands/ask-gemma.md). Verifies the local
# server is up, then shells out to curl against the OpenAI-compatible
# /v1/chat/completions endpoint.
#
# Flags:
#   --file <path>     Inject file content as user-message prefix.
#   --system "..."    Explicit system prompt (default: terse assistant).
#   --max-tokens N    Cap output length (default 1024).
#
# Positional: the rest of the args form the prompt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="127.0.0.1"
PORT="8080"
# mlx_lm.server uses the model field as an HF repo identifier.
# Passing "local" or any placeholder triggers a fetch. Must match
# the model loaded by mlx-server-start.sh.
MODEL="mlx-community/gemma-4-31b-it-4bit"

SYSTEM_DEFAULT="You are a terse, no-filler assistant. Prefer concrete answers over hedging. If uncertain, say so in one sentence."
SYSTEM="$SYSTEM_DEFAULT"
FILE=""
MAX_TOKENS=1024

# Flag parsing. Unknown flags fall through to the prompt.
# Using array-slice pattern for safe $2 access under set -u (see
# log-session.sh for the same idiom).
_require_value() {
    local flag="$1"; shift
    if [[ $# -lt 1 || "$1" == -* ]]; then
        echo "Error: $flag requires a value" >&2
        exit 2
    fi
}

PROMPT_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)
            _require_value "--file" "${@:2:1}"
            FILE="$2"; shift 2 ;;
        --system)
            _require_value "--system" "${@:2:1}"
            SYSTEM="$2"; shift 2 ;;
        --max-tokens)
            _require_value "--max-tokens" "${@:2:1}"
            MAX_TOKENS="$2"; shift 2 ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [--file <path>] [--system "..."] [--max-tokens N] <prompt>

Query the local Gemma 4 31B IT server at http://$HOST:$PORT.

Examples:
  $(basename "$0") "What's a good k8s HPA min-replicas heuristic?"
  $(basename "$0") --file note.md "Summarize in one paragraph"
  $(basename "$0") --max-tokens 20 "Count to 100"
EOF
            exit 0 ;;
        *)
            PROMPT_ARGS+=("$1"); shift ;;
    esac
done

if [[ ${#PROMPT_ARGS[@]} -eq 0 ]]; then
    echo "Error: no prompt provided" >&2
    echo "Usage: $(basename "$0") [flags] <prompt>" >&2
    exit 2
fi

PROMPT="${PROMPT_ARGS[*]}"

# If --file is set, prepend file content as user-message prefix.
if [[ -n "$FILE" ]]; then
    if [[ ! -f "$FILE" ]]; then
        echo "Error: file not found: $FILE" >&2
        exit 1
    fi
    FILE_CONTENT=$(cat "$FILE")
    USER_MSG="Context (file: $FILE):
---
$FILE_CONTENT
---

$PROMPT"
else
    USER_MSG="$PROMPT"
fi

# Server preflight. Fast-fail with actionable error from the check script.
if ! "$SCRIPT_DIR/local-model-check.sh"; then
    exit 1
fi

# Build the JSON payload safely using jq (avoids shell-quoting hell
# when prompts contain quotes, backticks, newlines, etc.).
PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --arg system "$SYSTEM" \
    --arg user "$USER_MSG" \
    --argjson max "$MAX_TOKENS" \
    '{
        model: $model,
        messages: [
            {role: "system", content: $system},
            {role: "user",   content: $user}
        ],
        max_tokens: $max,
        stream: false
    }')

# Query the OpenAI-compatible endpoint and extract the content.
# Use -f to treat HTTP non-2xx as failure; -sS keeps output quiet on
# success and shows errors on failure.
RESPONSE=$(curl -fsS --max-time 120 \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "http://$HOST:$PORT/v1/chat/completions")

# Extract the assistant's message. Gemma (and other CoT-capable
# models served by mlx_lm.server) produce both .choices[0].message.content
# (final answer) and .choices[0].message.reasoning (internal chain-of-
# thought). If max_tokens is too low the reasoning can consume the
# entire budget, leaving content empty. Prefer content; fall back to
# labeled reasoning; else surface raw.
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null || true)
REASONING=$(echo "$RESPONSE" | jq -r '.choices[0].message.reasoning // empty' 2>/dev/null || true)
FINISH=$(echo "$RESPONSE" | jq -r '.choices[0].finish_reason // empty' 2>/dev/null || true)

if [[ -n "$CONTENT" ]]; then
    printf '%s\n' "$CONTENT"
    # If output was truncated, flag it so the caller knows to retry
    # with a higher --max-tokens.
    if [[ "$FINISH" == "length" ]]; then
        echo "" >&2
        echo "(truncated — finish_reason=length; raise --max-tokens to get the full response)" >&2
    fi
elif [[ -n "$REASONING" ]]; then
    # Content empty but reasoning present — max_tokens was too tight.
    echo "(no final answer produced; showing reasoning trace — raise --max-tokens)" >&2
    printf '%s\n' "$REASONING"
    exit 0
else
    echo "ERROR: unexpected response shape — raw:" >&2
    echo "$RESPONSE" >&2
    exit 1
fi
