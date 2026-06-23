---
name: source-of-truth
description: "Use when a project keeps (or should keep) a docs/ spec catalog and the task touches it: before writing, modifying, or deleting production code (refactors and bug fixes included) or checking whether a capability already exists; after a feature ships or the user signals completion ('ship it', 'done', 'commit', 'merge', 'xong rồi') or an executing-plans/subagent-driven-development run finishes; when the user wants to change the project's roadmap, mission, or constitution, or to update/sync/bootstrap the spec docs; or when code exists but docs/overview.md doesn't."
---

# Spec Catalog (Spec-Driven Development)

A self-maintaining catalog implementing SDD: principles gate plans, mission gates roadmap, roadmap gates specs, specs gate code. Written for AI to read before coding. Prevents four failure modes: (1) rebuilding a feature that already exists, (2) silently deleting features during refactor, (3) breaking invariants by changing behavior without knowing the contract, (4) building features that violate project principles or aren't on the roadmap.

The **catalog** is the source of truth for "what exists, why, and what rules apply". The **code** is the source of truth for "how it works".

## Non-negotiable rules

This skill is **RIGID, not advisory**. Two rules have no exceptions:

1. **Follow this process exactly.** Do not skip a mode, shortcut the Catalog check, or "use judgment" to bypass a gate. READ before *any* write/modify/delete; SYNC after *any* ship. "It's a small change" is not a reason to skip — small changes break invariants most often.
2. **Iron-rule — every unit of work goes on the roadmap.** EVERY change — new feature, enhancement, refactor, **and bug fix** — gets a `roadmap.md` entry before code is written. The rule's job is to stop *your own* rationalizing — "too small to track", "just a typo", "I'll add it after" are not reasons to skip; untracked small changes are exactly how the roadmap drifts from reality and the gate quietly dies. So the default is firm: if it's not on the roadmap, surface that, add it (`Now`/`Next`) first, then code.
   What this rule is **not** is a way to overrule the user — they own the project; the skill serves them. Always surface the gate first. **Urgency is not an override:** "be quick", "don't overthink it", "we demo in 5 minutes" mean *work fast*, not *skip the gate* — the entry costs seconds, so add it and then move fast. A real override is the user, aware of the rule, explicitly telling you to proceed without the entry (e.g. a live production hotfix); then do it, say you're proceeding on their explicit call, and recommend a retroactive roadmap + CHANGELOG entry afterward. The violation is *you* skipping the gate — silently, because it felt small, or because the user was merely in a hurry.

## Layout

```
docs/
├─ overview.md          (index — links project docs + every feature spec)
├─ constitution.md      (principles: tech stack, code quality, testing, UX, performance)
├─ mission.md           (why: problem, users, value, success metrics)
├─ roadmap.md           (forward plan: Now / Next / Later — shipped work leaves the roadmap)
├─ CHANGELOG.md         (deletions, renames, contract changes, constitution changes)
├─ changelog/           (optional — monthly archives when CHANGELOG.md gets large)
│   └─ YYYY-MM.md
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
5. If the request mentions something not in the catalog, check `docs/CHANGELOG.md` — it might have been removed deliberately.
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
   ```

7. Handle these cases before proceeding:

   | Situation | Response |
   |---|---|
   | Feature already exists | STOP. "Feature X already exists at `<path>`. Modify it instead, or is there a real difference?" |
   | Change would break a documented invariant | "This breaks invariant `<X>` on feature `<Y>`. Confirm (it'll go in CHANGELOG) or rethink." |
   | Change violates a constitution principle | "This conflicts with constitution: `<principle>`. Update the constitution first (with reason + CHANGELOG entry) or change the approach." |
   | Work is not on the roadmap (any change — including a bug fix) | STOP and surface it: "This isn't on the roadmap yet — adding it to `roadmap.md` (`Now` or `Next`), then I'll code." Add it by default (urgency ≠ skip — the entry costs seconds). Don't skip on your own "too small" judgment. Only if the user, knowing the rule, explicitly says to proceed without it (e.g. a hotfix) do so — and recommend a retroactive entry. |
   | Spec's `Source files` reference paths that no longer exist | "Spec `<X>` references `<path>` which no longer exists — sync this spec first?" Don't silently fix. |

8. Only after user confirms, write code.

Do NOT update catalog files in READ mode (except the stale-spec exception above, with user confirmation) — proactive updates belong to SYNC.

## SYNC mode

**Commit gate:** when a commit is imminent — the user asks to commit, or you're about to — SYNC runs and **completes before the commit** (sync the catalog, then commit code + catalog together). This is automatic, not a question. Self-gating: only when `docs/overview.md` exists. Skip only for a pure no-spec-impact refactor, or an explicit user override (then recommend a retroactive sync).

Quick helpers (saves repeated git/date calls):

```bash
bash scripts/sync_helpers.sh diff   # files changed + commit hash + today
bash scripts/sync_helpers.sh stamp  # ready-to-paste "Last verified" line
bash scripts/sync_helpers.sh stale  # find specs referencing missing files
```

Full procedure (categorization, plan-aware extraction, multi-feature batching, roadmap moves, CHANGELOG handling, tech stack updates) → [`references/sync-guide.md`](references/sync-guide.md).

## BOOTSTRAP mode

Runs once. Three phases:

- **A — Auto-detect** (no user input): scan repo for tech stack, test framework, design system, README intro
- **B — Interview user** (single batch): ask only the things we can't detect (Code Quality rules, Performance budgets, Mission users/value/metrics)
- **C — Confirm and write**: show populated docs, get OK, then write all 5 project docs (overview, constitution, mission, roadmap, CHANGELOG) + per-feature specs, and update CLAUDE.md

`constitution.md` and `mission.md` MUST have real content before bootstrap completes — `_TBD: <question>_` markers are acceptable for sections the user defers, but blank fields and fabricated content are not. Updating CLAUDE.md is the highest-leverage step — don't skip it.

Full procedure → [`references/bootstrap-guide.md`](references/bootstrap-guide.md).

## Red flags

- **Reading the entire codebase.** READ reads catalog files; SYNC reads diff + relevant files; BOOTSTRAP caps at 15 files (or 15 per package in monorepos).
- **Inventing invariants, principles, or mission content.** If you didn't see it in code/tests, or get it from the user, don't claim it. Vague entries are worse than none — tests are the best source of invariants and validation criteria; the user is the only source of mission/code-quality principles.
- **Auto-filling constitution or mission from imagination.** Phase B requires real user input — `_TBD:` markers are acceptable, fabricated content is not (it propagates to every future session).
- **Updating overview.md for every change.** It's an index — only touch when features are added/removed/renamed.
- **Auto-updating constitution silently.** Tech stack changes need user confirmation; principle changes need explicit user request. Silent drift defeats the gate.
- **Skipping user confirmation in SYNC.** Always show the diff first; batch multi-feature updates into one diff.
- **Skipping READ for bug fixes or silently fixing stale specs.** Both are the exact failure modes this skill exists to prevent.
- **Forgetting to remove a shipped feature from `Now`.** The roadmap holds only unshipped work and should shrink as you ship; leaving shipped entries in `Now` makes it drift from reality.
- **Quietly building something not on the roadmap (iron-rule).** Every change — features, refactors, and bug fixes alike — gets a `roadmap.md` entry (`Now`/`Next`) before coding. The red flag is skipping on *your own* "too small" judgment, or skipping without surfacing it at all. Surfacing the gate and then honoring an explicit user override (with a recommended retroactive entry) is fine — silently shipping off-roadmap is the violation.
