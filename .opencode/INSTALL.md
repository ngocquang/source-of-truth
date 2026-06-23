# Installing Source of Truth for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add the plugin to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["source-of-truth@git+https://github.com/ngocquang/source-of-truth.git"]
}
```

Restart OpenCode. The plugin registers the `source-of-truth` skill through
OpenCode's plugin manager.

Verify by asking: "What skills do you have?" — `source-of-truth` should appear.

OpenCode uses its own plugin install. If you also use Claude Code, Codex, or
another harness, install Source of Truth separately for each one.

## Usage

The skill activates automatically when a task touches a `docs/` spec catalog.
You can also drive it explicitly with OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load source-of-truth
```

To bootstrap a catalog in a project that doesn't have one yet, ask:
"Set up the source-of-truth catalog for this project."

## Updating

OpenCode installs the plugin through a git-backed package spec. Some OpenCode
and Bun versions pin the resolved git dependency in a lockfile or cache, so a
restart may not pick up the newest commit. If updates don't appear, clear
OpenCode's package cache or reinstall the plugin.

To pin a specific version:

```json
{
  "plugin": ["source-of-truth@git+https://github.com/ngocquang/source-of-truth.git#v1.0.0"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i source-of-truth`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Skill not found

1. Use the `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)

## Getting Help

- Report issues: https://github.com/ngocquang/source-of-truth/issues
