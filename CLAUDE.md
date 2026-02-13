# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code skill that lets Claude manage a user's Todoist account. It consists of a Python CLI wrapping the Todoist REST API (JSON output), a shell bootstrapper, a skill definition (`SKILL.md`), and reasoning frameworks for intelligent task operations.

## Running the CLI

```bash
bash scripts/run.sh <resource> <action> [args...]
```

The first run auto-creates a `.venv/` and installs dependencies from `requirements.txt`. Requires `TODOIST_API_TOKEN` env var.

## Architecture

```
SKILL.md                              # Skill definition — tells Claude when/how to use the CLI
  └─ references/reasoning-frameworks.md  # Decision frameworks for triage, scheduling, estimation
      └─ scripts/run.sh               # Shell bootstrapper (venv setup, token validation)
          └─ scripts/todoist_cli.py    # Python CLI (argparse, JSON output, Todoist SDK)
              └─ Todoist REST API
```

**CLI structure**: Two-level argparse subparsers (`resource` → `action`). Each handler is decorated with `@handle_errors` for uniform JSON error output to stderr. All successful output goes to stdout as JSON via `output()`.

**Resources**: `tasks` (list/get/create/quick-add/complete/update/batch-update), `projects` (list/get), `labels` (list/create/ensure), `history` (completed tasks by date range).

**Key patterns**:
- JSON bridge: stdout = data, stderr = errors, exit 1 on failure
- Self-bootstrapping venv in `run.sh` (output to stderr to keep stdout clean)
- Lazy import of `todoist_api_python` inside `get_api()`
- `collect_all()` drains cursor-based paginators into flat lists of dicts
- `batch-update` catches errors per-task (graceful partial failure)
- Priority is inverted: P1 (urgent) = API value `4`, P4 (low) = API value `1`

**Intelligent operations** (triage, scheduling, estimation) follow a propose-confirm-apply workflow defined in `SKILL.md`. Claude reads the reasoning frameworks, fetches data via CLI, applies frameworks, proposes changes in a diff table, waits for user confirmation, then applies via `batch-update`.

## Dependencies

Single Python dependency: `todoist-api-python==3.2.1` (pinned in `requirements.txt`).

## No Tests

There is no test suite. The CLI is tested manually against the live Todoist API.
