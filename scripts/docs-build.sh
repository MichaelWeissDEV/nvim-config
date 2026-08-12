#!/usr/bin/env bash
# Regenerate the registry-derived docs, then build the full local Sphinx
# site. Network is only needed once, the first time, to create docs/.venv
# and install Sphinx/myst-parser into it -- everything after that is local.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Regenerating docs/_generated/*.md and doc/nvim-config.txt from the registries"
nvim --headless -u init.lua -l scripts/generate-docs.lua

echo "==> Refreshing :help tags"
nvim --headless -c "helptags $repo_root/doc" -c "qa"

if [ ! -x docs/.venv/bin/sphinx-build ]; then
  echo "==> Creating docs/.venv and installing Sphinx (one-time, needs network)"
  python3 -m venv docs/.venv
  docs/.venv/bin/pip install -q --upgrade pip
  # Version range kept in sync with pyproject.toml's [project.optional-dependencies].docs
  docs/.venv/bin/pip install -q "sphinx>=8.0,<9" "myst-parser>=4.0,<5" "sphinx-rtd-theme>=3.0,<4"
fi

echo "==> Building Sphinx HTML (docs/_build/html)"
( cd docs && SPHINXBUILD=.venv/bin/sphinx-build make html )

echo "==> Done: docs/_build/html/index.html"
