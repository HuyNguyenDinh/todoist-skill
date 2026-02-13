# Reasoning Frameworks for Intelligent Todoist Operations

Use these frameworks when the user asks for help with priority triage, smart scheduling, or time estimation. Read the relevant section, reason about the user's tasks, then propose changes using the propose-confirm-apply workflow.

---

## Priority Triage Framework

### Priority Mapping

| UI Label | API Value | Meaning |
|----------|-----------|---------|
| P1 | `4` | Urgent — must be done today or has hard deadline |
| P2 | `3` | High — important, should be done this week |
| P3 | `2` | Medium — worth doing, flexible timing |
| P4 | `1` | Low / normal — nice to have, no pressure |

Always use API values (1-4) in CLI calls. Display UI labels (P1-P4) to the user.

### Eisenhower Matrix Adaptation

Classify each task along two axes:

- **Urgent**: Has a hard deadline, someone is waiting, blocking others, or has real consequences if delayed.
- **Important**: Advances key goals, high-impact, aligns with stated priorities, or has compounding value.

| | Urgent | Not Urgent |
|---|---|---|
| **Important** | P1 — Do first | P2 — Schedule soon |
| **Not Important** | P3 — Delegate or quick-do | P4 — Backlog or drop |

### Heuristic Signals

Scan task content, descriptions, and context for signals:

**Urgency signals → raise priority:**
- Keywords: "ASAP", "urgent", "deadline", "blocking", "overdue", "today", "emergency"
- Overdue due dates
- Tasks in "Inbox" without a project (likely captured quickly = time-sensitive)

**Importance signals → raise priority:**
- Keywords: "launch", "release", "client", "presentation", "review", "deploy", "interview"
- Tasks with multiple labels (indicates cross-cutting significance)
- Subtasks of high-priority parents

**Low-priority signals → lower priority:**
- Keywords: "maybe", "someday", "explore", "idea", "nice to have", "optional", "research"
- No due date and no project assignment
- Tasks created long ago with no activity

### User Preference Discovery

Before analyzing tasks, surface these key preferences — they significantly affect the outcome:

1. **Scheduled/recurring task priority**: Should priority reflect the task's importance *on the day it's scheduled*? (e.g., "Take out trash" is P1 on trash day because it must happen that day.) If yes, don't lower priorities on recurring/scheduled tasks just because the date is far away.

2. **Blocked/sequential task priority**: Should downstream tasks be deprioritized because they're blocked, or prioritized based on their intrinsic importance as if unblocked? Users who prefer "set and forget" want intrinsic priority so they don't have to re-prioritize as blockers clear.

3. **Re-prioritization tolerance**: Does the user want priorities they'll revisit frequently, or priorities they can set once and leave alone?

If the user hasn't stated preferences, ask before proposing changes. These aren't edge cases — they determine the entire approach.

### Triage Process

1. Fetch all active tasks (`tasks list`)
2. Fetch projects for context (`projects list`)
3. **Discover user preferences** using the questions above
4. For each task, assess urgency and importance using the signals above **and** the user's stated preferences
5. Propose **only the changes** in a table: Task | Current Priority | Proposed Priority | Reasoning — do not include tasks where the priority stays the same
6. Wait for user confirmation — the user may refine principles rather than individual items; if so, revise the full proposal
7. Apply via `tasks batch-update`

---

## Smart Scheduling Framework

### Capacity Estimation

Check recent completion history to estimate daily capacity:

1. Fetch `history --since` for the past 2-4 weeks
2. Count completions per day (exclude weekends if pattern shows low weekend activity)
3. Use the median as daily capacity (typical: 5-8 tasks/day)
4. If no history available, default to 6 tasks/day

### Weekly Distribution

Distribute tasks across the week with this pattern:

| Day | Load | Rationale |
|-----|------|-----------|
| Monday | Heavy (120%) | Fresh start, high energy |
| Tuesday | Heavy (120%) | Peak productivity |
| Wednesday | Heavy (110%) | Midweek push |
| Thursday | Moderate (100%) | Winding down |
| Friday | Light (70%) | Wrap-up, planning ahead |
| Weekend | Minimal | Only if user works weekends |

Percentages are relative to daily capacity. Adjust based on observed user patterns.

### Scheduling Rules

1. **Respect existing deadlines** — never schedule a task after its due date
2. **Buffer before deadlines** — schedule 1-2 days before hard deadlines for review time
3. **Project round-robin** — avoid scheduling all tasks from one project on the same day; mix projects for variety and context-switching balance
4. **Batch similar work** — group tasks with the same label or project when possible, but don't overload a single day with one type
5. **Front-load high priority** — P1/P2 tasks go to earlier days in the schedule
6. **Preserve user assignments** — don't reschedule tasks the user has already dated unless asked

### Due String Examples

Use natural language strings the API understands:

- `"today"`, `"tomorrow"`, `"next Monday"`
- `"Jan 15"`, `"Feb 3 at 2pm"`
- `"every Monday"`, `"every weekday"`
- `"in 3 days"`, `"next week"`
- `"no date"` — removes due date

### Scheduling Process

1. Fetch active tasks without due dates, or all tasks if rescheduling
2. Fetch completion history for capacity estimation
3. Group tasks by priority and project
4. Distribute across days using the rules above
5. Propose schedule in a table: Task | Project | Priority | Proposed Date | Reasoning
6. Wait for user confirmation
7. Apply via `tasks batch-update` with `due_string` values

---

## Time Estimation Framework

### Label Discovery

**Do not assume a hardcoded label set.** The user's time labels may differ from any default (e.g., `1min` vs `@1min`, or they may not use `30min`/`2hr` at all).

1. Fetch all tasks and identify which labels are used as time estimates (look for patterns like durations: `1min`, `5min`, `@15min`, `1hr`, etc.)
2. Build a frequency table of existing time labels and examples of tasks using each
3. Use this as the canonical label set for proposals

If no time labels exist yet, suggest this default set and confirm with the user before proceeding:

| Label | Duration | Use For |
|-------|----------|---------|
| `1min` | ~1 minute | Quick replies, single-click actions, trivial fixes |
| `5min` | ~5 minutes | Short emails, simple updates, quick lookups |
| `15min` | ~15 minutes | Code reviews, short meetings prep, brief research |
| `1hr` | ~1 hour | Deep work sessions, significant coding, detailed reviews |
| `4hr` | ~4 hours | Major deliverables, architectural work, full implementations |

### Pattern Analysis

Before applying generic heuristics, study how the user already labels tasks:

1. Group already-labeled tasks by their time label
2. Identify patterns: what kinds of tasks does the user put in each bucket?
3. Use these patterns as the primary guide — the user's own calibration is more accurate than keyword heuristics

For example, if the user labels "clean toilets" as `15min` and "file taxes" as `4hr`, use those as anchors for similar tasks.

### Complexity Heuristics

Use these as a fallback when the user's existing patterns don't clearly cover a task:

**Quick tasks (1min - 5min):**
- "Reply", "respond", "check", "confirm", "approve", "merge", "update status"
- "Buy", "order", "send", "forward", "bookmark", "save"
- Single-action verbs with clear objects

**Medium tasks (15min):**
- "Write", "draft", "review", "plan", "research", "design", "prepare"
- "Fix bug", "update docs", "refactor", "test", "debug"
- Multi-step actions with moderate scope

**Large tasks (1hr - 4hr):**
- "Implement", "build", "create", "develop", "architect", "migrate"
- "Analyze", "investigate", "comprehensive", "full", "complete overhaul"
- Tasks with subtasks or complex descriptions
- Anything involving learning something new

### Category Defaults

When keyword signals and user patterns are both ambiguous, use project type as a heuristic. Map to the closest label in the user's actual label set:

| Project Type | Typical Range |
|-------------|-----------------|
| Admin / Errands | 5min - 15min |
| Communication | 5min - 15min |
| Coding / Dev | 1hr - 4hr |
| Writing / Content | 1hr |
| Planning / Strategy | 15min - 1hr |
| Learning / Research | 1hr - 4hr |

### Estimation Process

1. Fetch active tasks (`tasks list`)
2. **Discover the user's existing time labels** from already-labeled tasks — do not assume a default set
3. **Analyze existing patterns**: build a profile of how the user maps task types to durations
4. Identify tasks without time labels
5. For each unlabeled task, estimate duration using the user's existing patterns first, then complexity heuristics as a fallback
6. Propose **only the additions** in a table: Task | Project | Proposed Estimate | Reasoning — do not include already-labeled tasks
7. Wait for user confirmation — the user may refine principles rather than individual items
8. Apply via `tasks batch-update` with label additions (preserve existing labels)
