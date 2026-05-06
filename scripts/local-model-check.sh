#!/usr/bin/env bash
# Verify the local Gemma server is reachable at localhost:8080.
#
# Called by /ask-gemma and by /vault-ask (and other critical-path
# integrations) before routing a request to local. Fast-fails with an
# actionable message so the caller can surface it to the user.
#
# Exit codes:
#   0 — server reachable, model present
#   1 — server unreachable
#   2 — server reachable but expected model missing

set -euo pipefail

HOST="127.0.0.1"
PORT="8080"
EXPECTED_SUBSTR="gemma"

# jq is available from the Brewfile; fall back to grep if not
# (keeps the script usable in minimal environments).
if curl -fs --max-time 3 "http://$HOST:$PORT/v1/models" -o /tmp/.mlx-models.json 2>/dev/null; then
    if grep -qi "$EXPECTED_SUBSTR" /tmp/.mlx-models.json; then
        rm -f /tmp/.mlx-models.json
        exit 0
    fi
    echo "ERROR: mlx_lm.server is up on $HOST:$PORT but no model matching '$EXPECTED_SUBSTR' is loaded." >&2
    echo "Models returned:" >&2
    cat /tmp/.mlx-models.json >&2 2>/dev/null || true
    rm -f /tmp/.mlx-models.json
    exit 2
fi

cat >&2 <<EOF
ERROR: Local Gemma server not reachable at http://$HOST:$PORT
Start it manually:
    $(dirname "${BASH_SOURCE[0]}")/mlx-server-start.sh
Or check launchd status:
    launchctl list | grep -i mlx-server
Logs: ~/Library/Logs/mlx-server.log
EOF
exit 1
