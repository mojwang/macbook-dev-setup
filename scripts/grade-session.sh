#!/usr/bin/env bash
# Retroactively grade rows in scripts/.session-cost.log whose outcome
# field is empty. Writes to a temp file + mv to guarantee atomicity —
# a partial rewrite can never leave the live log in a half-edited state.
#
# Companion to /log-session (P0.2). Roadmap: P0.3 from 2026-04-19.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_PATH="$REPO_ROOT/scripts/.session-cost.log"

COUNT_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --count) COUNT_ONLY=1; shift ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [--count]

Walks rows in $LOG_PATH whose outcome field (5th column) is empty and
prompts for a grade. Grades are written via temp-then-mv for atomicity.

  --count    Report the number of ungraded rows; do not prompt.

Outcome enum: shipped | partial | reverted | blocked | plan-only
(Use 'skip' to leave a row ungraded for now.)
EOF
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

if [[ ! -f "$LOG_PATH" ]]; then
    echo "No log at $LOG_PATH — nothing to grade. (Run /log-session first.)"
    exit 0
fi

# A row is "ungraded" when field 5 (outcome) is empty. The logger
# always writes exactly " | " between fields; an empty outcome therefore
# appears as "|  |" at that column boundary. Counting on awk with the
# pipe separator is more precise than a regex against the raw string.
is_ungraded() {
    awk -F'|' '{
        gsub(/^[ \t]+|[ \t]+$/, "", $5)
        exit ($5 == "" ? 0 : 1)
    }' <<<"$1"
}

# Gather ungraded row numbers up front so we can show progress.
mapfile_compat() {
    # bash 3.2 on macOS lacks `mapfile`. Use while-read instead.
    local _line _i=0
    while IFS= read -r _line; do
        _i=$((_i + 1))
        if is_ungraded "$_line"; then
            printf '%s\n' "$_i"
        fi
    done < "$LOG_PATH"
}

UNGRADED_LINENOS=()
while IFS= read -r lineno; do
    UNGRADED_LINENOS+=("$lineno")
done < <(mapfile_compat)

UNGRADED_COUNT=${#UNGRADED_LINENOS[@]}

if [[ $COUNT_ONLY -eq 1 ]]; then
    echo "$UNGRADED_COUNT"
    exit 0
fi

if [[ $UNGRADED_COUNT -eq 0 ]]; then
    echo "No ungraded rows in $LOG_PATH."
    exit 0
fi

echo "Found $UNGRADED_COUNT ungraded row(s) in $LOG_PATH."
echo "Grade enum: shipped | partial | reverted | blocked | plan-only | skip"
echo ""

# Read full log into memory. Session log is append-only and small
# (one row per session); megabytes not in play at any realistic horizon.
LOG_LINES=()
while IFS= read -r _line; do
    LOG_LINES+=("$_line")
done < "$LOG_PATH"

VALID_GRADES="shipped partial reverted blocked plan-only"

updated=0
for lineno in "${UNGRADED_LINENOS[@]}"; do
    idx=$((lineno - 1))
    row="${LOG_LINES[idx]}"
    echo "[$lineno] $row"
    while :; do
        read -r -p "  Grade (or 'skip'): " grade </dev/tty || grade=""
        grade="${grade// /}"
        if [[ -z "$grade" ]]; then
            echo "  (empty — enter a grade or 'skip')" >&2
            continue
        fi
        if [[ "$grade" == "skip" ]]; then
            break
        fi
        if [[ " $VALID_GRADES " == *" $grade "* ]]; then
            # Replace field 5 in this row, preserving spacing on either
            # side of the pipes. awk with FS="|" splits on bare pipes,
            # but the logger writes " | " with surrounding spaces — so
            # we need to match the logger's exact format. Use awk to
            # rebuild the row with OFS=" | " and a trimmed-in field.
            LOG_LINES[idx]=$(
                awk -v g="$grade" -F'|' 'BEGIN{OFS=" | "} {
                    for (i=1; i<=NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
                    $5 = g
                    print
                }' <<<"$row"
            )
            updated=$((updated + 1))
            break
        fi
        echo "  Invalid: '$grade'. Use one of: $VALID_GRADES | skip" >&2
    done
done

if [[ $updated -eq 0 ]]; then
    echo "No rows updated."
    exit 0
fi

# Atomic rewrite: write to .tmp then mv. On any crash between the two,
# the live log is still the pre-edit file — never a half-edit.
TMP_PATH="$LOG_PATH.tmp"
: > "$TMP_PATH"
for line in "${LOG_LINES[@]}"; do
    printf '%s\n' "$line" >> "$TMP_PATH"
done
mv "$TMP_PATH" "$LOG_PATH"

echo ""
echo "Updated $updated row(s). Remaining ungraded: $((UNGRADED_COUNT - updated))."
