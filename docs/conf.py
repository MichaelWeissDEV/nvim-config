"""Sphinx config for the nvim-config docs. Builds fully offline: no theme or
extension here fetches anything from the network at build time.

Decision: MyST (Markdown) over reStructuredText. The repo already generates
KEYMAPS.md / COMMANDS.md / LANGUAGES.md / TOOLS.md / PLUGINS.md as Markdown
from scripts/generate-docs.lua; writing the rest of the docs in .rst would
mean maintaining two markup languages for one docs site. MyST's
`{include}` directive lets these Sphinx pages pull the generated
root-level .md files in directly -- one data source, not a second copy.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))

project = "nvim-config"
copyright = "2026, Michael Weiss"
author = "Michael Weiss"

extensions = [
    "myst_parser",
    "sphinx_copybutton",
]

source_suffix = {
    ".md": "markdown",
}

myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "attrs_inline",
    "fieldlist",
]

# _generated/ holds the registry-derived reference tables written by
# scripts/generate-docs.lua. They are {include}'d as partials by the real
# pages (keymaps.md, commands.md, ...), so they must NOT also be parsed as
# standalone documents -- otherwise Sphinx reports "document isn't included
# in any toctree" and, under `-W`, fails the build.
exclude_patterns = ["_build", "_generated", "Thumbs.db", ".DS_Store", ".venv"]

# include/literalinclude paths below docs/ need to reach the repo root.
myst_heading_anchors = 3

html_theme = "furo"
html_title = "nvim-config docs"
html_theme_options = {
    "source_repository": "https://github.com/MichaelWeissDEV/nvim-config",
    "source_branch": "main",
    "source_directory": "docs/",
    "light_css_variables": {
        "color-brand-primary": "#1e66f5",
        "color-brand-content": "#1e66f5",
    },
    "dark_css_variables": {
        "color-brand-primary": "#89b4fa",
        "color-brand-content": "#89b4fa",
        "color-background-primary": "#1e1e2e",
        "color-background-secondary": "#181825",
    },
}

html_static_path = []

master_doc = "index"

pygments_style = "friendly"
pygments_dark_style = "monokai"

# Keep local builds strict-friendly: undefined MyST cross-references should
# fail the build (invoked with `sphinx-build -W`), not be silently ignored.
nitpicky = False
