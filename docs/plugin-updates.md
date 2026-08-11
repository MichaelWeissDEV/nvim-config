# Plugin Updates

There is no plugin manager here — see {doc}`architecture` for why. Plugins
are vendored with `git subtree`, driven by a handful of maintainer-only
scripts under `scripts/`. None of these run automatically; `nvim` itself
never invokes any of them.

## The manifest: `scripts/plugins.tsv`

Tab-separated, one row per plugin:

```
name    url    branch    prefix    load_type    trigger
```

`prefix` is the vendor path (`pack/vendor/start/<name>` or
`pack/vendor/opt/<name>`), `load_type` is `start` or `opt`, and `trigger`
is a free-text note on what loads it (used for `PLUGINS.md` generation,
not read by any script logic).

## Adding a new plugin

```bash
scripts/plugin-add.sh <plugin-name>
```

`<plugin-name>` must already exist as a row in `scripts/plugins.tsv` —
add the row by hand first. The script then:

1. Refuses to run if `<prefix>` already exists, or if the working tree
   isn't clean (`git subtree` requires a clean tree).
2. Runs `git subtree add --prefix=<prefix> <url> <branch> --squash`.
3. Records the plugin in `plugins.lock` via `plugin-status.sh --record`,
   resolving the current upstream SHA with `git ls-remote`.
4. Commits `plugins.lock` in a separate commit.

## Updating a plugin

```bash
scripts/plugin-update.sh <plugin-name>          # one plugin
scripts/plugin-update-all.sh                     # every vendored plugin
```

`plugin-update.sh` runs `git subtree pull --prefix=<prefix> <url> <branch>
--squash`, then re-records the new SHA in `plugins.lock` the same way
`plugin-add.sh` does. `plugin-update-all.sh` just iterates every row in
`scripts/plugins.tsv`, calling `plugin-update.sh` for each one that's
already vendored (and skipping, with a message, any that aren't yet).

## Checking status

```bash
scripts/plugin-status.sh
```

Offline, no network: prints a table of every plugin in the manifest, its
load type, and whether its vendor directory is present (`vendored`) or
`MISSING`. The same script, called with `--record ...` (six positional
args: name, url, branch, prefix, load_type, sha), is also the sole writer
of `plugins.lock` — used internally by `plugin-add.sh`/`plugin-update.sh`,
not meant to be called with `--record` by hand.

## Why `plugins.lock`

`plugins.lock` is a second tab-separated file, one row per *vendored*
plugin, recording the exact upstream commit SHA it was vendored at (plus
url/branch/prefix/load_type) — `scripts/plugins.tsv` says what should be
vendored, `plugins.lock` says what SHA actually is. This is what makes the
vendoring reproducible: it's a record of exactly which commit produced the
code currently sitting in `pack/vendor/`, independent of whatever the
upstream branch has moved to since.

## Why `--squash`

Every `git subtree add`/`pull` in these scripts passes `--squash`. Without
it, each vendored plugin would bring its own full upstream commit history
into this repository's history — for dozens of plugins, that's a lot of
unrelated history bloating `git log`/`git blame` here. `--squash` collapses
each vendor operation into a single commit against the plugin's
subdirectory, so this repo's own history stays about *this* repo.
