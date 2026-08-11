---
name: source-of-truth
description: "Use when a project keeps (or should keep) a docs/ spec catalog and the task touches it: before writing, modifying, or deleting production code (refactors and bug fixes included) or checking whether a capability already exists; after a feature ships or the user signals completion; when the user wants to change the project's roadmap, mission, or constitution, or to update/sync/bootstrap the spec docs; or when code exists but docs/overview.md doesn't."
when_to_use: "User says 'ship it', 'done', 'commit', 'merge', 'sync', 'update the catalog', 'sync specs', 'sync docs', 'update roadmap', 'bootstrap docs'; an executing-plans or subagent-driven-development run reports completion; user asks 'is there already a thing that does X?'; user wants to edit roadmap.md, mission.md, or constitution.md."
---

# Spec Catalog (Spec-Driven Development)

A self-maintaining catalog implementing SDD: principles gate plans, mission gates roadmap, roadmap gates specs, specs gate code. Written for AI to read before coding. Prevents four failure modes: (1) rebuilding a feature that already exists, (2) silently deleting features during refactor, (3) breaking invariants by changing behavior without knowing the contract, (4) building features that violate project principles or aren't on the roadmap.

The **catalog** is the source of truth for "what exists, why, and what rules apply". The **code** is the source of truth for "how it works".

## Non-negotiable rules

This skill is **RIGID, not advisory**. Two rules have no exceptions:

1. **Follow this process exactly.** Do not skip a mode, shortcut the Catalog check, or "use judgment" to bypass a gate. READ before *any* write/modify/delete; SYNC after *any* ship. "It's a small change" is not a reason to skip — small changes break invariants most often.
2. **Iron-rule — every unit of work goes on the roadmap.** EVERY change — new feature, enhancement, refactor, **and bug fix** — gets a `roadmap.md` entry before code is written. "Too small to track", "just a typo", "I'll add it after" are not reasons to skip — untracked small changes are exactly how the roadmap drifts from reality and the gate quietly dies. Default: surface it, add it (`Now`/`Next`), then code.
   The rule never overrules the user — they own the project. **Urgency is not an override:** "be quick", "don't overthink it", "we demo in 5 minutes" mean *work fast*, not *skip the gate* — the entry costs seconds. A real override is the user, aware of the rule, explicitly choosing to proceed without the entry (e.g. a live production hotfix): do it, say so, and recommend a retroactive roadmap + changelog entry. The violation is *you* skipping the gate silently, because it felt small or rushed.

## Layout

```
docs/
├─ overview.md          (index — links project docs + every feature spec)
├─ constitution.md      (principles: tech stack, code quality, testing, UX, performance)
├─ mission.md           (why: problem, users, value, success metrics)
├─ roadmap.md           (forward plan: Now / Next / Later — shipped work leaves the roadmap)
├─ changelog/           (deletions, renames, contract changes, constitution changes —
│   └─ YYYY-MM-DD-<slug>.md   one flat file per entry so parallel sessions never conflict)
└─ specs/
    └─ spec-<feature>.md  (per feature: Plan + Requirement + Validation; kebab-case)
```

Exact schemas → [`references/catalog-format.md`](references/catalog-format.md).

## Pick a mode

| Condition | Mode |
|---|---|
| `docs/overview.md` does NOT exist + project has code | **BOOTSTRAP** → [`references/bootstrap-guide.md`](references/bootstrap-guide.md) |
| `docs/overview.md` exists but `constitution.md` or `mission.md` is missing/empty | **RE-BOOTSTRAP** the missing file before any code change → [`references/bootstrap-guide.md`](references/bootstrap-guide.md) (Re-bootstrap section) |
| User wants to write/modify/delete code (incl. bug fixes, refactors, "is there already a thing that does X?") | **READ** (below) |
| Feature shipped: "ship it", "done", "commit", "merge", "xong rồi"; or `executing-plans`/`subagent-driven-development` reports completion; or "update the catalog / sync specs" | **SYNC** → [`references/sync-guide.md`](references/sync-guide.md) |

Ambiguous? Ask once: "Sync the catalog now, or keep going?"

## READ mode

Do NOT skip for "simple" changes — bug fixes break invariants more often than features do.

1. Read `docs/overview.md`. Identify related features.
2. Read `docs/constitution.md` (skim Tech Stack always; skim other sections relevant to the change — e.g., Performance if touching a hot path, Testing if changing tests, UX if touching the UI).
3. Read `docs/roadmap.md`. Confirm the requested feature is in `Now` / `Next` / `Later`, or already shipped (a spec exists for it), or surface that it's not tracked yet.
4. Read each related `docs/specs/spec-<feature>.md` (Plan + Requirement + Validation).
5. If the request mentions something not in the catalog, search `docs/changelog/` — it might have been removed deliberately. `ls docs/changelog/*-<slug>.md` finds entries by filename; `grep -rl "<slug>" docs/changelog/` catches renames and legacy files by content.
6. **Before writing any code**, output this catalog check to the user (not internal thinking — user must be able to override):

   ```
   Catalog check:
   - Constitution: <relevant principle, or "no conflict">
   - Roadmap status: <Now | Next | Later | shipped (off-roadmap) | NOT TRACKED>
   - Related existing features: <list, or "none found">
   - Invariants I must preserve: <list, or "none">
   - Acceptance criteria that must still pass: <list, or "none">
   - Already exists? <yes + which feature, or no>
   - Plan: <what I'm about to do and why it doesn't conflict>
   - Implementation route: <plan doc path, or "no plan"> · <worktree/branch I'll work in> · <superpowers skills I'll drive it with, or "not available">
   ```

7. Handle these cases before proceeding:

   | Situation | Response |
   |---|---|
   | Feature already exists | STOP. "Feature X already exists at `<path>`. Modify it instead, or is there a real difference?" |
   | Change would break a documented invariant | "This breaks invariant `<X>` on feature `<Y>`. Confirm (it'll go in the changelog) or rethink." |
   | Change violates a constitution principle | "This conflicts with constitution: `<principle>`. Update the constitution first (with reason + changelog entry) or change the approach." |
   | Work is not on the roadmap (any change — including a bug fix) | STOP — iron-rule (non-negotiable rule 2): surface it, add it to `roadmap.md` (`Now`/`Next`), then code. |
   | Spec's `Source files` reference paths that no longer exist | "Spec `<X>` references `<path>` which no longer exists — sync this spec first?" Don't silently fix. |

8. Only after user confirms, write code — via the implementation handoff below, never freehand in the main checkout.

Do NOT update catalog files in READ mode (except the stale-spec exception above, with user confirmation) — proactive updates belong to SYNC.

## Implementation handoff

The gate ends where implementation begins, and roadmap work takes one route — the same for a feature, an enhancement, a refactor, or a bug fix.

1. **Work in an isolated worktree.** If the project is a git repo and you are not already in a dedicated worktree for this roadmap item, create one before the first edit (`superpowers:using-git-worktrees` when available, otherwise `git worktree add`). Report the path in the catalog check's `Implementation route` line. Not a git repo, or the user asks for an in-place edit: say which one applies and continue. "It's one small edit" is not one of those cases — the main checkout is where half-finished roadmap items get committed by accident.
2. **Drive it with the superpowers skills when the runtime has them** (any `superpowers:*` skill in the skill list): `brainstorming` → `writing-plans` for work that isn't planned yet, `test-driven-development` while implementing, `executing-plans` or `subagent-driven-development` to run a written plan, `finishing-a-development-branch` to integrate. When they aren't available, implement directly and name that in the `Implementation route` line so the user knows which process is running.
3. **Follow the plan document when one exists.** Look where SYNC looks for plans (the spec's `Source plan` field, then `docs/superpowers/`, `plans/`, `specs/` → [`references/sync-guide.md`](references/sync-guide.md) step 3). The plan's task order and checkpoints are the route; the spec's `Validation` criteria are what the tests assert (intent → tests). Don't re-plan planned work, and surface any deviation from the plan instead of drifting silently.
4. **Sync the catalog inside the worktree, before the merge** — SYNC's commit gate applies to the branch where the code lives → [`references/sync-guide.md`](references/sync-guide.md).

## SYNC mode

**Commit gate:** when a commit is imminent — the user asks to commit, or you're about to — SYNC runs and **completes before the commit** (sync the catalog, then commit code + catalog together). This is automatic, not a question. Self-gating: only when `docs/overview.md` exists. Skip only for a pure no-spec-impact refactor, or an explicit user override (then recommend a retroactive sync).

Full procedure (categorization, plan-aware extraction, multi-feature batching, roadmap moves, changelog handling, tech stack updates) → [`references/sync-guide.md`](references/sync-guide.md).

## BOOTSTRAP mode

Runs once, in three phases: **A** auto-detect from the repo (tech stack, test framework, design system, README intro), **B** interview the user in a single batch for what can't be detected, **C** confirm, then write the 4 project docs + the changelog bootstrap entry + per-feature specs and update CLAUDE.md (the highest-leverage step — don't skip it).

`constitution.md` and `mission.md` MUST have real content before bootstrap completes — `_TBD: <question>_` markers are acceptable for sections the user defers, but blank fields and fabricated content are not.

Full procedure → [`references/bootstrap-guide.md`](references/bootstrap-guide.md).

## Red flags

Mode-specific pitfalls live in each guide's pitfalls section; these apply across modes:

- **Reading the entire codebase.** READ reads catalog files; SYNC reads diff + relevant files; BOOTSTRAP caps at 15 files (15 per package in monorepos).
- **Inventing content.** Invariants come from code/tests; constitution and mission come from the user. `_TBD: <question>_` is acceptable, fabrication is not.
- **Skipping READ for bug fixes, or silently fixing stale specs.** Both are exactly what this skill exists to prevent.
- **Building off-roadmap (iron-rule).** Skipping the entry on your own "too small" judgment, or without surfacing it. Surface first; an explicit user override is fine (recommend a retroactive entry).
- **Implementing freehand.** Editing the main checkout instead of a worktree, ignoring an existing plan document, or hand-rolling a process the runtime's `superpowers:*` skills already cover → Implementation handoff (above).
- **Sloppy roadmap lifecycle.** One line per entry (detail lives in the spec); shipped work leaves `Now`; a feature enters `Now` only through the spec critique gate with `Open questions` resolved to `None.` — parking ambiguity in `Notes` or "TBD" prose is the violation. Lifecycle rules + gate checklist → [`references/catalog-format.md`](references/catalog-format.md).
- **Writing a spec and using it unreviewed.** Every spec passes the spec critique gate first — when drafted at `Later → Next`, when promoted `Next → Now`, when SYNC creates or rewrites one, and when BOOTSTRAP finishes its batch: a fresh-context reviewer on the strongest model available (Claude Code: `Agent` with `model: opus`), whose findings you fold back into the spec. Running the four checks in your own head, in the same context that wrote the spec, is the failure the gate exists to prevent. Reviewer inputs, return shape, and fold-back → [`references/catalog-format.md`](references/catalog-format.md).
- **Writing Validation criteria from the tests alone when a pre-implementation spec or plan exists.** Intent → tests, never the reverse — full direction rule → [`references/catalog-format.md`](references/catalog-format.md); test-only extraction is for BOOTSTRAP and plan-less legacy features.
