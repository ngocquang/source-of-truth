# Bootstrap mode — full guide

Read this file when running BOOTSTRAP mode (no `docs/overview.md` exists yet, but the project has code). Also runs in **Re-bootstrap** form when the catalog exists but `constitution.md` or `mission.md` is missing/empty (see end of this file).

Bootstrap runs **once** per project. After this, SYNC mode handles all incremental updates.

## Why this matters

Bootstrap also updates `CLAUDE.md` so that **future sessions automatically read the catalog** even when this skill doesn't trigger. This propagates the "always read the spec first" rule across every session — it's the single most important step. Don't skip it.

## Three-phase flow

Bootstrap runs in three phases:

- **A — Auto-detect** (no user input): scan repo for tech stack, test framework, design system, README intro. Pre-fill what we can prove from files.
- **B — Interview user** (single batch): ask only the things we can't detect. Code Quality rules, Performance budgets, Mission users/value/metrics require user input.
- **C — Confirm and write**: show the populated docs to the user, get OK, then write all 5 project docs (overview, constitution, mission, roadmap, CHANGELOG) + per-feature specs, and update CLAUDE.md.

`constitution.md` and `mission.md` MUST have real content before bootstrap completes. Use `_TBD: <prompt>_` markers if the user defers a section, but never blank fields and never fabricated content. Fabricated content propagates to every future session as if it were truth.

## Step 0 — Confirm with the user

Ask before scanning:

- "I'll create the spec catalog at `docs/overview.md` + `docs/constitution.md` + `docs/mission.md` + `docs/roadmap.md` + `docs/CHANGELOG.md` + `docs/specs/spec-<feature>.md` per feature. Continue?"
- **Initial bootstrap only** (no existing catalog): "Are there design docs I should pull from? (e.g. `docs/superpowers/`, `specs/`, `plans/`, ADRs, RFCs)"

If the user has design docs, use them as the **primary source of feature intent and mission**. Code shows implementation; docs show intent. Combining both produces accurate plans, requirements, and validation criteria.

For **re-bootstrap** (catalog exists, only `constitution.md` or `mission.md` is missing): skip the design-docs question. The existing roadmap + spec catalog already supply that context — going back to external PRDs duplicates the source-of-truth and risks divergence. Pull from the catalog itself.

## Phase A — Auto-detect

Pull from the repo, no user questions yet.

### A1. Tech stack (constitution → Tech Stack)

Read whichever exists:

- `package.json` (Node) — `dependencies`, `devDependencies`, `engines`
- `Cargo.toml` (Rust)
- `pyproject.toml` / `requirements.txt` (Python)
- `go.mod` (Go)
- `composer.json` (PHP)
- `pubspec.yaml` (Flutter / Dart)
- `Gemfile` (Ruby)
- `Dockerfile` / `docker-compose.yml` (DBs, runtimes)

Extract: language + version, framework, DB, cache, queue, build tool, deploy target.

### A2. Test framework (constitution → Testing Standards)

Detect: jest, vitest, mocha, pytest, go test, cargo test, phpunit, flutter test. Look for coverage configs (`jest.config`, `vitest.config`, `.coveragerc`, `pytest.ini`).

Note: this only fills the "what test runner is in use" line. The user still has to provide the **rules** (required test types, coverage threshold, forbidden patterns) in Phase B.

### A3. Design system (constitution → UX Consistency)

Search dependencies for: shadcn-related packages, `@radix-ui/*`, `@mui/*`, `antd`, `chakra-ui`, `tailwindcss`, design tokens. Note what you find.

### A4. README intro (mission → Problem)

If `README.md` exists, pull the first paragraph after the title. Use it as a draft for `Mission > Problem` — but mark it as `(from README, please verify)` so the user knows it's not yet confirmed.

### A5. Entry-point scan (feature specs)

Identify entry points (where users interact with the system). Examples:

- HTTP routes / API handlers (`routes.ts`, `app.py`, `controllers/*.rb`)
- CLI commands (`cli.ts`, `bin/*`)
- Queue consumers / event handlers
- UI page routes (`pages/*`, `app/*/page.tsx`)
- Public exports of a library (`index.ts` / `lib.rs`)

**Cap on files read:**

- **Single-repo project:** max 15 entry-point files total
- **Monorepo / workspace:** max 15 files **per package**, mark packages exceeding this as `PARTIAL`
- A "package" = anything with its own `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod`. Apps in `apps/`, libs in `packages/`, services in `services/`.

Prioritization (when there are more than 15 candidates), in order until cap:

1. Files with the most public exports (these define the API surface)
2. Files referenced by the entry point (`main.ts`, `app.ts`, `routes.ts`)
3. Files with associated tests (tests prove invariants and feed Validation criteria)
4. Files modified most recently (active features matter more than dead code)
5. Files referenced in design docs

## Phase B — Interview user

Ask **all of these in one message** (don't drip-feed). Show what was auto-detected next to each section so the user knows what's already filled.

```
I've auto-filled the parts I could detect from the repo:
- Constitution > Tech Stack: <list from A1>
- Constitution > Testing Standards (test runner): <from A2>
- Constitution > UX Consistency (design system): <from A3>
- Mission > Problem (draft from README): <from A4>

To finish bootstrap I need answers to these:

CONSTITUTION
1. Code Quality — what rules/patterns to enforce beyond the linter?
   (e.g., "no `any` in new code", "public functions document failure modes",
   forbidden patterns, naming conventions)
2. Testing Standards — required test types and coverage rules?
   (e.g., "unit tests for every public function; integration tests for every endpoint;
   ≥80% line coverage on src/, blocking")
3. Performance Requirements — latency budgets, throughput targets, SLOs?
   Reply "skip" if no formal targets yet.

MISSION
4. Problem — does the README draft above capture it correctly? Edit if not.
5. Users — who uses this and in what role? List 1-3 personas.
6. Value proposition — one sentence: why use this over the alternative?
7. Success metrics — how do you know the mission is being served? 1-3 measurable outcomes.

(Reply "TBD" for any section I should defer — I'll mark it for later, never fabricate.)
```

If the user deflects ("just write something reasonable") — push back once: "Mission and Code Quality require your judgment, otherwise the catalog will mislead future sessions. Even one-line answers are fine." If they still defer, write `_TBD: <the question>_` for that field. Never invent content.

## Phase C — Confirm and write

### C1. Show the user the populated docs

Render `constitution.md` and `mission.md` in a single message for review:

> Here's what I'll write. Edit anything before I commit it.

Wait for OK or edits.

### C2. Create per-feature spec files

For each identified feature, create `docs/specs/spec-<feature_name>.md` using the format in `references/catalog-format.md`. Use kebab-case for the filename.

For each spec, fill the four content sections:

- **Plan**: pull from the design doc if linked; otherwise infer from code + tests in 3-5 bullets covering problem, approach, alternatives, non-goals. Mark `_TBD: design rationale not documented_` if you genuinely can't infer.
- **Requirement > Surface**: extract from the entry point.
- **Requirement > Invariants**: extract from tests first, code second. Skip what you can't prove. Tests describe contracts more reliably than implementations.
- **Validation**: convert each test case into a Given/When/Then or SHALL acceptance criterion. Each criterion SHALL trace to an Invariants bullet. If no tests exist for a feature, mark `_TBD: no tests yet — acceptance criteria need confirmation_`.

If a package's code is too complex for 15 files to capture meaningfully, mark the package's specs with a `PARTIAL` note in the index entry, like:

```markdown
- [billing-engine](specs/spec-billing-engine.md) — _PARTIAL_ — Core billing logic only. Edge cases in tax calculation not yet captured.
```

### C3. Create the roadmap

The roadmap holds only **unshipped** work. Bootstrapped features already exist in code (they shipped), so they do **not** go on the roadmap — they are captured by their specs (`Status: active`) and the `overview.md` index. The roadmap therefore starts essentially empty: only in-flight or planned work.

`Now`, `Next`, `Later` start empty unless the user mentions in-flight or upcoming work during the interview. If they do, capture it:

```markdown
## Now
- [ ] **<feature>** — <one-line> — _started <date>_  (no spec yet — write before continuing development)
```

### C4. Create the index

Write `docs/overview.md` listing project docs and all features. Use the format in `references/catalog-format.md`.

### C5. Initialize the CHANGELOG

Write `docs/CHANGELOG.md`:

```markdown
# Changelog

## <today's date>
### Bootstrapped
- Initial spec catalog created from existing code at commit `<short hash>`.
- Files scanned: <N>. Features identified: <M>. Marked PARTIAL: <list, or "none">.
- Constitution sections auto-filled: <list>. User-provided: <list>. TBD: <list, or "none">.
- Mission sections user-provided: <list>. TBD: <list, or "none">.
```

### C6. Update CLAUDE.md (DO NOT SKIP)

This is the highest-leverage step. Append a section so every future session reads the catalog before coding, even when this skill doesn't trigger:

```markdown
## Spec Catalog (source of truth)

This project follows Spec-Driven Development. The catalog lives at:

- `docs/overview.md` — index of project docs and feature specs
- `docs/constitution.md` — principles, tech stack, quality bars (gates implementation choices)
- `docs/mission.md` — problem, users, value, success metrics (gates feature scope)
- `docs/roadmap.md` — Now / Next / Later forward plan (shipped work leaves the roadmap)
- `docs/CHANGELOG.md` — deletions, renames, contract changes
- `docs/specs/spec-<feature>.md` — per-feature Plan + Requirement + Validation

**Always read `docs/overview.md` at the start of every session** to load the source
of truth. Following this process is mandatory, not advisory: before writing,
modifying, or deleting code, walk these three gates in order. Each gate is a
STOP — do not proceed to the next until the current one clears, and do not
"use judgment" to skip a gate. (This is the *enforcement* order — roadmap first
because the iron-rule is the cheapest, hardest stop. It is independent of the
order READ mode reads files in, which only loads context.)

### Gate 1 — Roadmap (iron-rule)
Read `docs/roadmap.md`. EVERY unit of work — feature, refactor, **and bug fix** —
gets a roadmap entry before code is written. This gate's job is to block the
*assistant's own* "too small to track" rationalizing — that is how the roadmap
silently drifts from reality. If the work is not in `Now` / `Next` / `Later` (and has no spec yet — i.e. not already shipped),
STOP, surface it, and add it (`Now` or `Next`) first, then code. The user can
override — but urgency is not an override: "be quick" or "we demo in 5 minutes"
means work fast, not skip the gate (the entry costs seconds, so add it and move
fast). A real override is the user, aware of the rule, explicitly choosing to
proceed without it (e.g. a live hotfix); then do so, say so, and recommend a
retroactive roadmap + CHANGELOG entry. Quietly shipping off-roadmap — or skipping
because it felt small or rushed — is the violation.

### Gate 2 — Constitution
Read `docs/constitution.md`. STOP if the planned approach conflicts with
Tech Stack, Code Quality, Testing Standards, UX Consistency, or Performance
Requirements. Either change the approach, or ask the user to update the
constitution first (with reason + CHANGELOG entry under
`### Constitution change`) before coding.

### Gate 3 — Spec invariants
Read the relevant `docs/specs/spec-<feature>.md`. STOP if the change would
break a documented invariant or acceptance criterion. Either confirm with
the user (it goes in CHANGELOG under `### Contract changed`) or rethink.

### Commit gate — SYNC before every commit
Before ANY `git commit` — whether you initiated it or the user asked for one —
the catalog must already reflect the change. So whenever a commit is requested
(or you are about to commit), FIRST run source-of-truth SYNC automatically, then
commit — do not ask, just sync then commit:

1. Reconcile each affected `docs/specs/spec-<feature>.md` with the diff.
2. Remove the shipped entry from `Now` (the roadmap holds only unshipped work).
3. Record removals / renames / contract changes / constitution changes in
   `docs/CHANGELOG.md`.
4. Commit the code **and** the catalog updates together.

Self-gating: this applies only because `docs/overview.md` exists. Skip the sync
only when there is genuinely nothing to reconcile (a pure internal refactor that
touches no spec) or the user explicitly overrides for this commit (e.g. a live
hotfix) — then proceed and recommend a retroactive sync. A commit that lands
code while the catalog still describes the old behavior is exactly the drift
this catalog exists to prevent.
```

If the project has no `CLAUDE.md` yet, **create one** with this section. If it already exists, **append** to it (don't overwrite).

### C7. Show summary

Tell the user:

> Bootstrapped spec catalog with N features across M files.
> Constitution: <auto-filled sections / TBD sections>.
> Mission: <user-provided sections / TBD sections>.
> Roadmap: <N> items in flight (Now/Next/Later); shipped features live in their specs + overview.
> Areas marked PARTIAL: <list>.
> Updated CLAUDE.md to reference the catalog.

## Re-bootstrap (catalog incomplete)

If `docs/overview.md` exists but `constitution.md` or `mission.md` is missing or empty, run only the missing pieces:

1. Skip A5 (specs already exist) and skip C2/C3/C4/C5 unless those files are also missing.
2. Run Phase A for the missing file's domain (tech stack + test runner + design system for constitution; README intro for mission).
3. Run Phase B targeted at the missing sections only.
4. Phase C writes only the missing file + appends a CHANGELOG entry under `### Bootstrapped (partial)`.

Re-bootstrap blocks code changes until the catalog is complete. The "STOP, complete bootstrap first" gate exists because READ mode can't reason about constitution/roadmap conflicts when those files don't exist.

## Common pitfalls

- **Reading too many files.** The cap exists because spec quality drops when you skim too much. Stop at the cap and mark PARTIAL.
- **Inventing invariants from imagination.** If code/tests don't show it, don't claim it.
- **Fabricating constitution or mission content.** Phase B requires user input. `_TBD:` is acceptable; invented principles are not — they propagate to every future session as if they were truth.
- **Writing constitution rules from "common sense".** "No `any` types" sounds reasonable but if the user actually allows `any` in their codebase, that rule will block legitimate work. Ask.
- **Skipping Phase C confirmation.** The user must see constitution + mission before they're written.
- **Forgetting CLAUDE.md.** Without this step, future sessions won't know the catalog exists, and SYNC mode will never get triggered.
- **Bootstrapping a project that already has the catalog.** Check first — if `docs/overview.md` exists AND constitution/mission have content, switch to SYNC mode instead.
