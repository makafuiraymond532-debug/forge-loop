# Forge Codex Driver

The Codex driver is manual by design.

It reuses Forge Core, but does not depend on Claude Code commands or stop hooks.
Instead it ships small shell entrypoints that manage loop state and print the
next prompt to run in Codex.

## Files

- `bin/forge-init` — create a new Forge session for the current project
- `bin/forge-continue` — print the next iteration prompt for an existing session
- `bin/forge-cancel` — cancel the active Codex Forge loop without deleting forge-state
- `prompt.md` — shared prompt template used by the driver scripts

## State layout

The Codex driver stores state under `.codex/forge/` in the target project:

- `.codex/forge/forge-state.SESSION.md` — Forge Core KPI/state file
- `.codex/forge/loop-state.SESSION.md` — Codex driver loop metadata

The Forge state format stays compatible with Forge Core. Only the driver state
location differs from the Claude Code adapter.
