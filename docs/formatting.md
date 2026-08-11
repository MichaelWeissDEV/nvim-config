# Formatting

`lua/plugins/formatting.lua` drives conform.nvim entirely from
`languages.registry` (see {doc}`languages`) — nothing about which formatter
runs for which filetype is configured here directly.

## Building `formatters_by_ft`

At startup, for every language with `formatters` entries, each tool id is
checked with `tools.detection.installed()`. Installed formatters go into
`formatters_by_ft[filetype]`; missing ones are recorded separately in an
internal `missing_by_ft` table but **silently left out of
`formatters_by_ft`** — there is no startup warning for a missing
formatter. Two tools have no built-in conform.nvim formatter module
(verified against upstream `conform/formatters/*.lua`) and get a minimal
custom definition instead of being dropped: `google_java_format` and
`dotnet_format`.

## Formatting a buffer

- `<leader>lf` (normal + visual) and `:Format` both call the same
  `format_current()` function.
- If a formatter *is* configured for the current filetype, it runs via
  `conform.format({ async = true, lsp_format = "fallback" })`.
- If none is configured, exactly one notification fires — via
  `util.notify.once`, so it shows once per session per filetype, not on
  every attempt. The exact message, quoted from the code:
  - if formatters exist for the filetype but aren't installed:
    `"No formatter available for %s. Expected: %s."` (filetype, then the
    missing formatters' display names joined with `" or "`)
  - if the language has no formatters registered at all:
    `"No formatter registered for filetype '%s'."`
  Either way, formatting still falls through to
  `conform.format({ timeout_ms = 2000, lsp_format = "fallback", formatters
  = {} })` — an LSP-capable server (jdtls, OmniSharp, ...) can still format
  via `textDocument/formatting` even with zero conform formatters
  configured, so "no conform formatter" doesn't mean "no formatting at
  all".

## Format-on-save

Controlled by `format_on_save`, a function (not a flag) evaluated on every
save: it returns `nil` (skip) if `vim.g.disable_autoformat` or the
buffer-local `vim.b.disable_autoformat` is set, or if no formatter is
configured for that buffer's filetype; otherwise it formats with a
2-second timeout and `lsp_format = "fallback"`.

- `:FormatToggle` — toggle format-on-save for the current buffer only.
  `:FormatToggle!` (bang) toggles it globally instead.
- `:FormatEnable` — force format-on-save back on, both buffer- and
  globally.
- `:FormatDisable` — force it off globally (`vim.g.disable_autoformat =
  true`).

## Inspecting formatter status

`:FormatterStatus` opens a scratch buffer showing the current buffer's
formatter (available or missing, with names) and a full table of every
filetype with either an available or a missing formatter.

## Related

{doc}`lsp` for the `lsp_format = "fallback"` path, {doc}`linting` for the
parallel (but not identical) design used for linters, {doc}`tools` for
installing a missing formatter.
