# Plugins

Every plugin is vendored in-repo under `pack/vendor/{start,opt}/` via `git
subtree` — cloning this repository is enough to have every plugin's source
already present, with no plugin-manager download step. The manifest driving
this is `scripts/plugins.tsv` (name, upstream URL, branch, vendor prefix,
load type, trigger); see {doc}`plugin-updates` for the add/update workflow
and what `plugins.lock` records.

Plugins are split between `pack/vendor/start/` (sourced automatically at
startup) and `pack/vendor/opt/` (loaded on demand — a `FileType`
autocommand, a keymap's first press, or an explicit command). A plain
`nvim` with no file argument loads zero `opt` packages. See
{doc}`architecture` for the full reasoning and the list of what triggers
each `opt` plugin.

The table below — generated from `scripts/plugins.tsv` by
`scripts/generate-docs.lua`, identical to `PLUGINS.md` at the repo root —
lists every vendored plugin, its upstream, and its load trigger.

```{include} ../PLUGINS.md
:start-line: 3
```
