#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$SKILL_DIR/.venv"

# Bootstrap venv if missing
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR" >&2
  "$VENV_DIR/bin/pip" install --quiet -r "$SKILL_DIR/requirements.txt" >&2
fi

# Validate API token
if [ -z "${TODOIST_API_TOKEN:-}" ]; then
  echo '{"error": "TODOIST_API_TOKEN environment variable is not set. Add it to your ~/.claude/.env or shell profile."}' >&2
  exit 1
fi

exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/todoist_cli.py" "$@"
