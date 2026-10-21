# Python

Python is set up as a complete IDE environment around Astral's tools:
**ty** for types and navigation, **ruff** for linting, quick fixes,
import sorting and formatting, **debugpy** for debugging, and **pytest**
run from the editor. Everything is defined in `lua/languages/python.lua`.
The shared logic (virtualenv discovery, server choice, test ids) lives in
`lua/util/python.lua`, and the commands in `lua/ide/python.lua`.

## From `git clone` to a working Python IDE

```vim
:LangInstall python
```

Run this once, in any buffer (or press `<leader>tl` in a Python buffer).
It installs `ty`, `ruff` and `debugpy` through Mason, plus the `python`
Tree-sitter parser. If the `tree-sitter` CLI that builds parsers is
missing, it is installed through Mason first. Everything runs in the
background, and buffers that are already open pick up the new servers
without `:e`. `./scripts/bootstrap.sh python` does the same from a shell.
The `python` bootstrap profile also installs basedpyright.

Your project's own packages come from its virtualenv. See
[Interpreter and virtualenv](#interpreter-and-virtualenv) for how it is
found. Most of the time you don't need to activate anything.

## Language servers

| Server | Role | When it runs |
|---|---|---|
| **ty** (`ty server`) | types, go to definition/references/implementation, rename, hover, completion, signature help, inlay hints, call hierarchy, workspace symbols | default |
| **ruff** (`ruff server`) | lint diagnostics, quick fixes, "fix all", organize imports | always, alongside the type checker |
| **basedpyright** | the same role as ty | opt-in alternative (see below) |

Ruff's diagnostics come from its language server, **not** from nvim-lint,
so no problem is reported twice. Ruff's hover is switched off on attach:
it only explains `# noqa` codes, and it would add an empty section to
every `K` popup. Both servers read their configuration from the project
(`pyproject.toml`, `ruff.toml`, `ty.toml`), as on the command line and
in CI.

### Choosing the type checker

| `vim.g.nvim_config_python_lsp` | Runs |
|---|---|
| `"ty"` (default) | ty + ruff. Falls back to basedpyright when only basedpyright is installed, so an older setup keeps go-to-definition. |
| `"basedpyright"` | basedpyright + ruff |
| `"both"` | ty + basedpyright + ruff. Expect two sets of type diagnostics. |

You can set the choice in two ways:

- For the session: `:PythonLsp basedpyright`. Servers that are no longer
  chosen are stopped, and the chosen ones attach to open buffers right
  away.
- Permanently: put `vim.g.nvim_config_python_lsp = "basedpyright"` in
  `lua/config/local.lua` (see {doc}`installation`).

`:PythonLsp` with no argument shows the current choice.

When basedpyright runs, its own organize-imports is turned off (ruff owns
that), and it is pointed at the project's virtualenv.

## Interpreter and virtualenv

Running, testing and debugging all use the same interpreter, resolved in
this order:

1. `$VIRTUAL_ENV`, if a virtualenv is activated.
2. A **project-local** `.venv/` or `venv/`, found by walking up from the
   file to the project root. Nothing above the root is used, so a stray
   `~/venv` is never picked up.
3. `$CONDA_PREFIX`, if a conda env is activated.
4. `python3` / `python` on `PATH`.

The project root is the nearest directory containing `pyproject.toml`,
`uv.lock`, `setup.py`, `setup.cfg`, `requirements.txt`, `Pipfile`,
`ty.toml`, `ruff.toml`, `pyrightconfig.json` or `.git`. ty discovers the
same `.venv` by itself.

The statusline shows the virtualenv's directory name, e.g. `(.venv)`.
`:PythonInfo` (`<leader>cv`) shows the full picture:

- the interpreter and where it was found
- the project root
- the type checker choice
- which servers are installed and which are attached

## Keys in a Python buffer

| Key | Action |
|---|---|
| `<leader>cr` | Run the current file in a terminal split |
| `<leader>ct` | pytest: current file |
| `<leader>cT` | pytest: the test under the cursor (`file::Class::test`) |
| `<leader>cA` | pytest: whole project |
| `<leader>co` | Organize imports (ruff) |
| `<leader>cF` | Fix every auto-fixable problem (ruff) |
| `<leader>cv` | `:PythonInfo` |
| `<leader>lf` | Format (ruff format; also runs on save) |

On top of these come the general LSP keys from {doc}`lsp`: `gd`, `gr`,
`gi`, `gy`, `K`, `<leader>lr` (rename), `<leader>la` (code action) and the
rest.

## pytest

```vim
:Pytest file          " current file (the default)
:Pytest nearest -x    " test under the cursor, extra args passed to pytest
:Pytest all
:Pytest last          " repeat the previous run
```

pytest runs as `<interpreter> -m pytest` from the project root, in a
terminal split. The interpreter is the resolved one from above, so the
project's own pytest and plugins are used. The test under the cursor is
found with Tree-sitter when the `python` parser is installed. Without it,
a text search finds the enclosing `def test…` and its `class Test…`.

## Debugging

`<leader>db` sets a breakpoint and `<leader>dc` starts debugging (see
{doc}`debugging`). There are three launch configurations:

- **Launch file**: runs the current file.
- **Launch file with arguments**: prompts for the arguments first.
- **pytest: current file**: runs the current test file under pytest.

All three run under the resolved project interpreter, not under the
interpreter that Mason installed debugpy into. That interpreter cannot
import the project's dependencies.
