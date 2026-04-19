#!/usr/bin/env bash
# Append a single row to scripts/.session-cost.log capturing this
# session's directional cost signal (dispatches, models, outcome) plus
# an agent_sha that ties the row to a specific `.claude/agents/` version.
#
# Invoked by the /log-session slash command at end of a session, or
# directly from the shell. Fields are documented in
# docs/CLAUDE_AGENTS.md.
#
# Roadmap reference: P0.2 from the 2026-04-19 overnight research.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_PATH="$REPO_ROOT/scripts/.session-cost.log"

TOPIC=""
DISPATCHES=""
MODELS=""
OUTCOME=""
# Only outcome has a legitimate empty value (grade later via /grade-session).
# A sentinel lets `--outcome ""` bypass the prompt explicitly; missing
# --outcome still prompts interactively.
OUTCOME_SET=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [--topic "..."] [--dispatches "..."] [--models "..."] [--outcome "..."]

Appends one row to scripts/.session-cost.log.

Missing required fields are prompted interactively. Outcome is validated
against the enum: shipped | partial | reverted | blocked | plan-only
(empty allowed — grade later via /grade-session).

Fields:
  --topic        One-line session summary (required)
  --dispatches   Agent count x tier, e.g. "Explore x3, Plan x1" or "—"
  --models       Comma-separated models used, e.g. "haiku,sonnet"
  --outcome      One of: shipped | partial | reverted | blocked | plan-only | (empty)
EOF
}

# Defense against `--flag` passed with no value (e.g. last arg of the
# line) or with another flag as its value. Without these guards, `set -u`
# aborts on `$2` with "unbound variable" — opaque for the user. The
# short-circuit `$# -lt 2` keeps `$2` from being evaluated when there's
# only one arg left.
_require_value() {
    local flag="$1"; shift
    if [[ $# -lt 1 || "$1" == -* ]]; then
        echo "Error: $flag requires a value" >&2
        usage >&2
        exit 2
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --topic)      _require_value "$1" "${@:2:1}"; TOPIC="$2"; shift 2 ;;
        --dispatches) _require_value "$1" "${@:2:1}"; DISPATCHES="$2"; shift 2 ;;
        --models)     _require_value "$1" "${@:2:1}"; MODELS="$2"; shift 2 ;;
        --outcome)    _require_value "$1" "${@:2:1}"; OUTCOME="$2"; OUTCOME_SET=1; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# Prompt for missing required fields. Outcome is optional (grade later).
if [[ -z "$TOPIC" ]]; then
    read -r -p "Session topic (one line): " TOPIC
fi
if [[ -z "$DISPATCHES" ]]; then
    read -r -p "Dispatches (e.g. 'Explore x3, Plan x1' or '—'): " DISPATCHES
fi
if [[ -z "$MODELS" ]]; then
    read -r -p "Models used (comma-separated, e.g. 'haiku,sonnet'): " MODELS
fi
if [[ $OUTCOME_SET -eq 0 ]]; then
    read -r -p "Outcome (shipped|partial|reverted|blocked|plan-only, empty = grade later): " OUTCOME
fi

# Validate outcome enum when non-empty.
case "$OUTCOME" in
    ""|shipped|partial|reverted|blocked|plan-only) ;;
    *)
        echo "Invalid outcome: '$OUTCOME'" >&2
        echo "Must be one of: shipped | partial | reverted | blocked | plan-only | (empty)" >&2
        exit 2
        ;;
esac

# Guard against pipe characters in fields — they'd break the pipe-
# delimited format. Replace with ' ; ' (with spaces) as a deliberately
# visible sentinel so sanitized rows stand out in any weekly-review
# listing and prompt a manual cleanup.
sanitize() {
    local value="${1//|/ ; }"
    value="${value//$'\n'/ }"
    printf '%s' "$value"
}
TOPIC=$(sanitize "$TOPIC")
DISPATCHES=$(sanitize "$DISPATCHES")
MODELS=$(sanitize "$MODELS")

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

# Short SHA of the most recent commit that touched .claude/agents/.
# Ties a row to a specific agent-prompt version so we can correlate
# outcomes with prompt changes later (P5.1 meta-agent).
AGENT_SHA="unknown"
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    sha=$(git -C "$REPO_ROOT" log -1 --format=%h -- .claude/agents/ 2>/dev/null || true)
    if [[ -n "$sha" ]]; then
        AGENT_SHA="$sha"
    fi
fi

# Ensure the log file exists (gitignored; first run creates it).
mkdir -p "$(dirname "$LOG_PATH")"
touch "$LOG_PATH"

ROW="$TIMESTAMP | $TOPIC | $DISPATCHES | $MODELS | $OUTCOME | $AGENT_SHA"
printf '%s\n' "$ROW" >> "$LOG_PATH"

echo "Logged: $ROW"
echo "→ $LOG_PATH"
