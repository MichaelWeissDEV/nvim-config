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
copyright = "nvim-config contributors"
author = "nvim-config contributors"

extensions = [
    "myst_parser",
]

source_suffix = {
    ".md": "markdown",
}

myst_enable_extensions = [
    "colon_fence",
]

exclude_patterns = ["_build", "Thumbs.db", ".DS_Store", ".venv"]

# include/literalinclude paths below docs/ need to reach the repo root.
myst_heading_anchors = 3

html_theme = "alabaster"
html_static_path = []

master_doc = "index"

# Keep local builds strict-friendly: undefined MyST cross-references should
# fail the build (invoked with `sphinx-build -W`), not be silently ignored.
nitpicky = False
