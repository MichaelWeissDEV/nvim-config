# Commands

Every custom command this config defines goes through `util.command_registry`
(see {doc}`architecture`), so `:NvimCommands` (grouped by category, in a
scratch buffer) and the table below are always in sync — both are produced
from the same registry, the latter by `scripts/generate-docs.lua`.

Commands belonging to a vendored plugin that this config doesn't wrap
(`:Mason`, `:Telescope`, `:TSInstall`, `:Gitsigns`, ...) are registered via
`command_registry.external()` and listed alongside this config's own
commands below — the registry records that they exist and what they're
for (their actual implementation is the plugin's, not redefined here), but
the generated list doesn't visually distinguish them from commands this
config defines itself.

```{include} ../COMMANDS.md
:start-line: 3
```
