# Catalog format — full reference

Read this file when you need the exact schema for any of the catalog files (layout tree → SKILL.md). Sections: where content lives, the four project-level docs and the changelog folder (one file per entry), decision records, debugging entries, the per-feature spec (with status semantics, Invariants, Implementation decisions, Validation, Open questions), a full example, progressive rigor, and slug rules.

## Where content lives

Seven kinds of content, seven homes. A piece of content has exactly one — duplicating it across two files is how the catalog starts contradicting itself.

| Content | Home |
|---|---|
| Externally observable contract of one feature | spec → `Requirement` / `Invariants` |
| Decision scoped to **one** feature | spec → `Implementation decisions` |
| Decision touching **≥2 features** or the **constitution** | `docs/decisions/` |
| Bug investigation trail (symptom → real root cause) | `docs/debugging/` |
| Durable guard against a bug recurring | spec → new invariant + matching `Validation` criterion |
| Audit line: what changed, what callers must do | `docs/changelog/` |
| Short gotcha / hidden coupling / anti-pattern | spec → `Notes` |

Two consequences worth stating outright, because both are easy to get backwards:

- A debugging entry does **not** replace the guard. The entry records the investigation; the protection lives in the spec as an invariant plus a Validation criterion.
- A decision record does **not** replace the changelog entry. A constitution change still gets its audit line in `docs/changelog/`; that line links to the decision record, which carries the reasoning.

## Index file: `docs/overview.md`

The central index. Always overview/summary — never a dump of full feature details.

```markdown
# Spec catalog — <project name>
_Project docs live in this folder; per-feature specs in `specs/`. No date line — git records when this last changed._

## Project docs
- [Constitution](constitution.md) — principles, tech stack, quality bars
- [Mission](mission.md) — problem, users, value, success metrics
- [Roadmap](roadmap.md) — feature delivery plan & status
- [Changelog](changelog/) — deletions, renames, contract changes (one file per entry)
- [Decisions](decisions/) — cross-cutting decision records (one file per entry)
- [Debugging](debugging/) — bug post-mortems: root cause + how to recognise it (one file per entry)

## Feature specs
- [jwt-authentication](specs/spec-jwt-authentication.md) — JWT auth with refresh token rotation
- [email-search](specs/spec-email-search.md) — Search users by email, case-insensitive
- ...
```

Links use **relative paths** (`constitution.md`, `specs/spec-jwt-authentication.md`) so the folder is portable if it moves. The `Decisions` and `Debugging` lines appear only once their folder has its first entry — see "Both folders: creation, links, and restraint" below.

## Constitution: `docs/constitution.md`

Project principles. Immutable-ish — changes require explicit user approval and a changelog entry under `### Constitution change`.

Five fixed sections. Empty subsections must use `_TBD: <prompt>_` rather than blanks (so future sessions know to ask).

```markdown
# Constitution
_Project principles. Changes require user approval._

## Tech Stack
- **Language / runtime**: <e.g., TypeScript on Node 22>
- **Framework**: <e.g., NestJS 10>
- **Database**: <e.g., PostgreSQL 16 + Redis 7>
- **Build / deploy**: <e.g., Vite + Docker + Fly.io>

## Code Quality
- <rule 1 — e.g., "No `any` types in new code">
- <rule 2 — e.g., "Public functions document failure modes">
- <forbidden patterns, naming conventions, structure rules>

## Testing Standards
- **Required**: <e.g., "unit tests for every public function; integration tests for every endpoint">
- **Coverage**: <e.g., "≥80% line coverage on src/, blocking">
- **Forbidden**: <e.g., "no `skip()` in main branch">

## UX Consistency
- **Design system**: <e.g., "shadcn/ui + Radix primitives only">
- **Accessibility**: <e.g., "WCAG 2.2 AA on all user-facing pages">
- **i18n**: <e.g., "all strings via i18n keys, no hardcoded English">

## Performance Requirements
- **Latency budgets**: <e.g., "API p95 < 200ms, page TTFB < 100ms">
- **Throughput**: <e.g., "search endpoint handles 500 rps sustained">
- **SLO targets**: <link to SLO doc, or list directly>
```

Constitution changes get a changelog entry with the reason. New tech stack adoption (adding a DB, swapping framework) is a constitution change AND usually triggers a roadmap update.

## Mission: `docs/mission.md`

Why this project exists. Stable across many releases — only changes when product strategy shifts.

Four fixed sections. `_TBD:` allowed if user defers, but never blank, never invented.

```markdown
# Mission

## Problem
<what gap this fills, in 1-3 sentences. The pain point users had before this existed.>

## Users
<who uses this and what role they're in. Be specific:
- <persona 1>: <context, why they need it>
- <persona 2>: <context>>

## Value proposition
<the single sentence answer to "why use this instead of alternative X?">

## Success metrics
<measurable outcomes proving the mission is being served:
- <metric 1 — e.g., "weekly active builders ≥ 50">
- <metric 2 — e.g., "time-to-first-feature < 1 day">>
```

## Roadmap: `docs/roadmap.md`

Forward plan (unshipped work only). Feature lifecycle:

```
Later  →  Next  →  Now  →  ✓ shipped
(idea)   (spec'd) (active)  (leaves the roadmap)
```

```markdown
# Roadmap
_Forward plan only — shipped features leave the roadmap. One line per entry: summary + spec link; detail lives in the spec. No date line — git records when it last changed._

## Now
_In active development. Each item has a spec. Aim for ≤3 in flight._
- [ ] **<feature-slug>** — <one-line summary> — [spec](specs/spec-<feature-slug>.md) — _started <YYYY-MM-DD>_

## Next
_Spec'd and queued. Pull into Now when capacity opens._
- [ ] **<feature-slug>** — <one-line summary> — [spec](specs/spec-<feature-slug>.md)

## Later
_Idea pool. No spec yet. Promote to Next by writing a spec._
- [ ] **<feature-slug>** — <one-line summary>
```

**One line per entry.** A roadmap entry is exactly `**slug** — one-line summary — [spec](...)` (plus the start date in `Now`). Detail (acceptance criteria, sub-tasks, rationale) lives in the spec — carried on the roadmap it duplicates the spec, drifts, and bloats the file. An entry that seems to need more lines is the signal to write or expand its spec; `Later` items (no spec yet) keep to one line too.

**No `Shipped` group.** Once a feature ships it leaves the roadmap; shipped state is recorded by the spec (`Status: active`), the `overview.md` index, and changelog/git — not a list that grows forever and becomes a merge-conflict hotspot. (A team wanting an at-a-glance recap may keep a capped `## Recently shipped` of the last ~10 — but overview already serves this.)

### Lifecycle rules

- **Promote `Later` → `Next`**: write the spec first (Plan + Requirement + Validation + Open questions — record known unknowns), run it through the spec critique gate (below), then move the entry.
- **Promote `Next` → `Now`**: only when actively starting work; record the start date. Run the spec critique gate (below) and resolve `Open questions` down to `None.` — fold each answer into the spec/plan, or demote it to a non-goal. Tests are written from the surviving criteria (intent → tests, never the reverse); the catalog spec itself is typically written at SYNC, after ship, from that same plan. Building the item then follows the implementation handoff — isolated worktree, the plan document, the runtime's `superpowers:*` skills → SKILL.md.
- **Ship (`Now` → off-roadmap)**: at SYNC time, **remove the entry from `Now`** — the roadmap shrinks as you ship; there is no `Shipped` list to append to.
- **Drop a `Later` / `Next` item**: delete from roadmap. No changelog entry (it never shipped).
- **Deprecate / remove a shipped feature**: set the spec `Status: removed` and add a changelog entry under `### Removed`. It is already off the roadmap (nothing to move); if it somehow still sits in `Now` / `Next`, delete that row too.

A feature in flight is in **exactly one** of `Now` / `Next` / `Later`; once shipped it is no longer on the roadmap.

### Spec critique gate

A spec is not ready to build from until an **independent reviewer** has attacked it — the author of a spec is the worst judge of its gaps. The gate runs against the best spec available: the catalog spec if one exists, otherwise the design plan the implementation will follow.

**When it runs** — four triggers, no others:

1. A spec is drafted at `Later → Next`.
2. A feature is promoted `Next → Now`.
3. SYNC creates a spec, or rewrites an existing spec's `Requirement` / `Validation` (batched — one reviewer for all specs that sync touched).
4. BOOTSTRAP finishes drafting its specs (batched — one reviewer for the whole set).

Skip a trigger only when **this same session already reviewed this spec and has not edited it since** (so a draft-then-promote in one sitting reviews once, not twice). "Nothing material changed" from an earlier session is not a skip — that session's context is gone and its judgment isn't checkable.

The reviewer is a **fresh-context subagent on the strongest model available** (Claude Code: the `Agent` tool with `model: opus`; other runtimes: whatever independent-agent mechanism they offer, on their strongest model). This is a required step of the gate, not an optional second opinion.

**Step 1 — Dispatch the reviewer.** A fresh context knows nothing about the project, so pass it everything it needs to judge:

- the full spec (or plan) text, pasted inline — not just a link
- the paths of `docs/constitution.md` and `docs/mission.md` (the principles and the scope it must be checked against)
- the `Source plan` document, if one exists
- the source and test file paths the feature touches, if any exist yet
- the four checks below, verbatim, as its review rubric

**Step 2 — The four checks it runs:**

1. **Contradiction** — do any two Invariants (or an Invariant and a Plan statement) conflict?
2. **Coverage** — does every entry point in `Surface` have at least one Validation criterion for its failure path, not just the happy path?
3. **Testability** — can each Validation criterion be translated into an executable test as written? If not, rewrite it with concrete observable values, or delete it.
4. **Silent guesses** — list every place the spec chose an answer the user never gave (field sets, formats, limits, auth rules).

**Step 3 — What it returns.** Findings only. Each finding carries: which of the four checks it came from, the spec section or line it lands on, a severity (`blocker` | `should-fix` | `nit`), and one concrete suggested edit. The last line is a verdict: `ready to build` or `needs changes`. A rewritten spec, a restatement of what the spec already says, or a general appraisal is not the deliverable.

**Step 4 — Fold the findings into the spec.** Apply every `blocker` and `should-fix` you agree with, editing the spec in place. Where you disagree with a finding, say so to the user in one line with the reason — don't drop it silently. Anything that needs a user decision goes into the `## Open questions` section of the catalog spec (or of the plan document, when the catalog spec doesn't exist yet) — one line each: the question + what breaks if guessed wrong.

Roadmap-stage specs only, though: specs written at SYNC or BOOTSTRAP describe already-shipped code and carry no `Open questions` section (see the spec skeleton below). There, an unresolved finding is raised with the user directly — in the SYNC step-7 diff message, or in the BOOTSTRAP C7 summary — or written as a `_TBD: <question>_` marker in the affected section. Never as a guess stated as fact.

Do NOT park unresolved items in `Notes` or in prose ("TBD", "to confirm later", "placeholder"): only `Open questions` is checked by the `Next → Now` gate, so ambiguity parked anywhere else silently survives into implementation.

**Step 5 — Stop.** One review round is the default. Re-dispatch only when folding the findings materially changed `Requirement` or `Validation` (new invariants, rewritten criteria) — not for wording fixes. Don't loop until the reviewer runs out of things to say.

**Fallback.** If the runtime has no independent-agent mechanism, run the four checks yourself as a separate pass over the finished spec, and tell the user the review was inline rather than independent. Skipping the review because the spec "is small" or "was just written carefully" is the violation — that is exactly when silent guesses survive.

## Per-feature spec: `docs/specs/spec-<feature_name>.md`

Each feature gets its own file. Naming uses kebab-case with the `spec-` prefix (so `ls docs/specs/spec-*.md` lists all specs).

```markdown
### Feature: <short imperative name>
- **Status**: active | deprecated | removed
- **Roadmap**: Now | Next | Later | shipped (off-roadmap once live)
- **Source files**: <2-5 paths, most important first>
- **Source plan**: <path to design doc, or "none">
- **Decisions**: <docs/decisions/ paths, comma-separated — omit this line entirely if none>
- **Debugging**: <docs/debugging/ paths, comma-separated — omit this line entirely if none>
- **Last verified**: <YYYY-MM-DD> against `<short commit hash>`

## Plan
<design intent — the WHY and HOW at a high level. Cover:
- What problem this solves (link to mission section if relevant)
- The chosen approach and why over alternatives
- Tech choices that touch the constitution (if any)
- Non-goals — what this explicitly does NOT do>

## Requirement
- **Surface**: <how users / other services interact — endpoint, CLI command, queue topic, UI route>
- **Invariants**:
  - <bullet list of contracts this feature MUST keep, written from the caller's perspective>

## Implementation decisions (optional)
<settled choices from the design conversation, so they aren't relitigated later. Lower-altitude than Plan — the concrete "we picked X, not Y" calls. One bullet each, with the reason. Implementation detail, NOT contract — keep it out of Invariants.>

## Validation
<numbered acceptance criteria — verifiable conditions a reviewer can check by reading alone, without running tests. Each criterion is a Given/When/Then or a SHALL statement, numbered so it can be referenced independently. See "Validation section" below for format.>

## Notes (optional)
<gotchas, hidden coupling, anti-patterns, things future AI must NOT do>

## Open questions (roadmap-stage specs only — must read `None.` when the feature enters `Now`)
<known unknowns recorded while drafting, plus anything the spec critique gate surfaces at `Next → Now`. One line each: <question> — <what breaks if guessed wrong>. Write `None.` explicitly once all are resolved. Omit the section for specs written at SYNC/BOOTSTRAP from already-shipped code.>
```

`Decisions` and `Debugging` are optional backlinks to the two record folders. **Omit the line when there is no such record** — a spec for a feature that never had a contested decision or a hard bug looks exactly as it did before. They sit in the header block READ always reads, so a prior decision or a past root cause surfaces before any code is touched, without growing the spec body. The session that writes a record adds these backlinks to every spec named in the record's `Scope` / `Feature`, in the same change; READ never writes them. When a spec named in a record is later deleted (a `removed` feature, one release cycle on), the record keeps that name — it is append-only, and that the decision once covered that feature is exactly the history worth keeping.

### Status semantics

| Status | Meaning | Lifecycle action |
|---|---|---|
| `active` | Feature is in use. Default for new entries. | Keep until deprecated. |
| `deprecated` | Still works, but new code SHALL NOT call it. Has a successor (link in `Notes`). | Flip to `removed` once the successor has shipped for ≥1 release and no caller remains. |
| `removed` | Entry point gone. | Keep the spec file for one release cycle so AI can see WHY it was removed (prevents reintroduction). After that, delete the file; the changelog keeps the audit trail. |

Worked example: a `schedule-v2` feature deprecates in release 2.0, becomes `removed` in 2.1, and its spec file is deleted in 2.2.

### Plan section

Plan answers WHY this feature was built this way. It's the bridge between mission (the project's why) and code (the how). A reader who hasn't seen the design doc should be able to:

- Trace the feature back to a mission goal or user need
- Understand the chosen approach and major rejected alternatives
- See which constitution principles drove the decision (e.g., "uses Postgres because constitution requires single-DB")

If a separate design doc exists, link it in the `Source plan` metadata field and keep this section to a 3-5 bullet summary. If no design doc exists, this section IS the design doc.

### Requirement section

Requirement is the externally observable contract. `Surface` describes the entry points; `Invariants` describes what callers can rely on.

#### The `Invariants` field is the most important field

This stops future AI from "improving" a function in a way that breaks callers. Be specific. Tests are the best source of invariants — they describe contracts explicitly. Read tests before implementation when extracting.

- Bad: `Returns user data`
- Good: `Returns 404 if email not found, never 200 with null. Email comparison is case-insensitive. Soft-deleted users (deleted_at IS NOT NULL) are excluded from results.`

If you cannot prove an invariant from code or tests, do not write it. Vague invariants are worse than missing ones — they create false confidence.

#### Behavior vs implementation boundary

`Invariants` SHALL describe externally observable behavior only — what a caller can verify without reading the source. Implementation detail belongs in `Notes` or the document linked from `Source plan`.

| Belongs in `Invariants` | Belongs in `Notes` / `Source plan` |
|---|---|
| HTTP status codes, response shapes, error payloads | Library / framework choice (`uses bcrypt`, `built on Redis`) |
| Ordering and idempotency guarantees | Internal class / function structure |
| Input validation rules and rejection cases | Where the logic lives in the file tree (that's `Source files`) |
| Side effects visible to callers (events emitted, rows written) | Caching strategy, retry policy internals |
| Concurrency / race contracts (`refresh token rotated atomically`) | Algorithmic complexity, micro-optimizations |

Rule of thumb: if rewriting the implementation in a different language would change the bullet, it's implementation detail — move it out of `Invariants`.

#### Optional: structured invariant format

For most features, plain bullets are enough. Escalate to a structured `WHEN / THEN / AND` block when the invariant has any of these properties:

- Multiple branches that are easy to swap by accident (e.g., 401 vs 403, 404 vs empty 200)
- Race conditions or ordering guarantees a future reader could break by reordering code
- Compliance contracts (SOC2, GDPR, audit trail) where the exact wording matters
- Edge cases where past regressions came from misreading the contract

Format:

```markdown
- **Requirement**: <one-line SHALL statement>
  - **WHEN** <trigger / precondition>
  - **THEN** <observable outcome>
  - **AND** <additional outcome, if any>
```

Use SHALL / MUST for hard contracts (breaking them is a bug). Use SHOULD for strong recommendations that callers may opt out of with explicit reason. Do not use MAY in invariants — if it's optional, it's not an invariant.

Mix freely with plain bullets in the same `Invariants` block; do not convert simple invariants into scenarios just for uniformity.

### Implementation decisions section (optional)

Records the concrete choices settled during the design conversation, so a later session doesn't reopen them. This is the "we chose X over Y, because Z" layer — lower-altitude than `Plan` (which sketches the overall approach), and deliberately kept out of `Invariants` (which is the caller-facing contract).

- **When to include it**: when real alternatives were weighed and the losing option is likely to be re-proposed later ("why not just use a cron?", "why not store this in Redis?"). If nothing was contested, omit the section — don't manufacture decisions.
- **Format**: one bullet per decision, each naming the choice and the reason. Reference the rejected alternative when it's non-obvious.
  - Good: `Chose optimistic locking over row locks — write contention is rare and row locks stalled the import job in load tests.`
  - Bad: `Uses optimistic locking.` (no reason — that's just a fact, put it in Notes if it even matters)
- **Boundary**: these are *decisions*, not *contracts*. If a bullet describes something a caller can observe and rely on, it's an invariant — move it to `Requirement`. If it's a gotcha or an anti-pattern warning, it's a `Note`. Implementation decisions answer "why is it built this way", not "what must stay true".

If a separate design doc already captures these, link it in `Source plan` and keep this section to the 2-3 decisions most likely to be second-guessed.

### Validation section (acceptance criteria)

Each criterion is a verifiable condition a human reviewer can check by reading alone (no test execution needed). **Number the criteria** (`1.`, `2.`, …) so each one is independently addressable — reviews, changelog entries, and test names can cite "Validation #3" without ambiguity. Two acceptable formats:

**Plain SHALL statement:**
```markdown
1. The login response SHALL include a `user.id` field of type UUIDv4.
2. The system SHALL reject email addresses longer than 254 characters with HTTP 400.
```

**Given / When / Then (preferred for branching scenarios):**
```markdown
1. **Given** a user with `deleted_at IS NOT NULL`, **when** they POST `/auth/login` with valid credentials, **then** the response is `401` with body `{ "code": "account_disabled" }`.
2. **Given** a valid refresh token, **when** the user calls `/auth/refresh`, **then** the old refresh token is revoked atomically with the new one being issued.
```

Mix the two formats freely in one numbered list — keep a single running sequence so numbers stay stable. When a criterion is retired, leave the higher numbers as-is (don't renumber) so existing references don't silently point at the wrong thing.

Tests prove these criteria; the criteria themselves are the source of truth for "what does correct mean". When a test changes (framework swap, assertion rewrite), the criteria do not — they describe the contract from the caller's perspective.

**Direction rule (intent → tests):** the contract comes from intent — a catalog spec written before implementation, or the design plan (e.g., superpowers output) the feature was built from. Tests are written FROM those criteria, and at SYNC the Validation section derives from the plan's criteria as verified by the tests — do not reverse-engineer the contract from whatever the tests happen to assert. If tests and the pre-implementation criteria disagree at SYNC time, surface the mismatch to the user: either the implementation missed the contract, or the contract legitimately changed (→ changelog `### Contract changed`). Test-only extraction is for BOOTSTRAP and legacy features that never had a spec or plan.

**Traceability rule**: every Validation criterion SHALL trace back to an `Invariants` bullet (1:1 or many:1 — never an orphan criterion). If you write a criterion with no matching invariant, the invariant is missing — add it.

### The `Notes` field

Use for things that would surprise a reader and cannot be inferred from code:

- Hidden coupling (`Order webhook fires before invoice creation — race condition possible if reversed`)
- Performance constraints (`Must complete in <100ms — measured by SLO dashboard`)
- Anti-patterns (`Do not cache decoded JWT — token revocation depends on per-request DB lookup`)

`Notes` is for short gotchas only. Why a cross-cutting choice was made goes to `docs/decisions/`; how a hard bug was tracked down goes to `docs/debugging/`. Prose history parked in `Notes` is unfindable — nothing greps it and nothing links to it.

## Full example

```markdown
### Feature: jwt-authentication
- **Status**: active
- **Roadmap**: shipped (off-roadmap)
- **Source files**: `src/auth/login.ts`, `src/auth/refresh.ts`, `src/auth/jwt.ts`, `src/middleware/require-auth.ts`
- **Source plan**: `docs/superpowers/2025-12-jwt-auth-plan.md`
- **Decisions**: `docs/decisions/2025-11-18-stateless-api-tier.md`
- **Last verified**: 2026-04-30 against `a1b2c3d`

## Plan
Mission link: serves the "secure self-serve onboarding" goal. Chose JWT over server-side sessions because constitution requires stateless API tier (no shared session store). Refresh token rotation added for SOC2 audit trail. Non-goal: SSO — that's a separate feature.

## Requirement
- **Surface**: `POST /api/auth/login`, `POST /api/auth/refresh`, `POST /api/auth/logout`
- **Invariants**:
  - Returns 401 with empty body on wrong password (never 200 with null token)
  - Access token TTL = 15 minutes, refresh token TTL = 30 days
  - Email comparison is case-insensitive (lowercased before bcrypt compare)
  - Soft-deleted users (`deleted_at IS NOT NULL`) cannot log in
  - **Requirement**: Refresh token rotation SHALL be atomic
    - **WHEN** `/auth/refresh` is called with a valid refresh token
    - **THEN** the old refresh token is revoked
    - **AND** a new refresh token is issued in the same DB transaction

## Implementation decisions
- Chose opaque refresh tokens (random 256-bit, stored hashed) over JWT refresh tokens — opaque tokens can be revoked server-side per-row, which SOC2 audit requires; a JWT refresh token can't be revoked before expiry without a denylist.
- Refresh rotation done in a single Postgres transaction, not two statements — avoids the window where both old and new tokens are valid if the process dies mid-rotation.

## Validation
1. **Given** valid email + correct password, **when** POST `/api/auth/login`, **then** response is 200 with body matching `{ access_token: <jwt>, refresh_token: <opaque>, expires_in: 900 }`.
2. **Given** valid email + wrong password, **when** POST `/api/auth/login`, **then** response is 401 with empty body.
3. **Given** a soft-deleted user, **when** they POST `/api/auth/login` with correct credentials, **then** response is 401.
4. **Given** a valid refresh token, **when** POST `/api/auth/refresh` succeeds, **then** the old refresh token returns 401 on subsequent use.
5. The system SHALL reject login attempts with email length > 254 chars with HTTP 400.

## Notes
Do not cache decoded JWT — token revocation depends on per-request DB lookup. Refresh token rotation is required by SOC2.
```

## Changelog: `docs/changelog/`

Tracks deletions, renames, contract changes, and constitution changes. Answers the critical question: "was this removed on purpose, or did AI forget?"

A **folder of per-entry files** — one flat file per (date, feature), named `YYYY-MM-DD-<slug>.md`, so parallel sessions each write their own file and never merge-conflict. Constitution changes use the fixed slug `constitution`; renames use the new slug (old slug appears in the body). No index file — `ls docs/changelog/ | sort -r` is the chronology; `grep -r "<slug>" docs/changelog/` is the lookup.

Skeleton of one entry file, e.g. `docs/changelog/2026-08-07-email-search.md` (no title or date heading inside — the filename carries both; include only the `###` sections that apply, in this order):

```markdown
### Removed
- **<feature-slug>** — Reason: <why>. Replaced by: <successor or "nothing">.

### Renamed
- **<old-slug>** → **<new-slug>**. Reason: <why>.

### Contract changed
- **<feature-slug>** — Old: <prev>. New: <now>. Migration: <what callers must do>.

### Constitution change
- **<section>** — <what changed>. Reason: <why>.
```

For file naming rules, decision tree (which category does my change fall into?), per-category required fields, full examples, migration guidance, cross-link rules, audit checklist, and legacy `CHANGELOG.md` migration → [`changelog-guide.md`](changelog-guide.md). Read that file before adding any changelog entry.

## Decision records: `docs/decisions/`

Cross-cutting decisions — the ones a later session is most likely to reopen because the reasoning left with the person who made it. Same mechanics as the changelog: a flat folder, one file per entry, `YYYY-MM-DD-<slug>.md`, no index file. `ls docs/decisions/ | sort -r` is the chronology; `grep -rl "<slug>" docs/decisions/` is the lookup.

**Write an entry when at least one holds:**

1. The decision affects ≥2 specs.
2. The decision changes `constitution.md` (any of its five sections).
3. The decision reverses an existing decision record.

A decision inside one feature's boundary is not one of these — it belongs in that spec's `Implementation decisions`.

```markdown
- **Status**: accepted | superseded
- **Scope**: <spec slugs and/or constitution sections affected>
- **Supersedes**: <filename> | none
- **Superseded by**: <filename> | none

## Context
<the forces in play — constraints, what made this a real choice>

## Decision
<what was chosen, and what it commits the project to>

## Alternatives rejected
- <alternative> — <why it lost>
```

**Append-only.** A change of mind is a new entry carrying `Supersedes:`; the old entry gets `Status: superseded` plus a `Superseded by:` line, and nothing else in it is edited. Rewriting the old entry destroys the only thing the folder exists to hold.

## Debugging entries: `docs/debugging/`

The investigation trail for a bug that was expensive to find. Same file mechanics as `docs/decisions/`.

**Write an entry when at least one holds:**

1. The root cause was **not** in the file the symptom pointed to.
2. The bug is a recurrence (this behavior was reported or fixed before).
3. The fix reverses an earlier deliberate decision (a spec's `Implementation decisions`, or a decision record).
4. The investigation spanned more than one working session.

```markdown
- **Feature**: <spec slug(s)>
- **Trigger**: <which condition above fired>
- **Root cause location**: <file where the cause actually was>

## Symptom
<what was observable, in the terms it was first reported>

## Where it looked like the bug was
<the plausible wrong place, and why it was plausible>

## Root cause & fix
<the actual mechanism, and what changed to correct it>

## How to recognise it next time
<the distinguishing signal that separates this from its look-alikes>

## Guard added
<link to the new invariant + Validation criterion, or "none — <reason>">
```

`Guard added` is not optional. A post-mortem with no guard and no reason is a story, not a contract — the folder holds the investigation, the spec holds the protection.

## Both folders: creation, links, and restraint

- **Created on first entry.** BOOTSTRAP creates neither. The session writing the first entry creates the folder and adds that folder's link to `overview.md`'s `## Project docs` list in the same change — so the index never carries a dead link and the repo never carries an empty folder.
- **Overview links to folders only**, never to individual entries — `overview.md` is an index and does not grow with history.
- **An entry fits on one screen.** Length is not quality, the same rule Progressive rigor applies to specs. Sections with nothing real to say are dropped, not filled.
- **A trigger that does not fire writes nothing** — no empty folder, no placeholder entry, no `none` line in a spec.
- **A bug fix that reverses a decision record writes both entries, not one** — that event fires decision trigger #3 and debugging trigger #3 together. The debugging entry's `Root cause & fix` names the new decision record; the new record's `Context` names the debugging entry as what forced the reversal, and it supersedes the old one per the append-only rule above.

## Progressive rigor — when to expand a spec entry

Default: header metadata + Plan + Requirement + Validation + (optional Implementation decisions / Notes) is enough for ~80% of features. Resist the urge to make every spec exhaustive — over-detailed specs rot faster than they help. Add `Implementation decisions` only when a real choice was contested; add `Notes` only when there's a genuine gotcha.

Expand a spec (longer invariant list, scenario blocks, dense Notes, more validation criteria) only when at least one of these is true:

- The feature has caused a regression in the past (the post-mortem is a `docs/debugging/` entry, linked from the spec's `Debugging` field)
- It has a documented race condition or ordering requirement
- It crosses a compliance boundary (SOC2, GDPR, PCI, audit logging)
- It is called by ≥2 teams or external clients (the contract is now public)
- A previous AI session misread it (add the misread case as an invariant + matching validation criterion so future sessions catch it)

If none of these apply, keep the entry short. Length is not quality.

## Capability slug rules

The `<feature_name>` in `spec-<feature_name>.md` is the capability slug. Treat it as a stable identifier — it appears in `overview.md`, `roadmap.md`, changelog filenames and entries, and cross-references between specs.

- **Format**: lowercase kebab-case, `verb-noun` or `noun-action` (e.g., `jwt-authentication`, `email-search`, `invoice-generation`, `order-cancellation`).
- **Flat namespace**: no nested folders under `docs/specs/`. If two features feel like they need a folder, they are probably one feature with two scenarios.
- **Avoid abstract names**: `util`, `helpers`, `core`, `service`, `manager` — these collide with everything and describe nothing.
- **Avoid bare nouns**: `user`, `order`, `payment` — qualify them with the action (`user-creation`, `order-cancellation`, `payment-capture`).
- **Stability**: once published, a slug rename SHALL go through a changelog `### Renamed` entry so external links can be updated. The roadmap entry SHALL be updated in the same diff.

## Naming collisions

If two features have similar names (e.g., `search` and `email-search`), prefer the more specific name and qualify the broader one:

- `spec-search.md` (broad search across entities) → rename to `spec-global-search.md`
- `spec-email-search.md` (only email lookup) → keep as-is

Avoid bare nouns like `spec-user.md` — they collide with future features. Use action+object: `spec-user-creation.md`, `spec-user-deletion.md`.
