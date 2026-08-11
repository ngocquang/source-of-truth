# Sync mode — full guide

Read this file when running SYNC mode (a feature has just shipped or the user wants the catalog updated).

## When SYNC triggers

Completion language ("ship it", "done", "commit this", "xong rồi"), a `superpowers:executing-plans` / `subagent-driven-development` run reporting completion, an explicit sync request ("update the catalog / specs / roadmap"), or the diff is applied and the conversation feels closed. If unsure, ask once: "Sync the catalog now, or keep going?"

## Steps

### 1. Identify what changed

Gather the diff, current commit, and date:

- `git diff --name-only HEAD~1 HEAD` for the last committed change; `git diff --name-only` + `git status` for uncommitted work
- `git rev-parse --short HEAD` for the `Last verified` hash; today's date completes the stamp

Determine which features are affected. Also check if any of these changed (these can trigger constitution surfacing in step 5c):

- `package.json` / `Cargo.toml` / equivalent — new/upgraded/removed dependency
- Test config (`jest.config`, `vitest.config`, `pytest.ini`, etc.)
- Design system imports (new `@radix-ui/*`, swap from `@mui/*` to `@chakra-ui/*`)

### 2. Categorize each change

| Category | Definition | Action |
|---|---|---|
| **New feature** | User-visible capability added | Create `spec-<name>.md` + remove from `Now` once shipped (roadmap holds only unshipped work) + index entry |
| **Modified feature** | Existing feature's behavior or files changed | Update existing spec; if Requirement changed, add a changelog entry |
| **Removed feature** | Feature's entry point deleted | Set `Status: removed` + roadmap update + changelog entry |
| **Renamed feature** | Name changed, functionality preserved | Rename spec file + roadmap entry + changelog entry |
| **Internal refactor** | No feature-level change | Update `Source files` if files moved; do not touch overview/roadmap/changelog |
| **Tech stack change** | Dependency added/upgraded/swapped | Surface to user → update `constitution.md > Tech Stack` + changelog `### Constitution change` only after confirmation |
| **Principle change** | Code Quality / Testing / UX / Performance rule changed | Update `constitution.md` + changelog `### Constitution change` only on **explicit** user request — never infer |

A changelog entry is a per-entry file `docs/changelog/YYYY-MM-DD-<slug>.md` (`constitution` as the slug for constitution changes) — one flat file per (date, feature), so parallel sessions never merge-conflict. For category boundaries (when a change is "Contract changed" vs an internal refactor, when a tech stack edit qualifies as a `### Constitution change`, etc.) and the exact file format → [`changelog-guide.md`](changelog-guide.md). Load it before writing any changelog entry.

If the project still has a single-file `docs/CHANGELOG.md`, surface the migration once (don't migrate silently): "Move `docs/CHANGELOG.md` to `docs/changelog/archive-legacy.md` (frozen) and write new entries as per-file fragments?" See `changelog-guide.md > Legacy migration` for the procedure.

If a single PR touches **multiple features** (e.g., refactor across 5 modules), batch all updates and show the user **one combined diff** at step 7 — don't ask for confirmation per feature.

### 3. Look for design docs / plans (NEW features only)

**The spec IS the PRD.** If a spec already exists for the affected feature, work from the spec — do not go fishing for external PRDs or design docs. The spec's `Plan` + `Requirement` + `Validation` sections are the source of truth; duplicating from an external PRD risks two sources drifting apart.

Only look for external plans when the change introduces a **new feature** (no spec yet) OR when re-establishing context for a feature whose `Source plan` link is empty.

For new features only, check these locations in order:

1. `docs/superpowers/` — superpowers brainstorming + plan output
2. `docs/`, `plans/`, `specs/` (top-level — distinct from `docs/specs/` which is the catalog itself)
3. Recent commit messages — they may reference plan filenames
4. The PR description if available

If a plan exists for a new feature, **read it**. The plan tells intent (feeds the spec's `Plan` section); the diff tells implementation (feeds `Source files` and verifies `Requirement`); tests feed `Validation`. Never write a new spec entry from code alone if a plan is available.

For modified features, work from the existing spec + diff + tests. The original `Plan` section is already the design rationale; update it only if the modification changes the approach (not when implementation details shift).

### 4. Update the spec file(s)

Per the categorization in step 2:

- **New feature**: create `docs/specs/spec-<feature_name>.md` with metadata header + `Plan` + `Requirement` + `Validation`. `Last verified` = today + current short commit hash. Set `Roadmap: shipped (off-roadmap)`.
- **Modified feature**: update existing spec. Update `Plan` if approach changed; update `Requirement > Invariants` if contract changed (and add a changelog entry under `### Contract changed`); update `Validation` if acceptance criteria changed; update `Source files` if files moved. Bump `Last verified`.
- **Removed feature**: set `Status: removed`. Create `docs/changelog/<today>-<slug>.md` with a `### Removed` section. Keep the spec file for one release cycle so AI can see WHY.
- **Renamed feature**: rename `spec-<old>.md` → `spec-<new>.md`, update content, create `docs/changelog/<today>-<new-slug>.md` with a `### Renamed` section, update roadmap link in the same diff.

**Review the spec before showing the diff.** Every spec you newly create here — and every existing spec whose `Requirement` or `Validation` you rewrote — goes through the spec critique gate → [`catalog-format.md`](catalog-format.md): dispatch a fresh-context reviewer on the strongest model available, fold its findings into the spec, then show the step-7 diff. Batch it — one reviewer covering all specs this sync touched, not one per spec. Metadata-only edits (`Source files`, `Last verified`, index links) don't need a review. A finding you can't resolve from code or tests is raised with the user in the step-7 diff message (or written as a `_TBD:_` marker), never as an `Open questions` section — a shipped spec carries none.

### 5. Update sibling docs

#### 5a. `docs/roadmap.md`

Mandatory for new/removed/renamed features — silent drift between code and roadmap defeats the gate. Full lifecycle rules → [`catalog-format.md`](catalog-format.md).

- **Shipped feature**: **remove it from `## Now`** — there is no `Shipped` list; the spec (`Status: active`) + `overview.md` record it.
- **Removed feature**: delete any row it still has in `Now` / `Next` / `Later`; the removal is recorded by spec `Status: removed` + changelog `### Removed` entry.
- **Renamed feature**: update the entry's slug + spec link in place.
- **In-flight work being checkpointed (not shipped yet)**: ask once — "Add this to `## Now` so the roadmap reflects active work?"

#### 5b. `docs/overview.md`

Add/remove/update the one-line entry for any feature that was added, removed, or renamed. **Internal refactors don't touch overview.**

Overview stays a pure index — never add or grow a "Last sync" / sync-history / date-stamp section in it. Freshness lives in each spec's `Last verified` line; history lives in git and the changelog. If a previous session left such a section in `overview.md`, delete it as part of this sync (index drift — no changelog entry needed).

#### 5c. `docs/constitution.md`

Touch ONLY if step 2 flagged a tech stack or principle change AND the user explicitly confirms (tech stack) or explicitly requests (principle). Otherwise leave it — drifting constitution silently is the failure mode this gate prevents.

If a tech stack change is detected from code (new DB dependency added, framework swap) but the user didn't mention updating the constitution, surface it:

> I see Redis was added to dependencies. Update `Constitution > Tech Stack` (and add a changelog entry under `### Constitution change`)? Or is this a temporary experiment?

Let the user confirm. Don't auto-write — experimental dependencies that get ripped out within the week shouldn't pollute the constitution.

#### 5d. `docs/mission.md`

Almost never touched in SYNC. If the user explicitly says "the mission has shifted", "we have new target users", or "value prop changed", run a focused interview (similar to bootstrap Phase B targeted at the specific section) and update + a changelog entry `### Mission change`.

### 6. Extract invariants and validation from code AND tests

For new or modified features:

**Direction check first:** if the feature had a pre-implementation contract — a catalog spec with Validation criteria, or a design plan (see step 3) — that contract is the source of the criteria; tests only verify it. If tests and the contract disagree, surface it to the user — do not rewrite criteria to match what the tests happen to assert. Full direction rule → [`catalog-format.md`](catalog-format.md) (Validation section). The test → criterion extraction below is for BOOTSTRAP and for features that never had a spec or plan.

1. Read the test files first — tests describe contracts AND validation criteria explicitly
2. Read the handler/function code
3. Identify: status codes, error paths, input validation, side effects, time limits → these become `Invariants`
4. Translate each test case into a Given/When/Then or SHALL statement → these become `Validation` criteria
5. **If you can't prove an invariant from code or tests, do not write it.** Vague invariants are worse than missing ones.

**Traceability**: every `Validation` criterion traces back to an `Invariants` bullet and vice-versa — a missing match means the other half is missing (or the invariant isn't verifiable, so rephrase it). Full rule → [`catalog-format.md`](catalog-format.md).

### 7. Show the diff to the user before writing

```
Catalog updates:
- docs/overview.md: + new feature "email-search"
- docs/specs/spec-email-search.md: created (Plan + Requirement + Validation)
- docs/specs/spec-user-search.md: deleted (renamed to email-search)
- docs/roadmap.md: email-search removed from `Now` on ship (roadmap holds only unshipped work)
- docs/changelog/2026-05-09-email-search.md: created (### Renamed entry)
- docs/constitution.md: untouched
- docs/mission.md: untouched
Apply?
```

Wait for confirmation, then write.

For multi-feature changes, show all updates in one diff — don't fragment confirmations.

## Stale spec exception (also relevant in READ mode)

If during SYNC (or READ) you discover that a spec's `Source files` reference paths that no longer exist (file renamed/moved without spec update), don't silently fix — surface to the user:

> Spec `<name>` references `<path>` but the file no longer exists. Update the spec to point to `<new-path>` (likely candidate based on git log)?

This prevents AI from making cascading "corrections" based on stale data. The user confirms; then you update.

To scan for these in bulk, read each `docs/specs/spec-*.md`, pull the paths from its `**Source files**:` line, and confirm each still exists (`test -e <path>`).

## Common pitfalls

- **Updating overview.md for every change.** It's an index — only touch when features are added/removed/renamed, not for every behavior change inside a feature. Never stamp it with "Last sync" notes or sync logs — git and the changelog already record history; delete any such section you find.
- **Auto-updating constitution.** Tech stack changes require user confirmation; principle changes require explicit user request. Silent drift defeats the gate. Surface, don't decide.
- **Skipping the user diff confirmation.** Always show the diff before writing.
- **Writing a spec and shipping it unreviewed.** New specs and rewritten `Requirement` / `Validation` sections go through the critique gate's independent reviewer first — "I just wrote it carefully" is not a substitute for a fresh context reading it.
- **Inventing invariants or validation criteria.** Same rule as Bootstrap — code/tests only. No imagination. If a test was deleted along with the feature it tested, that invariant goes too.
- **Forgetting the changelog.** Removals, renames, contract changes, and constitution changes must always get an entry file in `docs/changelog/`, otherwise future AI won't know if a change was deliberate or forgotten.
- **Forgetting to remove a shipped feature from `Now`.** The roadmap holds only unshipped work and should shrink as you ship; stale `Now` entries make it drift from reality and the "is it tracked?" gate noisy.
- **Letting roadmap entries grow past one line.** An entry is summary + spec link only; when updating the roadmap, move any accumulated detail (acceptance criteria, sub-tasks, rationale) into the spec instead of preserving it.
- **Mixing spec content and Validation criteria with implementation detail.** Validation = caller-visible acceptance criteria. "Uses Redis" is not a validation criterion (it's implementation). "Refresh token rejected on second use" is.
- **Shipping a feature whose spec still carries `Open questions`.** Those were supposed to be resolved at `Next → Now`. Surface to the user: answer each now (fold into Invariants/Validation) or demote to a non-goal — don't delete silently.
