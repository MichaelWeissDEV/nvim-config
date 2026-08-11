-- Canonical metadata for every external tool this config knows how to use:
-- language servers, formatters, linters, debug adapters. Language modules
-- (lua/languages/*.lua) reference tools by `id` only -- they never repeat
-- an executable or mason package name. This is the one place that changes
-- if a tool is renamed upstream.
--
-- @class ToolSpec
--   id        string   stable id, referenced from languages/*.lua
--   name      string   display name
--   category  "lsp"|"formatter"|"linter"|"debugger"
--   exe       string|string[]  binary/binaries checked via executable.exists
--   mason     string|nil  mason.nvim package name, nil if not mason-installable
--   profiles  string[]  bootstrap profile bundles this belongs to
--   note      string|nil  short caveat shown in docs/health output

---@type table<string, table>
local tools = {}

local function add(spec)
  assert(tools[spec.id] == nil, "duplicate tool id: " .. spec.id)
  tools[spec.id] = spec
end

-- Lua ---------------------------------------------------------------------
add({
  id = "lua_ls",
  name = "lua-language-server",
  category = "lsp",
  exe = "lua-language-server",
  mason = "lua-language-server",
  profiles = { "core" },
})
add({ id = "stylua", name = "StyLua", category = "formatter", exe = "stylua", mason = "stylua", profiles = { "core" } })
add({
  id = "selene",
  name = "selene",
  category = "linter",
  exe = "selene",
  mason = "selene",
  profiles = { "core" },
  note = "optional; lua_ls diagnostics cover most cases",
})

-- Python --------------------------------------------------------------------
add({
  id = "basedpyright",
  name = "basedpyright",
  category = "lsp",
  exe = "basedpyright-langserver",
  mason = "basedpyright",
  profiles = { "python" },
})
add({ id = "ruff", name = "ruff", category = "linter", exe = "ruff", mason = "ruff", profiles = { "python" } })
add({
  id = "ruff_format",
  name = "ruff format",
  category = "formatter",
  exe = "ruff",
  mason = "ruff",
  profiles = { "python" },
})
add({
  id = "ty",
  name = "ty",
  category = "lsp",
  exe = "ty",
  mason = "ty",
  profiles = { "python" },
  note = "Astral's fast Rust-based type checker/LSP; still pre-1.0 and evolving quickly. "
    .. "Runs alongside basedpyright as a second LSP client for python (see languages/python.lua's "
    .. "extra_lsp), not as a replacement -- disable it by removing that entry if it's too noisy.",
})
add({
  id = "debugpy",
  name = "debugpy",
  category = "debugger",
  exe = "debugpy-adapter",
  mason = "debugpy",
  profiles = { "python" },
})

-- Ruby ------------------------------------------------------------------
add({
  id = "ruby_lsp",
  name = "ruby-lsp",
  category = "lsp",
  exe = "ruby-lsp",
  mason = "ruby-lsp",
  profiles = { "scripting" },
})
add({
  id = "rubocop",
  name = "rubocop",
  category = "formatter",
  exe = "rubocop",
  mason = "rubocop",
  profiles = { "scripting" },
})
add({
  id = "rubocop_lint",
  name = "rubocop (lint)",
  category = "linter",
  exe = "rubocop",
  mason = "rubocop",
  profiles = { "scripting" },
})
add({
  id = "rdbg",
  name = "debug.gem / rdbg",
  category = "debugger",
  exe = "rdbg",
  mason = nil,
  profiles = { "scripting" },
  note = "install via: gem install debug",
})

-- Go ------------------------------------------------------------------------
add({ id = "gopls", name = "gopls", category = "lsp", exe = "gopls", mason = "gopls", profiles = { "systems" } })
add({
  id = "gofumpt",
  name = "gofumpt",
  category = "formatter",
  exe = "gofumpt",
  mason = "gofumpt",
  profiles = { "systems" },
})
add({
  id = "golangci_lint",
  name = "golangci-lint",
  category = "linter",
  exe = "golangci-lint",
  mason = "golangci-lint",
  profiles = { "systems" },
  note = "optional",
})
add({ id = "delve", name = "delve", category = "debugger", exe = "dlv", mason = "delve", profiles = { "systems" } })

-- Rust ------------------------------------------------------------------
add({
  id = "rust_analyzer",
  name = "rust-analyzer",
  category = "lsp",
  exe = "rust-analyzer",
  mason = "rust-analyzer",
  profiles = { "systems" },
})
add({
  id = "rustfmt",
  name = "rustfmt",
  category = "formatter",
  exe = "rustfmt",
  mason = nil,
  profiles = { "systems" },
  note = "ships with rustup",
})
add({
  id = "clippy",
  name = "clippy",
  category = "linter",
  exe = "cargo-clippy",
  mason = nil,
  profiles = { "systems" },
  note = "ships with rustup; run on-demand, not on every keypress",
})
add({
  id = "codelldb",
  name = "CodeLLDB",
  category = "debugger",
  exe = "codelldb",
  mason = "codelldb",
  profiles = { "systems" },
})

-- C / C++ -----------------------------------------------------------------
add({ id = "clangd", name = "clangd", category = "lsp", exe = "clangd", mason = "clangd", profiles = { "systems" } })
add({
  id = "clang_format",
  name = "clang-format",
  category = "formatter",
  exe = "clang-format",
  mason = "clang-format",
  profiles = { "systems" },
})
add({
  id = "clang_tidy",
  name = "clang-tidy",
  category = "linter",
  exe = "clang-tidy",
  -- No standalone Mason package exists for clang-tidy (confirmed against
  -- the live mason-registry: only clang-format and clangd are listed) --
  -- it ships with the LLVM/clang toolchain itself, same as clang-format's
  -- system install would if you're not using Mason's prebuilt binary.
  mason = nil,
  profiles = { "systems" },
  note = "optional; ships with LLVM -- macOS: brew install llvm | Debian/Ubuntu: apt install clang-tidy | Arch: pacman -S clang",
})
add({
  id = "gdb",
  name = "gdb",
  category = "debugger",
  exe = "gdb",
  mason = nil,
  profiles = { "systems" },
  note = "fallback debugger if codelldb unavailable",
})

-- Assembly ------------------------------------------------------------------
add({ id = "asm_lsp", name = "asm-lsp", category = "lsp", exe = "asm-lsp", mason = "asm-lsp", profiles = { "systems" } })

-- Java / Kotlin ---------------------------------------------------------
add({ id = "jdtls", name = "jdtls", category = "lsp", exe = "jdtls", mason = "jdtls", profiles = { "jvm" } })
add({
  id = "google_java_format",
  name = "google-java-format",
  category = "formatter",
  exe = "google-java-format",
  mason = "google-java-format",
  profiles = { "jvm" },
})
add({
  id = "java_debug",
  name = "java-debug-adapter",
  category = "debugger",
  exe = nil,
  mason = "java-debug-adapter",
  profiles = { "jvm" },
  note = "driven through jdtls, no standalone binary check",
})
add({
  id = "kotlin_language_server",
  name = "kotlin-language-server",
  category = "lsp",
  exe = "kotlin-language-server",
  mason = "kotlin-language-server",
  profiles = { "jvm" },
})
add({ id = "ktlint", name = "ktlint", category = "formatter", exe = "ktlint", mason = "ktlint", profiles = { "jvm" } })

-- JS / TS / Web -----------------------------------------------------------
add({ id = "vtsls", name = "vtsls", category = "lsp", exe = "vtsls", mason = "vtsls", profiles = { "web" } })
add({
  id = "prettier",
  name = "prettier",
  category = "formatter",
  exe = "prettier",
  mason = "prettier",
  profiles = { "web" },
})
add({ id = "eslint", name = "eslint", category = "linter", exe = "eslint", mason = "eslint-lsp", profiles = { "web" } })
add({
  id = "js_debug_adapter",
  name = "js-debug-adapter",
  category = "debugger",
  exe = "js-debug-adapter",
  mason = "js-debug-adapter",
  profiles = { "web" },
})
add({
  id = "html_lsp",
  name = "vscode-html-language-server",
  category = "lsp",
  exe = "vscode-html-language-server",
  mason = "html-lsp",
  profiles = { "web" },
})
add({
  id = "css_lsp",
  name = "vscode-css-language-server",
  category = "lsp",
  exe = "vscode-css-language-server",
  mason = "css-lsp",
  profiles = { "web" },
})
add({
  id = "stylelint",
  name = "stylelint",
  category = "linter",
  exe = "stylelint",
  mason = "stylelint",
  profiles = { "web" },
  note = "optional",
})
add({
  id = "vue_ls",
  name = "vue-language-server",
  category = "lsp",
  exe = "vue-language-server",
  mason = "vue-language-server",
  profiles = { "web" },
})
add({
  id = "svelte_ls",
  name = "svelte-language-server",
  category = "lsp",
  exe = "svelteserver",
  mason = "svelte-language-server",
  profiles = { "web" },
})

-- PHP -------------------------------------------------------------------
add({
  id = "intelephense",
  name = "intelephense",
  category = "lsp",
  exe = "intelephense",
  mason = "intelephense",
  profiles = { "web" },
})
add({
  id = "php_cs_fixer",
  name = "php-cs-fixer",
  category = "formatter",
  exe = "php-cs-fixer",
  mason = "php-cs-fixer",
  profiles = { "web" },
})
add({
  id = "phpstan",
  name = "phpstan",
  category = "linter",
  exe = "phpstan",
  mason = "phpstan",
  profiles = { "web" },
  note = "optional",
})

-- C# / .NET ---------------------------------------------------------------
add({
  id = "omnisharp",
  name = "OmniSharp",
  category = "lsp",
  exe = "OmniSharp",
  mason = "omnisharp",
  profiles = { "dotnet" },
})
add({
  id = "dotnet_format",
  name = "dotnet format",
  category = "formatter",
  exe = "dotnet",
  mason = nil,
  profiles = { "dotnet" },
})
add({
  id = "netcoredbg",
  name = "netcoredbg",
  category = "debugger",
  exe = "netcoredbg",
  mason = "netcoredbg",
  profiles = { "dotnet" },
})

-- Zig -----------------------------------------------------------------------
add({ id = "zls", name = "zls", category = "lsp", exe = "zls", mason = "zls", profiles = { "systems" } })

-- F# -----------------------------------------------------------------------
add({
  id = "fsautocomplete",
  name = "FsAutoComplete",
  category = "lsp",
  exe = "fsautocomplete",
  mason = "fsautocomplete",
  profiles = { "dotnet" },
})

-- Erlang ---------------------------------------------------------------
add({
  id = "erlang_ls",
  name = "erlang_ls",
  category = "lsp",
  exe = "erlang_ls",
  mason = "erlang-ls",
  profiles = { "functional" },
})

-- Ansible -----------------------------------------------------------------
add({
  id = "ansible_ls",
  name = "ansible-language-server",
  category = "lsp",
  exe = "ansible-language-server",
  mason = "ansible-language-server",
  profiles = { "devops" },
})
add({
  id = "ansible_lint",
  name = "ansible-lint",
  category = "linter",
  exe = "ansible-lint",
  mason = "ansible-lint",
  profiles = { "devops" },
  note = "optional",
})

-- CMake / Make ------------------------------------------------------------
add({
  id = "cmake_lsp",
  name = "cmake-language-server",
  category = "lsp",
  exe = "cmake-language-server",
  mason = "cmake-language-server",
  profiles = { "systems" },
})

-- GraphQL / Protobuf --------------------------------------------------------
add({
  id = "graphql_lsp",
  name = "graphql-language-service-cli",
  category = "lsp",
  exe = "graphql-lsp",
  mason = "graphql-language-service-cli",
  profiles = { "web" },
})
add({ id = "buf", name = "buf (protobuf)", category = "lsp", exe = "buf", mason = "buf", profiles = { "systems" } })

-- Misc linters ---------------------------------------------------------
add({
  id = "dotenv_linter",
  name = "dotenv-linter",
  category = "linter",
  exe = "dotenv-linter",
  mason = "dotenv-linter",
  profiles = { "devops" },
  note = "optional",
})

-- Haskell / OCaml ---------------------------------------------------------
add({
  id = "haskell_language_server",
  name = "haskell-language-server",
  category = "lsp",
  exe = "haskell-language-server-wrapper",
  mason = "haskell-language-server",
  profiles = { "functional" },
})
add({
  id = "fourmolu",
  name = "fourmolu",
  category = "formatter",
  exe = "fourmolu",
  mason = "fourmolu",
  profiles = { "functional" },
})
add({
  id = "hlint",
  name = "hlint",
  category = "linter",
  exe = "hlint",
  mason = "hlint",
  profiles = { "functional" },
  note = "optional",
})
add({
  id = "ocamllsp",
  name = "ocaml-lsp",
  category = "lsp",
  exe = "ocamllsp",
  mason = nil,
  profiles = { "functional" },
  note = "install via opam: opam install ocaml-lsp-server",
})
add({
  id = "ocamlformat",
  name = "ocamlformat",
  category = "formatter",
  exe = "ocamlformat",
  mason = nil,
  profiles = { "functional" },
  note = "install via opam: opam install ocamlformat",
})

-- Elixir / Erlang -----------------------------------------------------------
add({
  id = "elixir_ls",
  name = "ElixirLS",
  category = "lsp",
  exe = "elixir-ls",
  mason = "elixir-ls",
  profiles = { "functional" },
})
add({
  id = "credo",
  name = "credo",
  category = "linter",
  exe = "mix",
  mason = nil,
  profiles = { "functional" },
  note = "optional; mix archive.install hex credo",
})

-- Perl ------------------------------------------------------------------
add({
  id = "perl_navigator",
  name = "Perl Navigator",
  category = "lsp",
  exe = "perlnavigator",
  mason = "perlnavigator",
  profiles = { "scripting" },
})
add({
  id = "perltidy",
  name = "perltidy",
  category = "formatter",
  exe = "perltidy",
  mason = nil,
  profiles = { "scripting" },
})
add({
  id = "perlcritic",
  name = "perlcritic",
  category = "linter",
  exe = "perlcritic",
  mason = nil,
  profiles = { "scripting" },
  note = "optional",
})

-- PowerShell ------------------------------------------------------------
add({
  id = "powershell_es",
  name = "PowerShellEditorServices",
  category = "lsp",
  exe = "pwsh",
  mason = "powershell-editor-services",
  profiles = { "scripting" },
})
add({
  id = "psscriptanalyzer",
  name = "PSScriptAnalyzer",
  category = "linter",
  exe = "pwsh",
  mason = nil,
  profiles = { "scripting" },
  note = "PowerShell module, not a standalone binary",
})

-- Shell -----------------------------------------------------------------
add({
  id = "bashls",
  name = "bash-language-server",
  category = "lsp",
  exe = "bash-language-server",
  mason = "bash-language-server",
  profiles = { "core" },
})
add({ id = "shfmt", name = "shfmt", category = "formatter", exe = "shfmt", mason = "shfmt", profiles = { "core" } })
add({
  id = "shellcheck",
  name = "ShellCheck",
  category = "linter",
  exe = "shellcheck",
  mason = "shellcheck",
  profiles = { "core" },
})
add({
  id = "bashdb",
  name = "bashdb",
  category = "debugger",
  exe = "bashdb",
  mason = nil,
  profiles = { "core" },
  note = "optional",
})

-- SQL -------------------------------------------------------------------
add({ id = "sqls", name = "sqls", category = "lsp", exe = "sqls", mason = "sqls", profiles = { "devops" } })
add({
  id = "sqlfluff",
  name = "sqlfluff",
  category = "formatter",
  exe = "sqlfluff",
  mason = "sqlfluff",
  profiles = { "devops" },
})
add({
  id = "sqlfluff_lint",
  name = "sqlfluff (lint)",
  category = "linter",
  exe = "sqlfluff",
  mason = "sqlfluff",
  profiles = { "devops" },
})

-- Data / config formats -----------------------------------------------------
add({
  id = "yamlls",
  name = "yaml-language-server",
  category = "lsp",
  exe = "yaml-language-server",
  mason = "yaml-language-server",
  profiles = { "devops" },
})
add({
  id = "yamllint",
  name = "yamllint",
  category = "linter",
  exe = "yamllint",
  mason = "yamllint",
  profiles = { "devops" },
})
add({
  id = "jsonls",
  name = "vscode-json-language-server",
  category = "lsp",
  exe = "vscode-json-language-server",
  mason = "json-lsp",
  profiles = { "web" },
})
add({ id = "taplo", name = "Taplo", category = "lsp", exe = "taplo", mason = "taplo", profiles = { "core" } })
add({ id = "lemminx", name = "lemminx", category = "lsp", exe = "lemminx", mason = "lemminx", profiles = { "devops" } })

-- DevOps / IaC ------------------------------------------------------------
add({
  id = "terraformls",
  name = "terraform-ls",
  category = "lsp",
  exe = "terraform-ls",
  mason = "terraform-ls",
  profiles = { "devops" },
})
add({
  id = "tflint",
  name = "tflint",
  category = "linter",
  exe = "tflint",
  mason = "tflint",
  profiles = { "devops" },
  note = "optional",
})
add({
  id = "nixd",
  name = "nixd",
  category = "lsp",
  exe = "nixd",
  mason = nil,
  profiles = { "devops" },
  note = "install via nix profile install nixpkgs#nixd",
})
add({ id = "nixfmt", name = "nixfmt", category = "formatter", exe = "nixfmt", mason = nil, profiles = { "devops" } })
add({
  id = "statix",
  name = "statix",
  category = "linter",
  exe = "statix",
  mason = nil,
  profiles = { "devops" },
  note = "optional",
})
add({
  id = "dockerls",
  name = "dockerfile-language-server",
  category = "lsp",
  exe = "docker-langserver",
  mason = "dockerfile-language-server",
  profiles = { "devops" },
})
add({
  id = "hadolint",
  name = "hadolint",
  category = "linter",
  exe = "hadolint",
  mason = "hadolint",
  profiles = { "devops" },
})

-- Documentation -----------------------------------------------------------
add({
  id = "marksman",
  name = "marksman",
  category = "lsp",
  exe = "marksman",
  mason = "marksman",
  profiles = { "docs" },
})
add({
  id = "markdownlint",
  name = "markdownlint",
  category = "linter",
  exe = "markdownlint",
  mason = "markdownlint-cli2",
  profiles = { "docs" },
  note = "optional",
})
add({ id = "esbonio", name = "esbonio", category = "lsp", exe = "esbonio", mason = "esbonio", profiles = { "docs" } })
add({
  id = "doc8",
  name = "doc8",
  category = "linter",
  exe = "doc8",
  mason = nil,
  profiles = { "docs" },
  note = "optional; pip install doc8",
})
add({ id = "texlab", name = "texlab", category = "lsp", exe = "texlab", mason = "texlab", profiles = { "docs" } })
add({
  id = "latexindent",
  name = "latexindent",
  category = "formatter",
  exe = "latexindent",
  mason = "latexindent",
  profiles = { "docs" },
})
add({
  id = "chktex",
  name = "chktex",
  category = "linter",
  exe = "chktex",
  mason = "chktex",
  profiles = { "docs" },
  note = "optional",
})

local M = {}

M.tools = tools

--- @param id string
--- @return table|nil
function M.get(id)
  return tools[id]
end

--- @return table[] all tool specs
function M.all()
  local out = {}
  for _, spec in pairs(tools) do
    table.insert(out, spec)
  end
  table.sort(out, function(a, b)
    return a.id < b.id
  end)
  return out
end

--- @param profile string
--- @return table[] tool specs belonging to `profile`
function M.by_profile(profile)
  local out = {}
  for _, spec in ipairs(M.all()) do
    if vim.tbl_contains(spec.profiles, profile) then
      table.insert(out, spec)
    end
  end
  return out
end

M.profiles = { "core", "systems", "python", "scripting", "web", "jvm", "dotnet", "functional", "devops", "docs" }

return M
