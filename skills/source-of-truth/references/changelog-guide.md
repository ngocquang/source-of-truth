# CHANGELOG guide — source-of-truth audit log

Read this file when adding an entry to `docs/CHANGELOG.md`. The CHANGELOG is the audit trail that answers the critical question: **"was this removed on purpose, or did AI forget?"** It is for AI and developers reading the catalog later — NOT for end users.

For user-facing release notes (marketing changelog, app store update text), use a separate tool — that is a different artifact with a different audience.

## What goes in the CHANGELOG

The CHANGELOG records four kinds of catalog-level events:

- A feature was **removed** or **deprecated**
- A feature was **renamed** (its capability slug changed)
- A feature's **contract changed** (an `Invariants` bullet or `Validation` criterion was modified)
- The **constitution changed** (Tech Stack, Code Quality, Testing, UX, or Performance principle was updated)

Internal refactors, bug fixes that preserve the contract, and additions of new features do NOT require a CHANGELOG entry. New features show up in the `overview.md` index and their own spec — that is enough audit trail.

## Decision tree — does my change need a CHANGELOG entry?

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
│       → No CHANGELOG entry. Bump the spec's `Last verified` date.
│
├─ Change a constitution section (added DB, swapped framework, raised
│  coverage threshold, changed accessibility target, etc.)?
│   → ### Constitution change
│
├─ Add a new feature?
│   → No CHANGELOG entry. The `overview.md` index + the feature's spec are the trail.
│
├─ Refactor internals without affecting Invariants / Validation?
│   → No CHANGELOG entry. Update spec `Source files` only.
│
└─ Fix a bug where code was violating an Invariant
   (i.e., code now matches the spec)?
    → No CHANGELOG entry. The spec was already correct; code caught up.
```

## Format per category

All entries live under a single date heading. **One date heading per day** — multiple entries on the same day group under that heading. Newest date on top.

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

After a rename, the spec file SHALL be renamed in the same diff (`spec-<old>.md` → `spec-<new>.md`), and the roadmap entry SHALL be updated. CHANGELOG is the trail; spec + roadmap are the current state.

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
- **invoice-generation** — Old: returned PDF as base64 string in the response body. New: returns S3 URL with 1-hour TTL. Migration: clients must fetch the URL and follow the redirect; bodies > 5MB are no longer supported.
- **email-search** — Old: returned 200 with empty array on no match. New: returns 404. Migration: clients SHALL handle 404 as "no results"; previously they checked `result.length === 0`.
```

The Migration line is the most-read part of the CHANGELOG. Be specific. "Update your client" is not a migration — say what to update.

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
- **UX Consistency** — Banned `@mui/*` imports in new code; existing usage flagged for migration to shadcn/ui. Reason: dual design systems caused inconsistency in v3 audit.
```

Tech stack changes that are temporary experiments do NOT belong here — wait until the dependency is committed to staying. The CHANGELOG records decisions, not experiments.

## Append rule (one date heading per day)

```markdown
## 2026-05-09
### Removed
- **xml-export** — ...

### Contract changed
- **invoice-generation** — ...

## 2026-04-30
### Renamed
- **user-search** → **email-search**. ...
```

Rules:

- One `## YYYY-MM-DD` heading per day. The first entry of a new day creates a new heading.
- Within a day, group entries under their `###` subsection. Subsections appear in a stable order: **Removed → Renamed → Contract changed → Constitution change**.
- Newest date goes on top.
- Never edit a past date heading's content after the day has passed. If you discover a missed entry, add it under today's date with a parenthetical note `(retroactive — change actually shipped <date>)`.

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

1. **Every removed/renamed/contract-changed feature has a CHANGELOG entry** under today's date.
2. **Every CHANGELOG entry has matching state** — Removed entries have `Status: removed` in the spec; Renamed entries have the file renamed and roadmap updated; Contract changed entries have the new `Invariants` / `Validation` content visible in the spec.
3. **Every `Migration:` line is specific** (no "update your client", no blanks).
4. **No invented entries** — if the diff doesn't show a removal/rename/contract change, don't write one.
5. **No silent constitution drift** — if `package.json` / `Cargo.toml` shows a dependency change but no `### Constitution change` entry exists, either add one or document why it doesn't qualify (e.g., experimental, soon to be reverted).
6. **One date heading per day** — if today's heading exists, add to it; don't create a duplicate.
7. **Subsection order within a day**: Removed → Renamed → Contract changed → Constitution change.

Specs whose `Source files` paths no longer exist often signal a removal that needs a CHANGELOG entry — when reconciling, confirm each affected spec's `Source files` still resolve (see [`sync-guide.md`](sync-guide.md) → Stale spec exception).

## Archive policy (when CHANGELOG.md gets large)

If `docs/CHANGELOG.md` grows beyond ~6 months of entries OR exceeds ~500 lines, split into monthly archive files. CHANGELOG.md becomes **index + current month inline**; past months move to `docs/changelog/YYYY-MM.md`.

### Target shape

`CHANGELOG.md` keeps an intro + an `## Archives` index (relative links to each month, newest first, with entry counts) + the **current month inline**. Each archived month lives in `docs/changelog/YYYY-MM.md`, headed `# Changelog — YYYY-MM`, with date headings and subsection structure preserved.

### Trigger and procedure

The skill does **NOT** auto-split. **First**, surface the option and let the user confirm (some teams prefer one grep-able file):

> CHANGELOG.md is <N> lines spanning <M> months. Archive months older than the current to `docs/changelog/`?

Only after they confirm: group entries by month, write each non-current month to its archive file, rewrite `CHANGELOG.md` as intro + `## Archives` index + current month inline, and show the multi-file diff before writing.

### Ongoing, once split

- New entries always go to the current-month section of `CHANGELOG.md` — nothing else changes day-to-day.
- When the first entry of a new month arrives, move the previous month's content into `changelog/YYYY-MM.md` and update the `## Archives` index (previous month gets a count + link; new month becomes "current month").
- In READ mode only `CHANGELOG.md` (index + current month) loads; open an archived month on demand — a historical question, a spec cross-link, or a removal audit.

## Anti-patterns

| Anti-pattern | Why it's bad | Fix |
|---|---|---|
| `Reason: cleanup` | Future sessions can't tell if removal was deliberate or a mistake | Be specific: "no client used for 6 months", "replaced by X after audit" |
| `Migration: update your client` | Doesn't tell the caller what to update | Say the exact behavior change: "handle 404 as empty result instead of checking length" |
| Logging refactors as "Contract changed" | Refactors that preserve `Invariants` and `Validation` are not contract changes | If the spec text didn't change, don't log it. Bump `Last verified` only. |
| Writing entries for features that never shipped | `Later` / `Next` drops don't need CHANGELOG (they never had a contract) | Just delete the roadmap row. CHANGELOG only logs features that actually shipped (had a contract). |
| Long prose in entries | CHANGELOG is for scanning, not reading | Keep each bullet to 1-3 lines. Long context goes in a linked post-mortem/ADR. |
| Multiple date headings on the same day | Breaks the append rule | Merge under one `## YYYY-MM-DD` heading. |
| Editing past entries to "improve" wording | Past entries are immutable history | Add a new entry today with the correction; don't rewrite history. |
| Bumping the CHANGELOG for renames in private code | Internal-only renames (no external callers) don't need CHANGELOG bloat | Only CHANGELOG renames of features with external surface (public API, CLI, UI route). |
| Logging every dependency bump | Patch/minor bumps of an existing tech stack entry are not constitution changes | Only log Tech Stack changes that add/remove a tool, swap a framework, or cross a major version. |
