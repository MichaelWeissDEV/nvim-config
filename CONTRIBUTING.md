# Contributing

This is a personal Neovim configuration, but it is structured so that
changes are easy to make correctly — by its author later, or by anyone
who forks it.

The full guide lives in the documentation:
[docs/development.md](docs/development.md) (rendered as the _Development_
page of the Sphinx site). Read [docs/architecture.md](docs/architecture.md)
first for the four registries everything revolves around.

## The short version

**Everything goes through a registry.** Never call `vim.keymap.set()` or
`vim.api.nvim_create_user_command()` directly; use
`util.keymap_registry.map()` / `util.command_registry.command()`. A
mapping registered any other way still works, but silently disappears from
which-key, `:NvimKeymaps`/`:NvimCommands` and the generated docs — the
drift the registries exist to prevent.

**A new language is one data file** (`lua/languages/<id>.lua`) plus its id
in `LANGUAGE_IDS`. Every tool it references must already exist in
`lua/tools/registry.lua`; never invent a tool id in a language file.

**Regenerate the docs after any registry change:**

```bash
./scripts/docs-build.sh
```

This rewrites `docs/_generated/*.md` and `doc/nvim-config.txt` from the
registries and rebuilds the Sphinx site. Committing a registry change
without regenerating leaves the docs stale.

## Before opening a pull request

```bash
stylua --check lua/ after/ scripts/*.lua tests/*.lua   # formatting
bash tests/run.sh                                      # full headless suite
( cd docs && .venv/bin/sphinx-build -W -b html . _build/html )   # docs build
```

All three also run in CI (`.github/workflows/ci.yml`), so a PR that breaks
any of them will fail there.

## Publishing the docs on Read the Docs

The repository is already configured for it — `/.readthedocs.yaml` and
`docs/requirements.txt` are committed, and so is `docs/_generated/`,
which is what makes a hosted build possible at all (the Read the Docs
builder has no Neovim and therefore can never run
`scripts/generate-docs.lua` itself).

One-time setup: sign in at [readthedocs.org](https://readthedocs.org) with
the GitHub account, _Import a Project_, pick this repository, and accept
the defaults — the config file is detected automatically. Builds then run
on every push to `main`. `fail_on_warning: true` is set, matching the
local `-W` build and CI, so a docs regression fails the hosted build
rather than publishing something broken.

If the project slug you choose is not `nvim-config`, update the docs badge
and its link at the top of [README.md](README.md) to match.

### Versioned documentation

Read the Docs builds `latest` from `main`. To also publish a stable,
tagged version:

1. Push a tag (see _Releasing_ below). Read the Docs detects tags as
   versions automatically.
2. In the project's _Versions_ page, activate the tag you want published.
3. Optionally set that version as the project default, so
   `nvim-config.readthedocs.io` lands on the stable docs instead of
   `latest`.

This matters more here than for most projects: because plugins are
vendored, a tag pins the configuration *and* the exact plugin versions, so
the documentation for a tag genuinely describes what that checkout does.

## Releasing

```bash
# 1. Move the entries under "Unreleased" into a new version section in
#    CHANGELOG.md, with today's date, and update the link definitions
#    at the bottom of that file.
# 2. Make sure everything is green (see "Before opening a pull request").
# 3. Tag and push.
git tag -a v0.2.0 -m "v0.2.0"
git push origin v0.2.0
```

Then create the GitHub release from that tag, using the changelog section
as its body. Versions follow [Semantic Versioning](https://semver.org/):
breaking changes to keymaps, command names or the registry schemas are a
major bump; new languages, tools or plugins are a minor bump; fixes are a
patch.

## Standards this repository holds itself to

- **No downloads at startup.** Plugins are vendored via `git subtree`;
  nothing in `init.lua` or anything it requires may perform a network
  operation. Online actions are explicit commands only.
- **Quiet on missing optional tools.** A missing formatter/linter/LSP/
  debugger must never produce a startup warning or a repeated
  notification — at most one message, and only when the user actually
  invokes the feature. Real configuration errors stay loud.
- **Verify, don't assume.** Claims about a tool's CLI, a plugin's API or a
  Mason package name belong in the repository only after they have been
  checked against the actual thing. Several bugs in this repo's history
  were exactly assumptions that looked reasonable and were wrong.
- **Comments explain why, not what.** Don't restate the line below.
