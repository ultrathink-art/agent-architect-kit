# Design Approval Process
#
# WHY THIS EXISTS: AI agents generated 10 stickers. 9 were slop (text on colored
# circles). 1 was good enough to sell. Without a taste filter, agents optimize
# for "technically correct" not "someone would buy this."

## Rule: Team owns quality autonomously

**The team ships. The stakeholder reacts.** No work waits on stakeholder approval. The quality bar is enforced internally by the agent chain (designer → product → QA). If something bad ships, fix fast.

### The Test (apply to EVERY product)
Ask honestly: **"Would [YOUR_TARGET_CUSTOMER] spend their own money on this?"**

Not "is it technically correct." Not "does it match the brief." Would someone see this and pull out their wallet?

If you hesitate → reject.

### What Gets Rejected
- Text on a shape with no illustration
- Designs that would work as a plain text tweet
- Jagged edges, aliasing, artifacts, transparency halos
- Generic/boring concepts even if technically well-executed
- "Fine" or "okay" designs — if it's not genuinely good, it's a no
- **AI text rendering defects** — misplaced, garbled, misspelled text
# WHY: AI generators frequently produce text that looks plausible at a glance
# but is wrong on close inspection. Every word must be verified character-by-character.

### What Gets Approved
- Character-based designs with personality
- Visual humor (the joke is in the IMAGE, not just words)
- Clean, professional execution at print resolution
- Designs that make someone smile and think "I need that"

### Rejection Target
**70-90% of concepts should be rejected.** If most designs pass, the bar is too low.
# WHY: When we tracked, 100% of designer outputs self-rated 5/5 — statistically
# impossible. Explicit rejection targets combat self-rating inflation.

## Workflow

1. **Designer** creates design, self-rates honestly (4-5 = ship, 1-3 = reject)
2. **Product** applies taste gate BEFORE upload (includes text verification)
3. **Product** runs creation pipeline (auto-syncs to DB + mockup images)
4. **Creating agent** sets product visible + screenshot-verifies
5. **QA** reviews (AUTO-CHAINED): technical + taste + text rendering on mockups

## Decision Log (MANDATORY)
# WHY: When a defective item shipped (Feb 2026), there was no decision trail —
# just logs saying "4/5, shipped." Took 15 tool calls to reconstruct what should
# have been one command.

Every product MUST have a structured decision file: `agents/state/design_decisions/<item_id>.yml`

**What it captures:** Concept, meme reference, per-agent ratings (1-5 + notes), issues, status.

## Accountability
- Products that get through and turn out to be slop → all three agents failed
- Regular catalog audits: apply this bar to existing products, not just new ones
- When stakeholder flags a bad product, the process failed — fix the process
- **Stakeholder feedback is reactive, not a gate.** Ship → feedback → iterate fast.
