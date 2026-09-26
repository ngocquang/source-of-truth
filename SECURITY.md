# Security Policy

## Supported versions

Only the latest release — the `version` in `.claude-plugin/plugin.json` on `main` — receives fixes.

## Reporting a vulnerability

Do not open a public issue. Email **ngocquangbb@gmail.com** with the subject `source-of-truth security` and include:

- the plugin version and the agent you ran it in
- the prompt or steps that reproduce the problem
- what happened, and what you expected instead

Every report is investigated. Confirmed issues are fixed in a new release.

## Scope

The plugin is Markdown instructions plus small loader files for other agents (`.opencode/`, `.pi/`). Relevant reports include instructions that lead an agent to act beyond what the README describes: running unexpected commands, touching files outside the project, or sending data anywhere.
