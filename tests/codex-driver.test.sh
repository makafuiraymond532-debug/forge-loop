#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_PATH="${ROOT_DIR}/drivers/codex/bin/forge-init"
CONTINUE_PATH="${ROOT_DIR}/drivers/codex/bin/forge-continue"
CANCEL_PATH="${ROOT_DIR}/drivers/codex/bin/forge-cancel"
INSTALL_PATH="${ROOT_DIR}/install-codex.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "${message}: missing '${needle}'"
  fi
}

assert_file() {
  local path="$1"
  local message="$2"

  if [[ ! -f "$path" ]]; then
    fail "${message}: missing file '${path}'"
  fi
}

test_codex_init_continue_cancel() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  (
    cd "$repo_dir"
    output_init="$("$INIT_PATH" "API controllers" --coverage 90 --speed -30% --quality strict --max-iterations 5)"
    assert_contains "$output_init" "Initialized Forge Codex driver session" "forge-init should initialize a session"
    session_id="$(printf '%s\n' "$output_init" | awk '/Initialized Forge Codex driver session/ {print $6}' | tr -d '.')"
    assert_file ".codex/forge/forge-state.${session_id}.md" "forge-init should create Forge state"
    assert_file ".codex/forge/loop-state.${session_id}.md" "forge-init should create loop state"

    output_continue="$("$CONTINUE_PATH" "$session_id")"
    assert_contains "$output_continue" "iteration 1" "forge-continue should report current iteration before incrementing"
    next_iteration="$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' ".codex/forge/loop-state.${session_id}.md" | awk -F: '$1=="iteration" { sub(/^[^:]+:[[:space:]]*/, "", $0); print; exit }')"
    [[ "$next_iteration" == "2" ]] || fail "forge-continue should increment iteration to 2"

    output_cancel="$("$CANCEL_PATH" "$session_id")"
    assert_contains "$output_cancel" "Cancelled Forge Codex driver session ${session_id}." "forge-cancel should cancel the session"
    [[ ! -f ".codex/forge/loop-state.${session_id}.md" ]] || fail "forge-cancel should remove loop state"
    assert_file ".codex/forge/forge-state.${session_id}.md" "forge-cancel should preserve Forge state"
  )
  rm -rf "$repo_dir"
}

test_codex_install() {
  local repo_dir tmp_home
  repo_dir="$(mktemp -d)"
  tmp_home="$(mktemp -d)"
  (
    cd "$ROOT_DIR"
    output_install="$(HOME="$tmp_home" "$INSTALL_PATH")"
    assert_contains "$output_install" "Installing forge-loop Codex driver" "install-codex should announce itself"
    assert_file "$tmp_home/.codex/skills/forge/SKILL.md" "install-codex should link Forge skill"
    assert_file "$tmp_home/.codex/bin/forge-init" "install-codex should link forge-init"
    assert_file "$tmp_home/.codex/bin/forge-continue" "install-codex should link forge-continue"
    assert_file "$tmp_home/.codex/bin/forge-cancel" "install-codex should link forge-cancel"
  )
  rm -rf "$repo_dir" "$tmp_home"
}

main() {
  test_codex_init_continue_cancel
  test_codex_install
  echo "codex-driver tests passed"
}

main "$@"
