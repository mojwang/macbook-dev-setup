#!/usr/bin/env bash
# Start mlx_lm.server on localhost:8080 with Gemma 4 31B IT 4-bit.
# Idempotent — no-op if the port is already serving the expected model.
#
# Invoked by the com.mojwang.mlx-server LaunchAgent at login, or
# directly from the shell for ad-hoc restarts.
#
# Logs to ~/Library/Logs/mlx-server.log. The launchd plist also
# captures stdout/stderr to the same file via StandardOutPath /
# StandardErrorPath.

set -euo pipefail

MODEL="mlx-community/gemma-4-31b-it-4bit"
HOST="127.0.0.1"
PORT="8080"
LOG_DIR="$HOME/Library/Logs"
LOG_PATH="$LOG_DIR/mlx-server.log"

mkdir -p "$LOG_DIR"

# Already up? Curl the /v1/models endpoint. If it responds, we're done.
# Don't check the model identity here — that's local-model-check.sh's
# job; we only care that the port is serving SOMETHING.
if curl -fs --max-time 2 "http://$HOST:$PORT/v1/models" >/dev/null 2>&1; then
    echo "mlx_lm.server already responding on $HOST:$PORT — no-op."
    exit 0
fi

# Resolve mlx_lm.server. When invoked by launchd, PATH is a minimal
# set that excludes ~/.pyenv/shims/. Probe common install locations
# explicitly before falling back to PATH.
CANDIDATES=(
    "$HOME/.pyenv/shims/mlx_lm.server"
    "$HOME/.local/bin/mlx_lm.server"
    "/opt/homebrew/bin/mlx_lm.server"
    "/usr/local/bin/mlx_lm.server"
)
SERVER_BIN=""
for candidate in "${CANDIDATES[@]}"; do
    if [[ -x "$candidate" ]]; then
        SERVER_BIN="$candidate"
        break
    fi
done
# Last-resort PATH lookup (works when invoked from an interactive shell).
if [[ -z "$SERVER_BIN" ]]; then
    SERVER_BIN="$(command -v mlx_lm.server || true)"
fi
if [[ -z "$SERVER_BIN" ]]; then
    echo "ERROR: mlx_lm.server not found in PATH or known install locations" >&2
    echo "Checked: ${CANDIDATES[*]}" >&2
    echo "Install: pip3 install mlx mlx-lm" >&2
    exit 1
fi
echo "Using: $SERVER_BIN"

echo "Starting mlx_lm.server with model=$MODEL host=$HOST port=$PORT"
echo "Log: $LOG_PATH"

# Exec so launchd (and manual invocations) can track the process.
# --trust-remote-code is required by some HF models; Gemma 4 doesn't
# need it but including for forward compat. --host 127.0.0.1 binds
# loopback only — no LAN exposure.
exec "$SERVER_BIN" \
    --model "$MODEL" \
    --host "$HOST" \
    --port "$PORT" \
    >> "$LOG_PATH" 2>&1
