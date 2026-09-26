# Privacy Policy

Effective date: 2026-09-26

source-of-truth is a skill: Markdown instructions that your coding agent (Claude Code, Codex, Cursor, and others) reads and follows. It has no server, makes no network calls, and contains no telemetry or analytics.

## What the plugin collects

Nothing. The plugin sends no data anywhere, and its author receives no data about you, your project, or your usage.

## What the plugin reads

While following the skill, your agent reads files in your project: the `docs/` catalog, the source files and git diff relevant to the change, plan documents, and the README. These reads happen inside your agent session. How your agent provider handles that session is governed by the provider's own privacy policy — for Claude, [Anthropic's Privacy Policy](https://www.anthropic.com/legal/privacy).

## What the plugin writes

Only files in your project:

- the `docs/` catalog (overview, constitution, mission, roadmap, specs, changelog, decisions, debugging records)
- during bootstrap, after you confirm: a catalog section in `CLAUDE.md`, with `AGENTS.md` symlinked to it

It also has your agent create a git worktree for each change. Nothing is written outside your project.

## Retention

The plugin keeps no data. The files it writes stay in your repository until you delete them.

## Contact

Questions about this policy: ngocquangbb@gmail.com, or open an issue at [github.com/ngocquang/source-of-truth](https://github.com/ngocquang/source-of-truth/issues).

## Changes

Changes to this policy are published in this file with a new effective date.
