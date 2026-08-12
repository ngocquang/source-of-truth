# Changelog guide — source-of-truth audit log

Read this file when adding a changelog entry to `docs/changelog/`. The changelog is the audit trail that answers the critical question: **"was this removed on purpose, or did AI forget?"** It is for AI and developers reading the catalog later — NOT for end users.

The changelog is a **folder of per-entry files**, not a single file. One file per (date, feature): `docs/changelog/YYYY-MM-DD-<slug>.md`. Parallel sessions each create their own file, so the changelog never merge-conflicts — the reason a single `CHANGELOG.md` was retired (see Legacy migration below).

For user-facing release notes (marketing changelog, app store update text), use a separate tool — that is a different artifact with a different audience.

## What goes in the changelog

Four kinds of catalog-level events: a feature was **removed/deprecated**, **renamed** (slug changed), its **contract changed** (an `Invariants` bullet or `Validation` criterion was modified), or the **constitution changed**. Internal refactors, contract-preserving bug fixes, and new features do NOT get entries — new features are already trailed by the `overview.md` index and their own spec.

The changelog records **what changed**, in one line, for audit. **Why** a cross-cutting choice was made lives in `docs/decisions/`; **how** a hard bug was found lives in `docs/debugging/`. A constitution change produces a changelog entry and a decision record, linked to each other — the audit line stays scannable, the reasoning stays complete.

## File layout — one file per (date, feature)

```
docs/changelog/
├─ 2026-08-05-legacy-session-auth.md
├─ 2026-08-07-email-search.md
└─ 2026-08-07-constitution.md
```

Naming rules:

- **Filename**: `YYYY-MM-DD-<slug>.md`. The date is the day the entry is written; the slug is the feature's capability slug.
- **Constitution changes** use the fixed slug `constitution` (they have no feature slug).
- **Renames** use the **new** slug in the filename; the old slug appears in the entry body, so grepping either slug finds it.
- **One file covers all of that feature's events for that day.** If a change is both a rename and a contract change, both `###` sections go in the same file.
- **If the file already exists** (same feature, same day — e.g. an earlier session already shipped part of it), append your `###` sections to it instead of creating a second file.
- **Never create per-day folders or nested structure** — the folder stays flat so `ls docs/changelog/` sorts chronologically and one grep covers everything.

Finding entries:

- By feature: `ls docs/changelog/*-<slug>.md` (filename) or `grep -rl "<slug>" docs/changelog/` (body — catches renames referenced by old slug).
- Chronological: `ls docs/changelog/ | sort -r` — newest first, no index file needed.

## Decision tree — does my change need a changelog entry?

```
Did the change ...

├─ Delete a feature's entry point (route, CLI, public export)?
│   → ### Removed
│
├─ Rename a feature (slug change in roadmap / spec filename)?
│   → ### Renamed
│
├─ Modify a documented Invariant or Validation criterion?
│   ├─ The new behavior is what callers should rely on going forward?
│   │   → ### Contract changed
│   └─ Just clarified wording without changing behavior?
│       → No changelog entry. Bump the spec's `Last verified` date.
│
├─ Change a constitution section (added DB, swapped framework, raised
│  coverage threshold, changed accessibility target, etc.)?
│   → ### Constitution change
│
├─ Add a new feature?
│   → No changelog entry. The `overview.md` index + the feature's spec are the trail.
│
├─ Refactor internals without affecting Invariants / Validation?
│   → No changelog entry. Update spec `Source files` only.
│
├─ Explain WHY a cross-cutting choice was made
│  (architecture, tooling, a constitution edit's reasoning)?
│   → Not a changelog entry. Write docs/decisions/YYYY-MM-DD-<slug>.md.
│     A constitution change gets BOTH: the ### Constitution change audit
│     line here, and the decision record it links to.
│
├─ Record how a hard bug was tracked down
│  (root cause was not where the symptom pointed, recurrence, multi-session hunt)?
│   → Not a changelog entry. Write docs/debugging/YYYY-MM-DD-<slug>.md,
│     plus the guard (invariant + Validation criterion) in the spec.
│
└─ Fix a bug where code was violating an Invariant
   (i.e., code now matches the spec)?
    → No changelog entry. The spec was already correct; code caught up.
```

## Format per category

Each entry file contains one or more `###` category sections. No date heading inside the file — the date lives in the filename.

### `### Removed`

```markdown
### Removed
- **<feature-slug>** — Reason: <why removed>. Replaced by: <successor-slug, or "nothing">.
```

Required fields:

- **Reason** — one sentence answering "why is this gone?" Future sessions read this to understand the decision.
- **Replaced by** — the successor slug, or the literal word "nothing". Never blank.

Example:

```markdown
### Removed
- **legacy-session-auth** — Reason: replaced by JWT after SOC2 audit (server-side sessions failed compliance). Replaced by: jwt-authentication.
- **xml-export** — Reason: no client used for 6 months (verified via access logs). Replaced by: nothing.
```

### `### Renamed`

```markdown
### Renamed
- **<old-slug>** → **<new-slug>**. Reason: <why renamed>.
```

Required field:

- **Reason** — why the new slug is more accurate. Renames cost callers (broken links, search misses), so the reason must be substantive.

Example:

```markdown
### Renamed
- **user-search** → **email-search**. Reason: clearer scope — we only search by email, never by name or other attributes.
```

After a rename, the spec file SHALL be renamed in the same diff (`spec-<old>.md` → `spec-<new>.md`), and the roadmap entry SHALL be updated. The changelog is the trail; spec + roadmap are the current state.

### `### Contract changed`

```markdown
### Contract changed
- **<feature-slug>** — Old: <previous behavior>. New: <new behavior>. Migration: <what callers must do>.
```

Required fields:

- **Old** — exact previous behavior, copy-pasted from the prior `Invariants` / `Validation` text if possible.
- **New** — exact new behavior.
- **Migration** — what callers MUST do to adapt. If no migration is needed (caller code Just Works with the new behavior), write `Migration: none — change is backwards-compatible`. Never omit the field.

Example:

```markdown
### Contract changed
- **email-search** — Old: returned 200 with empty array on no match. New: returns 404. Migration: clients SHALL handle 404 as "no results"; previously they checked `result.length === 0`.
```

The Migration line is the most-read part of the changelog. Be specific. "Update your client" is not a migration — say what to update.

### `### Constitution change`

```markdown
### Constitution change
- **<section>** — <what changed>. Reason: <why>.
```

Section is one of `Tech Stack`, `Code Quality`, `Testing Standards`, `UX Consistency`, `Performance Requirements`.

Example:

```markdown
### Constitution change
- **Tech Stack** — Added Redis 7 for refresh token storage. Reason: SOC2 requires revocable sessions; previous in-memory approach didn't survive redeploy.
- **Testing Standards** — Raised coverage threshold from 70% → 80% on `src/auth/`. Reason: post-mortem on incident #142 (token expiry edge case shipped without test). Linked: docs/postmortems/2026-04-10-incident-142.md
```

Tech stack changes that are temporary experiments do NOT belong here — wait until the dependency is committed to staying. The changelog records decisions, not experiments.

## Entry file rules

A complete entry file, e.g. `docs/changelog/2026-05-09-invoice-generation.md`:

```markdown
### Removed
- **invoice-generation** — Reason: ... Replaced by: ...

### Contract changed
- **invoice-generation** — Old: ... New: ... Migration: ...
```

Rules:

- No `# Changelog` title and no `## YYYY-MM-DD` heading inside the file — the filename carries both identity and date.
- When a file has multiple `###` sections, keep them in a stable order: **Removed → Renamed → Contract changed → Constitution change**.
- Never edit an entry file after its day has passed. If you discover a missed entry, create a new file under today's date with a parenthetical note `(retroactive — change actually shipped <date>)`.

## Cross-link rules

When the entry references something external, link it inline. Common cross-links:

| When to link | Format |
|---|---|
| Removal/contract change driven by a post-mortem | `Linked: docs/postmortems/<file>.md` (relative path) |
| Removal triggered by a customer/issue | `Linked: <issue or ticket URL>` |
| Constitution change tied to an audit/compliance event | `Linked: <audit-report-or-ADR>` |
| Renamed feature whose old slug is still referenced externally | `Old links: <list of external places that need updating>` |

Cross-links are optional but strongly recommended for `### Constitution change` and `### Contract changed` entries — these are the high-cost decisions future sessions will second-guess.

## Audit checklist (run before merge)

When a PR touches the catalog, verify:

1. **Every removed/renamed/contract-changed feature has an entry file** under today's date (`docs/changelog/<today>-<slug>.md`).
2. **Every changelog entry has matching state** — Removed entries have `Status: removed` in the spec; Renamed entries have the file renamed and roadmap updated; Contract changed entries have the new `Invariants` / `Validation` content visible in the spec.
3. **Every `Migration:` line is specific** (no "update your client", no blanks).
4. **No invented entries** — if the diff doesn't show a removal/rename/contract change, don't write one.
5. **No silent constitution drift** — if `package.json` / `Cargo.toml` shows a dependency change but no `### Constitution change` entry exists, either add one or document why it doesn't qualify (e.g., experimental, soon to be reverted).
6. **One file per (date, feature)** — if `docs/changelog/<today>-<slug>.md` already exists, append to it; don't create a variant filename.
7. **Filename convention holds**: `YYYY-MM-DD-<slug>.md`, flat in `docs/changelog/`, section order Removed → Renamed → Contract changed → Constitution change.

Specs whose `Source files` paths no longer exist often signal a removal that needs a changelog entry — when reconciling, confirm each affected spec's `Source files` still resolve (see [`sync-guide.md`](sync-guide.md) → Stale spec exception).

## Legacy migration (project still has `docs/CHANGELOG.md`)

Earlier versions of this skill kept a single `docs/CHANGELOG.md` (optionally with monthly archives at `docs/changelog/YYYY-MM.md`). When you encounter one:

1. **Surface it once** — don't migrate silently:

   > This project still uses the single-file `docs/CHANGELOG.md`, which merge-conflicts across parallel sessions. Move it to `docs/changelog/archive-legacy.md` (frozen) and write new entries as per-file fragments?

2. After the user confirms: `git mv docs/CHANGELOG.md docs/changelog/archive-legacy.md`. Do **not** rewrite its content — it is frozen history. Existing monthly archives (`docs/changelog/YYYY-MM.md`) stay where they are, also frozen.
3. Update the project's `overview.md` link and the `## Spec Catalog` section of its `CLAUDE.md` to point at `docs/changelog/` instead of `docs/CHANGELOG.md`.
4. All **new** entries go to `docs/changelog/YYYY-MM-DD-<slug>.md` — never append to the legacy files again.

When searching history, one `grep -r "<slug>" docs/changelog/` covers fragments AND frozen legacy files. If the user declines the migration, keep appending to `docs/CHANGELOG.md` per its old one-date-heading-per-day rule — their call.

## Anti-patterns

| Anti-pattern | Why it's bad | Fix |
|---|---|---|
| `Reason: cleanup` | Future sessions can't tell if removal was deliberate or a mistake | Be specific: "no client used for 6 months", "replaced by X after audit" |
| `Migration: update your client` | Doesn't tell the caller what to update | Say the exact behavior change: "handle 404 as empty result instead of checking length" |
| Logging refactors as "Contract changed" | Refactors that preserve `Invariants` and `Validation` are not contract changes | If the spec text didn't change, don't log it. Bump `Last verified` only. |
| Writing entries for features that never shipped | `Later` / `Next` drops don't need a changelog entry (they never had a contract) | Just delete the roadmap row. The changelog only logs features that actually shipped (had a contract). |
| Long prose in entries | The changelog is for scanning, not reading | Keep each bullet to 1-3 lines. Long context goes in a linked post-mortem/ADR. |
| Two files for the same (date, feature) | Splits one feature's daily trail across files | Append to the existing `YYYY-MM-DD-<slug>.md` instead. |
| Date folders or nesting under `docs/changelog/` | Breaks flat-folder sort/grep; empty-folder churn | Flat files only, date prefix in the filename. |
| Editing past entry files to "improve" wording | Past entries are immutable history | Add a new file today with the correction; don't rewrite history. |
| Changelog entries for renames in private code | Internal-only renames (no external callers) don't need changelog bloat | Only log renames of features with external surface (public API, CLI, UI route). |
| Logging every dependency bump | Patch/minor bumps of an existing tech stack entry are not constitution changes | Only log Tech Stack changes that add/remove a tool, swap a framework, or cross a major version. |
