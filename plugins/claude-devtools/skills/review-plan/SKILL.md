---
name: review-plan
description: "Get a second opinion from Codex on your plan. Multi-turn discussion until consensus."
version: 1.0.0
triggers:
  - review plan
  - second opinion
  - plan incele
  - ikinci görüş
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
  - Write
  - AskUserQuestion
---

# /review-plan — Codex Second Opinion

Get a structured review of your plan from ChatGPT Codex CLI (gpt-5.3-codex, xhigh reasoning).
Multi-turn discussion (max 3 rounds) until consensus or agree-to-disagree.

## Workflow

### Step 1: Gather Context

Identify the plan to review. Sources (in priority order):
1. User provides plan text directly
2. Active plan mode file
3. Recent conversation context

Identify the project directory for Codex to read files from.

### Step 2: Build Review Prompt

Write a structured prompt to `/tmp/codex-review/prompt.md`:

```markdown
You are a senior architect reviewing a plan proposed by another AI (Claude Code, Opus 4.6).
Your job: find blind spots, suggest better approaches, catch oversights.

## Your Review Framework
For each section of the plan:
- AGREE: if approach is sound (brief reason)
- MODIFY: if you'd change something (what + why + your alternative)
- ADD: if something is missing (what + why it matters)
- REMOVE: if something is unnecessary (what + why)

## Project Context
- Project: {project_name}
- Tech Stack: {tech_stack}
- Current State: {current_state_summary}

## Key Files (read these for context)
{file_paths_with_descriptions}

## Objective
{what_we_are_trying_to_achieve}

## Proposed Plan
{plan_content}

## Review Instructions
1. Read the referenced files in this project to understand current architecture
2. Evaluate each plan section against the actual codebase
3. Be specific — reference file paths, function names, line numbers
4. End with: overall assessment + priority-ordered list of recommended changes
5. If the plan is solid, say so clearly and suggest only minor improvements
```

### Step 3: Round 1 — Codex Reviews

Run: `bash ~/.claude/hooks/codex-review.sh round1 "$PROJECT_DIR"`

Read the output from `/tmp/codex-review/round1.txt`.

Analyze Codex's feedback using these rules:
- For each MODIFY/ADD point: evaluate the trade-off between Codex's suggestion and current plan
- **No automatic acceptance** — "Codex said so" is not sufficient. Explain WHY a point is valid.
- **No automatic rejection** — "I already considered that" is not sufficient. Genuinely engage with the point.

Present Round 1 Summary to user:
```
## Round 1 Summary
### Agreed
- [points both AIs agree on]
### Under Discussion
- [points still being debated]
### Claude's Position
- [Claude's stance on debated points]
### Codex's Position
- [Codex's stance on debated points]
```

### Step 4: Round 2 — Claude Counter-Response

Write Claude's counter-response to `/tmp/codex-review/counter-2.md`:

```markdown
Claude (plan author) responds to your review:

{claude_response_to_each_point}

Please:
1. Accept points where Claude's reasoning is sound
2. Push back with evidence where you still disagree
3. Propose compromise where neither approach is clearly better
4. List final consensus points and remaining disagreements
```

Run: `bash ~/.claude/hooks/codex-review.sh round2 "$PROJECT_DIR"`

Read `/tmp/codex-review/round2.txt` and analyze.

Present Round 2 Summary.

### Step 5: Round 3 (if needed)

Only if significant disagreements remain after Round 2.

Write to `/tmp/codex-review/counter-3.md`, run `codex-review.sh round3`.

### Step 6: Present Final Results

```
## Plan Review Complete

### Consensus (both agree)
- ...

### Incorporated Changes (from Codex feedback)
- ...

### Remaining Disagreements (user decides)
- Claude says: ...
- Codex says: ...

### Updated Plan
[Plan with incorporated changes applied]
```

### Step 7: Cleanup

Ask user if they want to proceed with the updated plan. If yes, clean up:
`bash ~/.claude/hooks/codex-review.sh clean`

## Rules

- **Max 3 rounds.** After round 3, stop and present results regardless.
- **Codex runs read-only** — it cannot modify any files.
- **Every round's output is preserved** at `/tmp/codex-review/roundN.txt`.
- **User has final say** on all disagreements.
- **Early consensus is fine** — if round 1 has no major disagreements, skip further rounds.
