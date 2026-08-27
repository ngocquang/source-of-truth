---
name: no-comments
description: "Use in exactly two situations: the source-of-truth SYNC / commit gate is running its comment sweep on a diff, or the user explicitly asks to strip comments, remove narration, clean up commented-out code, or audit lint/type suppressions. Never invoke it on your own after writing or reviewing code — writing code is not a trigger."
---

# No comments

**Invoked, never volunteered.** This skill runs only when SYNC's comment sweep gate calls it, or when the user asks for it by name. Finishing a code change is not a reason to reach for it — an unrequested sweep rewrites code the user never asked you to touch.

An independent reviewer judges the comments; you act on what survives the audit.

**The agent that wrote the comment is the worst judge of it.** Authoring agents defend their own narration — "this one is genuinely helpful", "I'll keep it for the next reader". Defer to the reviewer's fresh perspective. Your job is to catch its mistakes against the exception list, not to re-argue the comments you wrote.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch (default `main`), including the working tree. Never widen the scope mid-run.

## Dispatch the reviewer

Run it in a **fresh context** that has not seen this conversation:

| Runtime | How |
|---|---|
| Claude Code (this plugin installed) | `Agent` with `subagent_type: "Comment Sicko"` |
| Any runtime with subagents | Fresh agent seeded with [`../../agents/comment-sicko.md`](../../agents/comment-sicko.md) |
| No subagents available | Apply that file's rules yourself in a separate pass, reading only the scope — and say in the report that no fresh context was used |

Pass the scope. Do not restate its rules; the agent file carries them.

## Steps

1. **Dispatch** the reviewer with the scope.
2. **Audit its report and diff.** Reject application-code edits, scope escapes, exception-protected deletions, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty. Reshape flags on our-code surprises stay actionable. Do not restore those comments. A keep survives only with proof it is about something we cannot change. Audit missed scoped lint and TypeScript suppressions — correctness or safety suppressions stay actionable `MUST KILL`s. Restore a deletion only with an exact exception and scoped proof. Before accepting a thin `IMPORTANT` or `do not remove` kill or keep, read the named symbol and trace its callers. **If a kill is ambiguous, do not restore. If a keep is refuted or still ambiguous, delete it.** Revert and rerun one rejected report with the failure named; reject a second, report it open, and fail the skill.
3. **Fix trivial accepted flags directly** — delete a dead path, drop a parameter, use the real API. If any fix needs a shape, sketch the shape for the whole accepted set and the surrounding code first, then stop at the sketch. Shape, then implement — never freehand a fix into a shape you haven't drawn.
4. **Implement the smallest root-cause fix in scope.** Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Intent: fix real causes, redesign as if the requirements had always existed, never bolt on symptom guards. None of that authorizes widening the fence or fixing instances outside it.
5. **Handle constraint comments** — `do not remove`, `do not change wording`, `talk to X before changing`. Leave keeps about things we cannot change. For the rest, offer the cheapest in-scope encoding: a type, a runtime check, a test, or a CI lint. Wait for interactive approval; unattended and eval runs need caller pre-approval. If approved, encode then delete. Otherwise delete, report the constraint open, and sketch the out-of-scope work.
6. **Report**: deletion count, restored comments, reruns, any shape sketch, fixes, encoding offers, encodings landed, unenforced constraints, and other open work.

## Red flags — you are rationalizing

| Thought | Reality |
|---|---|
| "This comment explains something subtle" | Subtle in *our* code is a rename/extract/type, not prose. Reshape it. |
| "It's only a suppression, the rule is noisy" | Look the rule up. Correctness and safety rules stay; only style-only rules justify a suppression. |
| "The reviewer missed the context I have" | It read the code. Context you can't point at in the code is the confession the comment was hiding. |
| "I'll keep it, deleting feels risky" | Ambiguity deletes. A keep needs proof about something we cannot change. |
| "While I'm here I'll also fix that other file" | Out of scope. Report it open. |
| "I just wrote code, I should sweep it" | Not a trigger. SYNC calls this skill, or the user does. |
| "I'll skip the fresh context, I know these comments" | You wrote them. That is the whole reason a fresh context is required. |

## Common mistakes

- **Letting the reviewer write application code.** It flags; you fix. A report containing app-code edits is rejected, not merged.
- **Polishing a comment instead of deleting it.** A shorter alibi is still an alibi.
- **Deleting a constraint comment without offering the encoding.** The constraint outlives the comment — encode it or report it open.
- **Reporting a clean sweep after skipping the audit in step 2.** The reviewer is deliberately extreme; an unaudited apply is how a license header or an API doc contract dies.
