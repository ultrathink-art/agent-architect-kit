# Build Feature / New Page Process
#
# WHY THIS EXISTS: "Build me X" is the most common request. Without a standard
# workflow, agents skip discovery (build wrong thing), skip briefs (build thing
# wrong), or skip QA (ship broken thing). This 5-phase process prevents all three.

## When to Use
- Stakeholder says "build me X"
- CEO identifies a feature gap
- Any request that results in new code

## Workflow

### Phase 1: Discovery (CEO, 10 min)
# WHY: Building without exploring existing code creates duplication and
# pattern violations. 10 minutes of discovery prevents hours of rework.

1. **Explore codebase** — find existing patterns, controllers, views, CSS
2. **Identify data sources** — what services, APIs, models exist
3. **Map the architecture** — how does the new thing fit into what exists

### Phase 2: Brief (CEO, 5 min)
# WHY: A brief forces you to think before you build. Briefs that seem
# tedious to write reveal ambiguity that would otherwise become bugs.

Write brief at `agents/briefs/{feature-name}.md` covering:
- **Objective** — one sentence
- **Architecture** — route, controller, view, model changes
- **Layout** — section-by-section spec with data sources
- **Service changes** — new methods needed on existing services
- **CSS** — use existing patterns or specify new ones
- **Error handling** — graceful degradation
- **Test plan** — what tests to write
- **Anti-patterns** — what NOT to do

### Phase 3: Task Chain (CEO, 2 min)

```bash
# Standard chain: coder → QA (auto-chained)
bin/agent-task add coder "Build {feature}. Full spec: agents/briefs/{feature}.md"
bin/agent-task ready WQ-{id}
```

For customer-facing pages with novel UI:
```bash
# Extended chain: designer → coder → QA
bin/agent-task add designer "Create mockup for {feature}"
bin/agent-task add coder "Build {feature}. Blocked by WQ-{designer_id}"
```

For internal pages (admin tools): skip designer — follow existing patterns.

### Phase 4: Execute (Orchestrator, autonomous)
```bash
bin/agent-orchestrator  # spawns agents for ready tasks
```

### Phase 5: Review (CEO + QA, 5 min)
1. QA auto-chained — verifies deploy, screenshots, feature works
2. CEO reviews QA result
3. If issues → new coder task with fixes, repeat

## Decision: When Does Designer Get Involved?

| Scenario | Designer Needed? |
|----------|-----------------|
| New admin dashboard tab | No — follow existing patterns |
| New customer-facing page | Yes — novel layout/branding |
| New product type on site | Yes — visual direction |
| Admin tool / internal page | No — follow admin patterns |
| Marketing landing page | Yes — conversion-focused design |

## Checklist

- [ ] Brief written with section-by-section spec
- [ ] Data sources identified
- [ ] Existing patterns referenced
- [ ] Task queued with brief link
- [ ] QA chain attached (auto for coder tasks)
- [ ] Priority set (P0 if stakeholder request)
