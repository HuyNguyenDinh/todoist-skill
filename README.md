# Todoist Skill for Claude Code

A [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that lets Claude manage your Todoist account through natural language. Supports basic CRUD operations and intelligent operations like priority triage, smart scheduling, and time estimation.

## Setup

1. **Install the skill** by symlinking or copying this repo into your Claude Code skills directory:

   ```bash
   ln -s /path/to/todoist-skill ~/.claude/skills/todoist
   ```

2. **Set your Todoist API token** in `~/.claude/.env` or your shell profile:

   ```
   TODOIST_API_TOKEN=your_token_here
   ```

   You can find your API token at [Settings > Integrations > Developer](https://app.todoist.com/app/settings/integrations/developer) in Todoist.

3. **That's it.** The first run auto-creates a Python virtual environment and installs dependencies. No manual setup needed.

## What It Can Do

### Basic Operations

- List, create, update, and complete tasks
- Quick-add tasks with natural language (e.g., "Buy groceries tomorrow @Shopping")
- Batch update multiple tasks at once
- List and manage projects and labels
- Query completed task history

### Intelligent Operations

These combine task data with reasoning frameworks to help you manage your task list:

- **Priority Triage** — Analyzes all tasks using an Eisenhower matrix adaptation, proposes priority changes based on urgency/importance signals and your preferences
- **Smart Scheduling** — Estimates your daily capacity from completion history, distributes unscheduled tasks across days following scheduling rules (deadline buffers, project round-robin, priority front-loading)
- **Time Estimation** — Discovers your existing time labels and labeling patterns, estimates duration for unlabeled tasks using your calibration and complexity heuristics

All intelligent operations follow a **propose-confirm-apply** workflow: Claude proposes changes in a diff table, you review and iterate, then Claude applies the agreed changes.

## Usage

Once installed, just talk to Claude naturally:

- "Show me my tasks for today"
- "Create a task to review PR #42, due tomorrow, high priority"
- "Triage my task priorities"
- "Schedule my unscheduled tasks for this week"
- "Estimate time for my unlabeled tasks"
- "Complete the grocery shopping task"

## Project Structure

```
SKILL.md                            # Skill definition (when/how Claude uses the CLI)
scripts/
  run.sh                            # Shell entry point (venv bootstrap, token validation)
  todoist_cli.py                    # Python CLI (argparse, JSON output via Todoist SDK)
references/
  reasoning-frameworks.md           # Decision frameworks for triage, scheduling, estimation
requirements.txt                    # Python dependency: todoist-api-python==3.2.1
```

## CLI Reference

The CLI is designed for Claude to call, but you can also use it directly:

```bash
bash scripts/run.sh <resource> <action> [args...]
```

| Command | Description |
|---------|-------------|
| `tasks list [--filter Q] [--project-id ID] [--label NAME]` | List active tasks |
| `tasks get TASK_ID` | Get a single task |
| `tasks create --content TEXT [--due-string DUE] [--priority 1-4] [--project-id ID] [--labels L1,L2] [--description DESC]` | Create a task |
| `tasks quick-add TEXT` | Natural language task creation |
| `tasks complete TASK_ID [TASK_ID ...]` | Complete one or more tasks |
| `tasks update TASK_ID [--content] [--due-string] [--priority] [--labels] [--description]` | Update a task |
| `tasks batch-update CHANGES_JSON` | Batch update from JSON array |
| `projects list` | List all projects |
| `projects get PROJECT_ID` | Get a single project |
| `labels list` | List all labels |
| `labels create --name NAME [--color COLOR]` | Create a label |
| `labels ensure NAMES_CSV` | Ensure labels exist (idempotent) |
| `history --since YYYY-MM-DD [--until YYYY-MM-DD]` | Completed tasks in date range |

**Note:** Priority values are inverted in the API. P1 (urgent) = `--priority 4`, P4 (low) = `--priority 1`.

## Requirements

- Python 3
- A [Todoist API token](https://app.todoist.com/app/settings/integrations/developer)
- Claude Code
