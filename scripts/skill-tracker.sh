#!/usr/bin/env bash
set -e

# Track skill execution dates and detect staleness.
# Usage:
#   skill-tracker.sh update <skill-name>        — record that a skill ran today
#   skill-tracker.sh check                      — report stale skills
#   skill-tracker.sh status                     — show all tracked skills

TRACKER_FILE=".skill-runs.json"

# Staleness thresholds (days)
declare -A THRESHOLDS=(
  ["entropy-scan"]=14
  ["competitive-audit"]=90
  ["doc-garden"]=7
)

ensure_tracker() {
  if [[ ! -f "$TRACKER_FILE" ]]; then
    echo '{}' > "$TRACKER_FILE"
  fi
}

cmd_update() {
  local skill="${1:?Usage: skill-tracker.sh update <skill-name>}"
  local today
  today=$(date +%Y-%m-%d)
  ensure_tracker

  # Use python3 for JSON manipulation (available on macOS)
  python3 -c "
import json, sys
with open('$TRACKER_FILE') as f:
    data = json.load(f)
data['$skill'] = '$today'
with open('$TRACKER_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
  echo "Updated ${skill}: ${today}"
}

cmd_check() {
  ensure_tracker
  local today_epoch
  today_epoch=$(date +%s)
  local has_warnings=false

  for skill in "${!THRESHOLDS[@]}"; do
    threshold="${THRESHOLDS[$skill]}"
    last_run=$(python3 -c "
import json
with open('$TRACKER_FILE') as f:
    data = json.load(f)
print(data.get('$skill', ''))
" 2>/dev/null)

    if [[ -z "$last_run" ]]; then
      echo "⚠ ${skill}: never run (threshold: ${threshold} days)"
      has_warnings=true
    else
      last_epoch=$(date -j -f "%Y-%m-%d" "$last_run" +%s 2>/dev/null || date -d "$last_run" +%s 2>/dev/null || echo "0")
      if [[ "$last_epoch" -gt 0 ]]; then
        age_days=$(( (today_epoch - last_epoch) / 86400 ))
        if [[ "$age_days" -gt "$threshold" ]]; then
          echo "⚠ ${skill}: last run ${age_days} days ago (threshold: ${threshold} days)"
          has_warnings=true
        fi
      fi
    fi
  done

  if [[ "$has_warnings" == "false" ]]; then
    echo "✓ All tracked skills within thresholds"
  fi
}

cmd_status() {
  ensure_tracker
  echo "Skill run history:"
  python3 -c "
import json
with open('$TRACKER_FILE') as f:
    data = json.load(f)
for skill, date in sorted(data.items()):
    print(f'  {skill}: {date}')
if not data:
    print('  (no skills tracked yet)')
"
}

case "${1:-}" in
  update) cmd_update "$2" ;;
  check) cmd_check ;;
  status) cmd_status ;;
  *) echo "Usage: skill-tracker.sh {update|check|status} [skill-name]"; exit 1 ;;
esac
