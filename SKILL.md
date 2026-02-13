---
name: todoist
description: Manage Todoist tasks, projects, and labels. Use when the user mentions tasks, todos, Todoist, priorities, scheduling, task management, triage, time estimation, or any request involving their task list.
---

# Todoist Skill

Manage Todoist via a Python CLI that outputs JSON. Basic CRUD operations use the CLI directly. Intelligent operations (priority triage, smart scheduling, time estimation) combine CLI data with reasoning frameworks.

## Setup & Authentication

The CLI requires `TODOIST_API_TOKEN` as an environment variable. Add it to `~/.claude/.env` or your shell profile.

The first run auto-bootstraps a Python venv and installs dependencies. No manual setup needed.

**All CLI commands use this pattern:**

```bash
bash ~/.claude/skills/todoist/scripts/run.sh <resource> <action> [args...]
```

## CLI Reference

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

## Priority Mapping

The API uses inverted priority numbers. Always display UI labels to the user.

| UI Label | API Value | Use in CLI |
|----------|-----------|------------|
| P1 (urgent) | `4` | `--priority 4` |
| P2 (high) | `3` | `--priority 3` |
| P3 (medium) | `2` | `--priority 2` |
| P4 (low) | `1` | `--priority 1` |

## Basic Operations

### List tasks

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks list
bash ~/.claude/skills/todoist/scripts/run.sh tasks list --filter "today | overdue"
bash ~/.claude/skills/todoist/scripts/run.sh tasks list --project-id 12345
bash ~/.claude/skills/todoist/scripts/run.sh tasks list --label "work"
```

Parse the JSON output and present as a markdown table with columns: Task, Project, Priority, Due Date.

### Create a task

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks create --content "Review PR #42" --priority 3 --due-string "tomorrow" --labels "work,code-review"
```

### Quick add (natural language)

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks quick-add "Buy groceries tomorrow @Shopping #errands"
```

### Complete tasks

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks complete TASK_ID1 TASK_ID2
```

### Update a task

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks update TASK_ID --priority 4 --due-string "today"
```

### Batch update

Pass a JSON array of changes. Each entry must have an `id` field plus fields to update.

```bash
bash ~/.claude/skills/todoist/scripts/run.sh tasks batch-update '[{"id":"123","priority":4},{"id":"456","labels":"work,urgent"}]'
```

## Intelligent Operations

For priority triage, smart scheduling, or time estimation, read the reasoning frameworks first:

```
Read file: ~/.claude/skills/todoist/references/reasoning-frameworks.md
```

Then follow the propose-confirm-apply workflow below.

### Priority Triage

1. Read `references/reasoning-frameworks.md` (Priority Triage Framework section)
2. Fetch all tasks and projects
3. **Discover the user's prioritization preferences** before analyzing (see framework for key questions: how to handle scheduled tasks, blocked tasks, and re-prioritization tolerance)
4. Analyze each task using the Eisenhower matrix, heuristic signals, and the user's stated preferences
5. Propose **only the changes** (tasks where you'd shift priority) in a table — do not include unchanged tasks
6. After confirmation, apply with `tasks batch-update`

### Smart Scheduling

1. Read `references/reasoning-frameworks.md` (Smart Scheduling Framework section)
2. Fetch unscheduled tasks and completion history
3. Estimate daily capacity from history
4. Distribute tasks across days using the scheduling rules
5. Propose schedule in a table
6. After confirmation, apply with `tasks batch-update`

### Time Estimation

1. Read `references/reasoning-frameworks.md` (Time Estimation Framework section)
2. Fetch all tasks and **discover the user's existing time labels** — do not assume a hardcoded label set
3. Analyze the user's existing labeling patterns (which tasks map to which durations) to calibrate your estimates
4. Identify tasks without time labels
5. Estimate duration using the user's label set, their existing patterns, and the complexity heuristics in the framework
6. Propose **only the additions** in a table — do not include already-labeled tasks
7. After confirmation, apply with `tasks batch-update`

## Propose-Confirm-Apply Workflow

**Never apply changes without explicit user confirmation.** Follow this three-phase pattern:

### Phase 1: Propose

Present **only the diffs** — tasks where you're proposing a change. Do not include unchanged tasks. Include reasoning for each change.

Example for priority triage:

| # | Task | Current | Proposed | Reasoning |
|---|------|---------|----------|-----------|
| 1 | Deploy hotfix | P4 | P1 | Overdue, blocking release |
| 2 | Research new library | P2 | P4 | No deadline, exploratory |

End with: "Would you like me to apply these changes? You can also tell me to adjust specific items."

### Phase 2: Confirm (iterate if needed)

Wait for the user to approve, modify, or reject. The user may give feedback on **principles** (e.g., "scheduled tasks should reflect priority on the day they're due") rather than individual items. If so, revise the entire proposal using the updated principles and present a new table. Repeat until the user approves.

### Phase 3: Apply

After confirmation, execute via `tasks batch-update` with the agreed changes. Report results.

## Output Formatting

When presenting task data to the user:

- **Group tasks by project** with section headers when listing many tasks — a single flat table becomes unreadable past ~15 tasks
- Use markdown tables within each project group
- Map API priority values to UI labels (P1-P4)
- Format dates as human-readable (e.g., "Tomorrow", "Mon Jan 15")
- Truncate long task names in tables if needed
- Show project name, not project ID
- Include task count summaries (e.g., "Showing 12 tasks across 3 projects")
- Include labels (especially time estimates) as a column when relevant

## Error Handling

| Error | Response |
|-------|----------|
| Missing `TODOIST_API_TOKEN` | Tell the user to set the env var in `~/.claude/.env` or shell profile |
| API rate limit (429) | Wait briefly and retry once. If it persists, tell the user. |
| Network error | Tell the user to check connectivity |
| Invalid task ID | Tell the user the ID was not found |
| Venv issues | Delete `~/.claude/skills/todoist/.venv/` and retry — it auto-rebuilds |
