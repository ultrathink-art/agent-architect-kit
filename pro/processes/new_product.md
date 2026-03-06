# New Product Process
#
# WHY THIS EXISTS: Product creation involves 4+ agents in sequence.
# Without a defined process, handoffs break, designs get orphaned,
# and products sit invisible. This process ensures the full pipeline
# from concept to visible product on site.

## Design-First Principle (READ FIRST)
# WHY: Great designs live across the product line, not siloed to one format.
# A winning design as a tee should also be a hoodie, mug, sticker, and poster.

Before starting any product:
1. Think about the *design concept* first, not the product type
2. Identify 3+ product formats where the design could work
3. Create the primary product, then plan expansions

## Phases

### 1. Discovery (Product + Marketing)
**Owner:** Product
**Collaborator:** Marketing

- Research market trends, competitor products
- Research audience sentiment, trending memes/topics
- Document findings in `agents/briefs/product-research-YYYY-MM-DD.md`
- Output: Research brief with 3-5 product concepts

### 2. Concept Selection (CEO or Product)
- Review research brief, select 1-2 concepts
- Document decision in `agents/decisions/`

### 3. Design Brief (Product → Designer)
**Owner:** Product
**Executor:** Designer

- Create design brief in `agents/briefs/design-brief-[product].md`
- Brief includes: concept, audience, style direction, references, specs
- **REQUIRED:** Identify 3+ product formats for the design
- Designer generates 3-5 variations per concept

### 4. Design Review — INTERNAL QUALITY GATE
# WHY: Without explicit rejection targets, agents rubber-stamp everything.
# "Target 60-70% rejection" is the single most effective quality mechanism.

**Owner:** Product
**Reviewer:** QA

**Target 60-70% rejection rate. More no's than yes's.**

- Product evaluates for audience fit and taste
- QA verifies technical quality
- **Quality rating MANDATORY**: Rate each design 1-5
- **ONLY ship 4-5 rated designs** — REJECT everything else
- **Slop check**: walls of text, AI artifacts, no cultural hook = REJECT
- Output: Approved design(s) with rating AND rejection documentation

**No stakeholder approval gate.** Team ships autonomously.

### 5. Production — FULL PIPELINE REQUIRED
# WHY (Feb 2026): Product sat invisible 5+ hours because creating agent
# completed step 1 (create in fulfillment provider) and declared done.
# Steps 2-4 (sync, set visible, verify) were never executed.

**HARD GATE**: Task is NOT complete until product is VISIBLE on site.

Steps:
1. ✅ Create product (automated by creation script)
2. ✅ Sync to DB + mockup images (automated)
3. ⚠️ Set `hidden: false, available: true` (MANUAL — after quality gate)
4. ⚠️ Screenshot-verify on site (MANUAL)

If you can't complete steps 3-4, chain a follow-up task via `next_tasks`.

### 6. Launch (Marketing)
- Create launch content
- Coordinate timing
- Document in launch plan

### 7. Cross-Product Expansion (MANDATORY FOR 4-5 RATED DESIGNS)
# WHY: Revenue scales with product-type coverage, not new concepts.
# One great design × 6 product types = more revenue than 6 mediocre designs.

For ANY design rated 4-5:
- IMMEDIATELY create expansion tasks for ALL fitting product types
- Track expansion coverage
- Goal: Every successful design exists across ALL fitting formats

## Artifacts Created
Each product launch should generate:
- [ ] Research brief
- [ ] Design brief (with 3+ formats identified)
- [ ] Design review (internal quality rating)
- [ ] Launch plan
- [ ] Cross-product expansion tasks
