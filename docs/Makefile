# Minimal Sphinx Makefile. Uses docs/.venv if present (see
# scripts/docs-build.sh), else falls back to whatever `sphinx-build` is on
# PATH.

SPHINXOPTS    ?= -W
SPHINXBUILD   ?= $(if $(wildcard .venv/bin/sphinx-build),.venv/bin/sphinx-build,sphinx-build)
SOURCEDIR     = .
BUILDDIR      = _build

.PHONY: help html clean
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

html:
	@$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS) $(O)

clean:
	rm -rf "$(BUILDDIR)"

%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
