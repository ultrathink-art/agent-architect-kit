# Agent Memory Protocol
#
# WHY THIS EXISTS: Without persistent memory, AI agents repeat the same mistakes
# every session. Memory is what turns one-off debugging into permanent learning.
# In our production system, agents repeated identical failures (wrong background
# format, skipped tests, incorrect API calls) until memory was implemented.
#
# HOW IT WORKS: Each agent reads their memory file at session start and updates
# it at session end. Include this file in every agent definition via @ import.

You have persistent memory across sessions. USE IT.

## At Session START (before any work)

Read your memory file: `agents/state/memory/<your-role>.md`

This contains your accumulated knowledge from past sessions — mistakes you've made, things you've learned, stakeholder preferences about your work, and a log of your recent sessions. **Treat this as your personal notebook.** If it says you screwed something up before, don't do it again.

## At Session END (before TASK_COMPLETE)

Update your memory file. Add entries to the relevant sections based on what happened this session. Be specific and actionable — future-you needs to understand what happened and what to do differently.

### What to record

**Mistakes** — anything that went wrong, got rejected, or required rework:
- What you did wrong
- What the correct approach was
- How to avoid it next time

**Learnings** — non-obvious discoveries specific to your role:
- Gotchas, workarounds, tool quirks
- Things that took multiple attempts to figure out
- Patterns that work well

**Stakeholder Feedback** — direct reactions to your work:
- What they liked / what they rejected
- Quality standards, preferences
- Specific items or approaches called out

**Session Log** — brief record of what you did:
- Task ID, what you worked on, outcome
- Keep to 1-2 lines per session

### How to update

Append new entries at the TOP of each section (newest first). Each entry gets a date prefix `[YYYY-MM-DD]`.

### Size limits
# WHY: Unbounded memory files eventually exceed context windows.
# These limits keep the most valuable information while pruning stale entries.

- **Mistakes**: Keep last 20 entries. These are the most valuable — prune only the oldest.
- **Learnings**: Keep last 20 entries.
- **Stakeholder Feedback**: Keep ALL entries. Never prune — this is the voice of the customer.
- **Session Log**: Keep last 15 sessions.

If a learning or mistake is already captured in CLAUDE.md as a project-wide rule, you can remove it from memory (it's been "promoted" to a permanent rule).

## Memory File Format

```markdown
# [Role] Agent Memory

## Mistakes
- [2026-02-06] Pushed code without running tests. Tests were failing. MUST run tests after final commit, verify exit 0 before push.

## Learnings
- [2026-02-06] Published products can't be edited via update API (error 8252). Must create new product + swap ID.

## Stakeholder Feedback
- [2026-02-06] Rejected sticker designs — "poster layout, not die-cut." Stickers must be die-cut to illustration shape.

## Session Log
- [2026-02-06] WQ-716: Fixed broken template syntax. Pushed clean build.
- [2026-02-05] WQ-713: Homepage redesign — NOTE: fabricated test results, got caught. See Mistakes.
```

## Rules

1. **Always read before working.** Your memory exists to prevent repeated failures.
2. **Always write before completing.** Every session teaches something.
3. **Be honest.** If you messed up, record it. Memory is private working notes, not a performance review.
4. **Be specific.** "Don't forget tests" is useless. "Run `CI=true bin/rails test` after final commit, check exit code 0" is useful.
5. **Don't duplicate CLAUDE.md.** If a rule already exists there, reference it — don't copy it.
6. **Prune stale entries.** If a mistake led to a CLAUDE.md rule, the memory entry served its purpose — remove it.
