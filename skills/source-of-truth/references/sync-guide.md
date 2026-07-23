# Sync mode — full guide

Read this file when running SYNC mode (a feature has just shipped or the user wants the catalog updated).

## When SYNC triggers

- User says "ship it", "done", "commit this", "let's merge", "ok ship", "xong rồi", or similar completion language
- A `superpowers:executing-plans` run reports completion
- A `superpowers:subagent-driven-development` workflow finishes
- User explicitly asks: "update the catalog", "update specs", "sync docs", "sync specs", "update roadmap"
- Diff has been applied AND conversation feels closed (tests pass, user signals satisfaction)

If you're not sure whether SYNC has triggered, ask once: "Sync the catalog now, or keep going?"

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
| **Modified feature** | Existing feature's behavior or files changed | Update existing spec; if Requirement changed, log in CHANGELOG |
| **Removed feature** | Feature's entry point deleted | Set `Status: removed` + roadmap update + CHANGELOG entry |
| **Renamed feature** | Name changed, functionality preserved | Rename spec file + roadmap entry + CHANGELOG entry |
| **Internal refactor** | No feature-level change | Update `Source files` if files moved; do not touch overview/roadmap/CHANGELOG |
| **Tech stack change** | Dependency added/upgraded/swapped | Surface to user → update `constitution.md > Tech Stack` + CHANGELOG `### Constitution change` only after confirmation |
| **Principle change** | Code Quality / Testing / UX / Performance rule changed | Update `constitution.md` + CHANGELOG `### Constitution change` only on **explicit** user request — never infer |

For category boundaries (when a change is "Contract changed" vs an internal refactor, when a tech stack edit qualifies as a `### Constitution change`, etc.) → [`changelog-guide.md`](changelog-guide.md). Load it before writing any CHANGELOG entry.

If `docs/CHANGELOG.md` is approaching ~500 lines or spans ≥6 months of entries, surface the archive option to the user (don't auto-split): "CHANGELOG.md is <N> lines spanning <M> months. Archive past months to `docs/changelog/`?" See `changelog-guide.md > Archive policy` for the full split procedure.

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
- **Modified feature**: update existing spec. Update `Plan` if approach changed; update `Requirement > Invariants` if contract changed (and log in CHANGELOG); update `Validation` if acceptance criteria changed; update `Source files` if files moved. Bump `Last verified`.
- **Removed feature**: set `Status: removed`. Add CHANGELOG entry under `### Removed`. Keep the file for one release cycle so AI can see WHY.
- **Renamed feature**: rename `spec-<old>.md` → `spec-<new>.md`, update content, add CHANGELOG entry under `### Renamed`, update roadmap link in the same diff.

### 5. Update sibling docs

#### 5a. `docs/roadmap.md`

This is mandatory for new/removed/renamed features — silent drift between code and roadmap defeats the gate.

- **New feature**: it leaves the roadmap on ship — **remove it from `## Now`** if it was there. There is no `Shipped` list; the spec (`Status: active`) + `overview.md` record it.
- **Removed feature**: it is already off the roadmap; if it still sits in `Now` / `Next` / `Later`, delete that row. The removal itself is recorded by the spec `Status: removed` + CHANGELOG `### Removed`.
- **Renamed feature**: update the entry's slug + spec link in the same group it was in.
- **In-flight work being checkpointed (not shipped yet)**: ask once — "Add this to `## Now` so the roadmap reflects active work?"

#### 5b. `docs/overview.md`

Add/remove/update the one-line entry for any feature that was added, removed, or renamed. **Internal refactors don't touch overview.**

Overview stays a pure index — never add or grow a "Last sync" / sync-history / date-stamp section in it. Freshness lives in each spec's `Last verified` line; history lives in git and CHANGELOG. If a previous session left such a section in `overview.md`, delete it as part of this sync (index drift — no CHANGELOG entry needed).

#### 5c. `docs/constitution.md`

Touch ONLY if step 2 flagged a tech stack or principle change AND the user explicitly confirms (tech stack) or explicitly requests (principle). Otherwise leave it — drifting constitution silently is the failure mode this gate prevents.

If a tech stack change is detected from code (new DB dependency added, framework swap) but the user didn't mention updating the constitution, surface it:

> I see Redis was added to dependencies. Update `Constitution > Tech Stack` (and add CHANGELOG entry under `### Constitution change`)? Or is this a temporary experiment?

Let the user confirm. Don't auto-write — experimental dependencies that get ripped out within the week shouldn't pollute the constitution.

#### 5d. `docs/mission.md`

Almost never touched in SYNC. If the user explicitly says "the mission has shifted", "we have new target users", or "value prop changed", run a focused interview (similar to bootstrap Phase B targeted at the specific section) and update + CHANGELOG `### Mission change`.

### 6. Extract invariants and validation from code AND tests

For new or modified features:

**Direction check first:** if the feature had a pre-implementation contract — a catalog spec with Validation criteria, or a design plan (e.g., superpowers output, see step 3) — that contract is the source of the criteria: verify each criterion has a covering test and each new test traces back to a criterion. Do not rewrite criteria to match what the tests happen to assert; if tests and the contract disagree, surface it to the user (either the implementation missed the contract, or the contract legitimately changed → CHANGELOG `### Contract changed`). The test → criterion extraction below is for BOOTSTRAP and for features that never had a spec or plan.

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
- docs/CHANGELOG.md: + rename entry under 2026-05-09
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

- **Reading the entire codebase.** SYNC reads only the diff + relevant spec files. Stay focused.
- **Updating overview.md for every change.** It's an index — only touch when features are added/removed/renamed, not for every behavior change inside a feature. Never stamp it with "Last sync" notes or sync logs — git and CHANGELOG already record history; delete any such section you find.
- **Auto-updating constitution.** Tech stack changes require user confirmation; principle changes require explicit user request. Silent drift defeats the gate. Surface, don't decide.
- **Skipping the user diff confirmation.** Always show the diff before writing.
- **Inventing invariants or validation criteria.** Same rule as Bootstrap — code/tests only. No imagination. If a test was deleted along with the feature it tested, that invariant goes too.
- **Forgetting CHANGELOG.** Removals, renames, contract changes, and constitution changes must always go in CHANGELOG, otherwise future AI won't know if a change was deliberate or forgotten.
- **Forgetting to remove a shipped feature from `Now`.** The roadmap holds only unshipped work and should shrink as you ship; stale `Now` entries make it drift from reality and the "is it tracked?" gate noisy.
- **Letting roadmap entries grow past one line.** An entry is summary + spec link only; when updating the roadmap, move any accumulated detail (acceptance criteria, sub-tasks, rationale) into the spec instead of preserving it.
- **Mixing spec content and Validation criteria with implementation detail.** Validation = caller-visible acceptance criteria. "Uses Redis" is not a validation criterion (it's implementation). "Refresh token rejected on second use" is.
- **Shipping a feature whose spec still carries `Open questions`.** Those were supposed to be resolved at `Next → Now`. Surface to the user: answer each now (fold into Invariants/Validation) or demote to a non-goal — don't delete silently.
