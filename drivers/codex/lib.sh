#!/usr/bin/env bash
set -euo pipefail

forge_frontmatter_value() {
  local file="$1"
  local key="$2"

  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" \
    | awk -F: -v key="$key" '$1 == key { sub(/^[^:]+:[[:space:]]*/, "", $0); gsub(/^"|"$/, "", $0); print; exit }'
}

forge_recorded_iteration() {
  local forge_state="$1"
  local recorded

  recorded="$(sed -n 's/^## Iteration \([0-9][0-9]*\).*/\1/p' "$forge_state" | tail -1)"
  if [[ -z "$recorded" ]]; then
    printf '0\n'
  else
    printf '%s\n' "$recorded"
  fi
}

forge_active_sessions() {
  local state_dir="$1"
  find "$state_dir" -maxdepth 1 -name 'loop-state.*.md' -type f -print | sort | while read -r file; do
    local active
    active="$(forge_frontmatter_value "$file" "active")"
    if [[ "$active" == "true" ]]; then
      basename "$file" | sed 's/^loop-state\.//; s/\.md$//'
    fi
  done
}

forge_choose_session() {
  local state_dir="$1"
  local explicit_session="${2:-}"
  local active_sessions=()
  local session

  if [[ -n "$explicit_session" ]]; then
    printf '%s\n' "$explicit_session"
    return 0
  fi

  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
    active_sessions+=("$session")
  done < <(forge_active_sessions "$state_dir")

  if [[ "${#active_sessions[@]}" -eq 0 ]]; then
    echo "Error: No active Codex Forge loop found in .codex/forge." >&2
    return 1
  fi

  if [[ "${#active_sessions[@]}" -gt 1 ]]; then
    echo "Error: Multiple active Codex Forge sessions found. Pass a session id explicitly." >&2
    printf '%s\n' "${active_sessions[@]}" >&2
    return 1
  fi

  printf '%s\n' "${active_sessions[0]}"
}

forge_render_prompt() {
  local template="$1"
  local session_id="$2"
  local scope="$3"
  local iteration="$4"

  sed \
    -e "s/{SESSION}/${session_id}/g" \
    -e "s/{SCOPE}/${scope//\//\\/}/g" \
    -e "s/{ITERATION}/${iteration}/g" \
    "$template"
}
