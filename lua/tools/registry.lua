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

--- `category` is the tool's primary role -- the one it is grouped under in
--- :ToolsStatus and the generated tables. A few tools genuinely fill more
--- than one role with the same binary (ktlint formats *and* lints, taplo is
--- both an LSP and a formatter), and those declare the extra ones in
--- `also`. Without that, a language referencing ktlint as a linter looks
--- like a typo to the integrity checker even though it is correct.
---
--- Tools whose roles need *different invocations* stay separate entries
--- instead (ruff/ruff_format, rubocop/rubocop_lint), because those differ
--- in more than classification.
local function add(spec)
  assert(tools[spec.id] == nil, "duplicate tool id: " .. spec.id)
  local categories = { [spec.category] = true }
  for _, extra in ipairs(spec.also or {}) do
    categories[extra] = true
  end
  spec.categories = categories
  tools[spec.id] = spec
end

--- Does this tool fill the given role, primary or secondary?
--- @param tool table
--- @param category string
--- @return boolean
local function has_category(tool, category)
  return tool ~= nil and tool.categories ~= nil and tool.categories[category] == true
end

-- Lua / Vimscript ---------------------------------------------------------
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
add({
  id = "vimls",
  name = "vim-language-server",
  category = "lsp",
  exe = "vim-language-server",
  mason = "vim-language-server",
  profiles = { "core" },
})
add({
  id = "vint",
  name = "vint",
  category = "linter",
  exe = "vint",
  mason = "vint",
  profiles = { "core" },
  note = "optional",
})

-- Python --------------------------------------------------------------------
-- The default Python stack is Astral's: ty (types, navigation, completion)
-- plus ruff (lint, quick fixes, import sorting, formatting). basedpyright is
-- the alternative type checker -- see util/python.lua and :PythonLsp.
add({
  id = "ty",
  name = "ty",
  category = "lsp",
  exe = "ty",
  mason = "ty",
  profiles = { "python" },
  note = "default Python LSP (Astral): types, go-to-definition, references, rename, completion, inlay hints",
})
add({
  id = "basedpyright",
  name = "basedpyright",
  category = "lsp",
  exe = "basedpyright-langserver",
  mason = "basedpyright",
  profiles = { "python" },
  note = "alternative to ty; used when vim.g.nvim_config_python_lsp is 'basedpyright'/'both', "
    .. "or when ty is not installed",
})
add({
  id = "ruff",
  name = "ruff (server)",
  -- `ruff server` is a real language server: lint diagnostics, quick fixes,
  -- "fix all" and organize-imports code actions. That replaces running
  -- ruff through nvim-lint, which only ever produced the diagnostics.
  category = "lsp",
  exe = "ruff",
  mason = "ruff",
  profiles = { "python" },
})
add({
  id = "ruff_format",
  name = "ruff format",
  category = "formatter",
  exe = "ruff",
  mason = "ruff",
  profiles = { "python" },
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

-- C / C++ / Objective-C / CUDA / Swift ------------------------------------
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
add({
  id = "sourcekit_lsp",
  name = "sourcekit-lsp",
  category = "lsp",
  exe = "sourcekit-lsp",
  mason = nil,
  profiles = { "systems" },
  note = "ships with the Swift toolchain / Xcode",
})
add({
  id = "swiftformat",
  name = "SwiftFormat",
  category = "formatter",
  exe = "swiftformat",
  mason = nil,
  profiles = { "systems" },
  note = "macOS: brew install swiftformat",
})
add({
  id = "swiftlint",
  name = "SwiftLint",
  category = "linter",
  exe = "swiftlint",
  mason = nil,
  profiles = { "systems" },
  note = "optional; macOS: brew install swiftlint",
})

-- Assembly ------------------------------------------------------------------
add({ id = "asm_lsp", name = "asm-lsp", category = "lsp", exe = "asm-lsp", mason = "asm-lsp", profiles = { "systems" } })
add({
  id = "asmfmt",
  name = "asmfmt",
  category = "formatter",
  exe = "asmfmt",
  mason = "asmfmt",
  profiles = { "systems" },
})

-- Java / Kotlin / Scala / Groovy --------------------------------------------
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
add({
  id = "ktlint",
  name = "ktlint",
  category = "formatter",
  -- The same binary also lints (`ktlint` checks, `ktlint --format` fixes),
  -- which is why languages/kotlin.lua legitimately lists it under both.
  also = { "linter" },
  exe = "ktlint",
  mason = "ktlint",
  profiles = { "jvm" },
})
add({
  id = "metals",
  name = "Metals (Scala LSP)",
  category = "lsp",
  exe = "metals",
  mason = nil,
  profiles = { "jvm" },
  note = "install via Coursier: cs install metals",
})
add({
  id = "scalafmt",
  name = "scalafmt",
  category = "formatter",
  exe = "scalafmt",
  mason = nil,
  profiles = { "jvm" },
  note = "install via Coursier: cs install scalafmt",
})
add({
  id = "groovyls",
  name = "groovy-language-server",
  category = "lsp",
  exe = "groovy-language-server",
  mason = "groovy-language-server",
  profiles = { "jvm" },
})
add({
  id = "npm_groovy_lint",
  name = "npm-groovy-lint",
  category = "formatter",
  also = { "linter" },
  exe = "npm-groovy-lint",
  mason = "npm-groovy-lint",
  profiles = { "jvm" },
})

-- JS / TS / Web / Mobile / Blockchain ---------------------------------------
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
  id = "htmlhint",
  name = "HTMLHint",
  category = "linter",
  exe = "htmlhint",
  mason = "htmlhint",
  profiles = { "web" },
  note = "optional",
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
add({
  id = "astro_ls",
  name = "astro-language-server",
  category = "lsp",
  exe = "astro-ls",
  mason = "astro-language-server",
  profiles = { "web" },
})
add({
  id = "prismals",
  name = "prisma-language-server",
  category = "lsp",
  exe = "prisma-language-server",
  mason = "prisma-language-server",
  profiles = { "web" },
})
add({
  id = "solidity_ls",
  name = "nomicfoundation-solidity-language-server",
  category = "lsp",
  exe = "nomicfoundation-solidity-language-server",
  mason = "nomicfoundation-solidity-language-server",
  profiles = { "web" },
})
add({
  id = "forge_fmt",
  name = "forge fmt",
  category = "formatter",
  exe = "forge",
  mason = nil,
  profiles = { "web" },
  note = "ships with Foundry (foundryup)",
})
add({
  id = "solhint",
  name = "solhint",
  category = "linter",
  exe = "solhint",
  mason = "solhint",
  profiles = { "web" },
  note = "optional",
})
add({
  id = "dartls",
  name = "dart language-server",
  category = "lsp",
  exe = "dart",
  mason = nil,
  profiles = { "web" },
  note = "ships with the Dart / Flutter SDK",
})
add({
  id = "dart_format",
  name = "dart format",
  category = "formatter",
  exe = "dart",
  mason = nil,
  profiles = { "web" },
  note = "ships with the Dart / Flutter SDK",
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

-- C# / F# / .NET ----------------------------------------------------------
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
add({
  id = "fsautocomplete",
  name = "FsAutoComplete",
  category = "lsp",
  exe = "fsautocomplete",
  mason = "fsautocomplete",
  profiles = { "dotnet" },
})
add({
  id = "fantomas",
  name = "Fantomas",
  category = "formatter",
  exe = "fantomas",
  mason = "fantomas",
  profiles = { "dotnet", "functional" },
})

-- Zig / Odin / Nim / D / Fortran / Vala / V ---------------------------------
add({ id = "zls", name = "zls", category = "lsp", exe = "zls", mason = "zls", profiles = { "systems" } })
add({
  id = "zigfmt",
  name = "zig fmt",
  category = "formatter",
  exe = "zig",
  mason = nil,
  profiles = { "systems" },
  note = "ships with the Zig compiler",
})
add({ id = "ols", name = "ols (Odin LSP)", category = "lsp", exe = "ols", mason = "ols", profiles = { "systems" } })
add({
  id = "odinfmt",
  name = "odinfmt",
  category = "formatter",
  exe = "odinfmt",
  mason = "ols",
  profiles = { "systems" },
  note = "bundled with ols",
})
add({
  id = "nim_langserver",
  name = "nimlangserver",
  category = "lsp",
  exe = "nimlangserver",
  mason = "nimlangserver",
  profiles = { "systems" },
})
add({
  id = "nimpretty",
  name = "nimpretty",
  category = "formatter",
  exe = "nimpretty",
  mason = nil,
  profiles = { "systems" },
  note = "ships with the Nim compiler",
})
add({
  id = "serve_d",
  name = "serve-d",
  category = "lsp",
  exe = "serve-d",
  mason = "serve-d",
  profiles = { "systems" },
})
add({
  id = "dfmt",
  name = "dfmt",
  category = "formatter",
  exe = "dfmt",
  mason = nil,
  profiles = { "systems" },
  note = "install via dub or system package manager",
})
add({ id = "fortls", name = "fortls", category = "lsp", exe = "fortls", mason = "fortls", profiles = { "systems" } })
add({
  id = "fprettify",
  name = "fprettify",
  category = "formatter",
  exe = "fprettify",
  mason = "fprettify",
  profiles = { "systems" },
})
add({
  id = "vala_ls",
  name = "vala-language-server",
  category = "lsp",
  exe = "vala-language-server",
  mason = "vala-language-server",
  profiles = { "systems" },
})
add({
  id = "v_analyzer",
  name = "v-analyzer",
  category = "lsp",
  exe = "v-analyzer",
  mason = "v-analyzer",
  profiles = { "systems" },
})
add({
  id = "v",
  name = "v fmt",
  category = "formatter",
  exe = "v",
  mason = nil,
  profiles = { "systems" },
  note = "ships with the V compiler",
})

-- Shaders / Hardware / GameDev --------------------------------------------
add({
  id = "glsl_analyzer",
  name = "glsl_analyzer",
  category = "lsp",
  exe = "glsl_analyzer",
  mason = "glsl_analyzer",
  profiles = { "systems" },
})
add({
  id = "glslc",
  name = "glslc",
  category = "linter",
  exe = "glslc",
  mason = nil,
  profiles = { "systems" },
  note = "optional; ships with Vulkan SDK / shaderc",
})
add({
  id = "wgsl_analyzer",
  name = "wgsl-analyzer",
  category = "lsp",
  exe = "wgsl_analyzer",
  mason = "wgsl-analyzer",
  profiles = { "systems" },
})
add({
  id = "verible_ls",
  name = "verible-verilog-ls",
  category = "lsp",
  exe = "verible-verilog-ls",
  mason = "verible",
  profiles = { "systems" },
})
add({
  id = "verible",
  name = "verible-verilog-format",
  category = "formatter",
  exe = "verible-verilog-format",
  mason = "verible",
  profiles = { "systems" },
})
add({
  id = "verilator",
  name = "Verilator",
  category = "linter",
  exe = "verilator",
  mason = nil,
  profiles = { "systems" },
  note = "optional; install via system package manager",
})
add({
  id = "vhdl_ls",
  name = "vhdl_ls (rust_hdl)",
  category = "lsp",
  exe = "vhdl_ls",
  mason = "rust_hdl",
  profiles = { "systems" },
})
add({
  id = "gdformat",
  name = "gdformat",
  category = "formatter",
  exe = "gdformat",
  mason = "gdtoolkit",
  profiles = { "scripting" },
})
add({
  id = "gdlint",
  name = "gdlint",
  category = "linter",
  exe = "gdlint",
  mason = "gdtoolkit",
  profiles = { "scripting" },
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

-- CMake / Make / Meson / Just -----------------------------------------------
add({
  id = "cmake_lsp",
  name = "cmake-language-server",
  category = "lsp",
  exe = "cmake-language-server",
  mason = "cmake-language-server",
  profiles = { "systems" },
})
add({
  id = "gersemi",
  name = "gersemi",
  category = "formatter",
  exe = "gersemi",
  mason = "gersemi",
  profiles = { "systems" },
})
add({
  id = "cmakelint",
  name = "cmakelint",
  category = "linter",
  exe = "cmakelint",
  mason = "cmakelint",
  profiles = { "systems" },
  note = "optional",
})
add({
  id = "autotools_ls",
  name = "autotools-language-server",
  category = "lsp",
  exe = "autotools-language-server",
  mason = "autotools-language-server",
  profiles = { "systems" },
})
add({
  id = "checkmake",
  name = "checkmake",
  category = "linter",
  exe = "checkmake",
  mason = "checkmake",
  profiles = { "systems" },
  note = "optional",
})
add({
  id = "mesonlsp",
  name = "mesonlsp",
  category = "lsp",
  exe = "mesonlsp",
  mason = "mesonlsp",
  profiles = { "systems" },
})
add({
  id = "meson",
  name = "meson format",
  category = "formatter",
  exe = "meson",
  mason = nil,
  profiles = { "systems" },
  note = "ships with Meson",
})
add({
  id = "just_lsp",
  name = "just-lsp",
  category = "lsp",
  exe = "just-lsp",
  mason = "just-lsp",
  profiles = { "systems", "devops" },
})
add({
  id = "just",
  name = "just --fmt",
  category = "formatter",
  exe = "just",
  mason = nil,
  profiles = { "systems", "devops" },
  note = "ships with just",
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
add({
  id = "buf",
  name = "buf (protobuf)",
  category = "lsp",
  also = { "formatter" },
  exe = "buf",
  mason = "buf",
  profiles = { "systems" },
})
add({
  id = "buf_lint",
  name = "buf lint",
  category = "linter",
  exe = "buf",
  mason = "buf",
  profiles = { "systems" },
})

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

-- Haskell / OCaml / Clojure / Gleam / Elm / Racket --------------------------
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
add({
  id = "clojure_lsp",
  name = "clojure-lsp",
  category = "lsp",
  exe = "clojure-lsp",
  mason = "clojure-lsp",
  profiles = { "functional" },
})
add({
  id = "cljfmt",
  name = "cljfmt",
  category = "formatter",
  exe = "cljfmt",
  mason = "cljfmt",
  profiles = { "functional" },
})
add({
  id = "clj_kondo",
  name = "clj-kondo",
  category = "linter",
  exe = "clj-kondo",
  mason = "clj-kondo",
  profiles = { "functional" },
})
add({
  id = "gleam",
  name = "gleam (LSP + format)",
  category = "lsp",
  also = { "formatter" },
  exe = "gleam",
  mason = nil,
  profiles = { "functional" },
  note = "ships with the Gleam compiler",
})
add({
  id = "elmls",
  name = "elm-language-server",
  category = "lsp",
  exe = "elm-language-server",
  mason = "elm-language-server",
  profiles = { "functional", "web" },
})
add({
  id = "elm_format",
  name = "elm-format",
  category = "formatter",
  exe = "elm-format",
  mason = "elm-format",
  profiles = { "functional", "web" },
})
add({
  id = "racket_langserver",
  name = "racket-langserver",
  category = "lsp",
  exe = "racket",
  mason = nil,
  profiles = { "functional" },
  note = "install via: raco pkg install racket-langserver",
})
add({
  id = "racketfmt",
  name = "raco fmt",
  category = "formatter",
  exe = "raco",
  mason = nil,
  profiles = { "functional" },
  note = "install via: raco pkg install fmt",
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
  id = "mix",
  name = "mix format",
  category = "formatter",
  exe = "mix",
  mason = nil,
  profiles = { "functional" },
  note = "ships with Elixir",
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
add({
  id = "erlang_ls",
  name = "erlang_ls",
  category = "lsp",
  exe = "erlang_ls",
  mason = "erlang-ls",
  profiles = { "functional" },
})
add({
  id = "erlfmt",
  name = "erlfmt",
  category = "formatter",
  exe = "erlfmt",
  mason = nil,
  profiles = { "functional" },
  note = "optional; rebar3 or escript install",
})

-- Perl / Crystal / Tcl / R / Julia ------------------------------------------
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
add({
  id = "crystalline",
  name = "crystalline",
  category = "lsp",
  exe = "crystalline",
  mason = "crystalline",
  profiles = { "scripting" },
})
add({
  id = "crystal",
  name = "crystal tool format",
  category = "formatter",
  exe = "crystal",
  mason = nil,
  profiles = { "scripting" },
  note = "ships with the Crystal compiler",
})
add({
  id = "tclfmt",
  name = "tclfmt",
  category = "formatter",
  exe = "tclfmt",
  mason = nil,
  profiles = { "scripting" },
  note = "optional; part of tclint (pip install tclint)",
})
add({
  id = "nagelfar",
  name = "Nagelfar (Tcl linter)",
  category = "linter",
  exe = "nagelfar",
  mason = nil,
  profiles = { "scripting" },
  note = "optional",
})
add({
  id = "r_language_server",
  name = "r-languageserver",
  category = "lsp",
  exe = "r-languageserver",
  mason = "r-languageserver",
  profiles = { "scripting" },
})
add({
  id = "air",
  name = "Air (R formatter)",
  category = "formatter",
  exe = "air",
  mason = "air",
  profiles = { "scripting" },
})
add({
  id = "julials",
  name = "julia-lsp",
  category = "lsp",
  exe = "julia-lsp",
  mason = "julia-lsp",
  profiles = { "scripting" },
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

-- Shell (Bash / Zsh / Fish / Nushell / Awk) ---------------------------------
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
add({
  id = "zsh",
  name = "zsh -n (syntax check)",
  category = "linter",
  exe = "zsh",
  mason = nil,
  profiles = { "scripting" },
  note = "ships with zsh",
})
add({
  id = "fish_lsp",
  name = "fish-lsp",
  category = "lsp",
  exe = "fish-lsp",
  mason = "fish-lsp",
  profiles = { "scripting" },
})
add({
  id = "fish_indent",
  name = "fish_indent",
  category = "formatter",
  exe = "fish_indent",
  mason = nil,
  profiles = { "scripting" },
  note = "ships with fish",
})
add({
  id = "fish",
  name = "fish -n (syntax check)",
  category = "linter",
  exe = "fish",
  mason = nil,
  profiles = { "scripting" },
  note = "ships with fish",
})
add({
  id = "nuls",
  name = "nu --lsp",
  category = "lsp",
  exe = "nu",
  mason = nil,
  profiles = { "scripting" },
  note = "built into Nushell (nu --lsp)",
})
add({
  id = "nufmt",
  name = "nufmt",
  category = "formatter",
  exe = "nufmt",
  mason = nil,
  profiles = { "scripting" },
  note = "optional; cargo install nufmt",
})
add({
  id = "awk_ls",
  name = "awk-language-server",
  category = "lsp",
  exe = "awk-language-server",
  mason = "awk-language-server",
  profiles = { "scripting" },
})
add({
  id = "gawk",
  name = "gawk",
  category = "formatter",
  also = { "linter" },
  exe = "gawk",
  mason = nil,
  profiles = { "scripting" },
  note = "ships with GNU Awk",
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
add({
  id = "taplo",
  name = "Taplo",
  category = "lsp",
  -- `taplo fmt` formats; conform ships a built-in taplo formatter, so
  -- languages/toml.lua uses this one entry for both roles.
  also = { "formatter" },
  exe = "taplo",
  mason = "taplo",
  profiles = { "core" },
})
add({ id = "lemminx", name = "lemminx", category = "lsp", exe = "lemminx", mason = "lemminx", profiles = { "devops" } })
add({
  id = "xmlformat",
  name = "xmlformatter",
  category = "formatter",
  exe = "xmlformat",
  mason = "xmlformatter",
  profiles = { "devops" },
})
add({
  id = "kdlfmt",
  name = "kdlfmt",
  category = "formatter",
  exe = "kdlfmt",
  mason = "kdlfmt",
  profiles = { "devops" },
})
add({
  id = "pkl_lsp",
  name = "pkl-lsp",
  category = "lsp",
  exe = "pkl-lsp",
  mason = nil,
  profiles = { "devops" },
  note = "see https://pkl-lang.org/lsp",
})
add({
  id = "pkl",
  name = "pkl format",
  category = "formatter",
  exe = "pkl",
  mason = nil,
  profiles = { "devops" },
  note = "ships with Pkl CLI",
})
add({
  id = "hyprls",
  name = "hyprls",
  category = "lsp",
  exe = "hyprls",
  mason = "hyprls",
  profiles = { "devops" },
})

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
  id = "terraform_fmt",
  name = "terraform fmt",
  category = "formatter",
  exe = "terraform",
  mason = nil,
  profiles = { "devops" },
  note = "ships with Terraform CLI",
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
  id = "helm_ls",
  name = "helm-ls",
  category = "lsp",
  exe = "helm_ls",
  mason = "helm-ls",
  profiles = { "devops" },
})
add({
  id = "jsonnet_ls",
  name = "jsonnet-language-server",
  category = "lsp",
  exe = "jsonnet-language-server",
  mason = "jsonnet-language-server",
  profiles = { "devops" },
})
add({
  id = "jsonnetfmt",
  name = "jsonnetfmt",
  category = "formatter",
  exe = "jsonnetfmt",
  mason = nil,
  profiles = { "devops" },
  note = "ships with go-jsonnet",
})
add({
  id = "regal",
  name = "Regal (Rego LSP + linter)",
  category = "lsp",
  also = { "linter" },
  exe = "regal",
  mason = "regal",
  profiles = { "devops" },
})
add({
  id = "opa_fmt",
  name = "opa fmt",
  category = "formatter",
  exe = "opa",
  mason = nil,
  profiles = { "devops" },
  note = "ships with Open Policy Agent (opa)",
})
add({
  id = "cue",
  name = "cue (LSP + lint)",
  category = "lsp",
  also = { "linter" },
  exe = "cue",
  mason = "cue",
  profiles = { "devops" },
})
add({
  id = "cue_fmt",
  name = "cue fmt",
  category = "formatter",
  exe = "cue",
  mason = "cue",
  profiles = { "devops" },
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
  -- No Mason package exists (confirmed against the live registry) -- it
  -- ships with TeX distributions (TeX Live / MacTeX), not standalone.
  mason = nil,
  profiles = { "docs" },
  note = "optional; ships with TeX Live/MacTeX -- macOS: brew install --cask mactex-no-gui "
    .. "| Debian/Ubuntu: apt install chktex | Arch: pacman -S texlive-binextra",
})
add({
  id = "tinymist",
  name = "tinymist (Typst LSP)",
  category = "lsp",
  exe = "tinymist",
  mason = "tinymist",
  profiles = { "docs" },
})
add({
  id = "typstyle",
  name = "typstyle",
  category = "formatter",
  exe = "typstyle",
  mason = "typstyle",
  profiles = { "docs" },
})
add({
  id = "vale",
  name = "Vale",
  category = "linter",
  exe = "vale",
  mason = "vale",
  profiles = { "docs" },
  note = "optional prose linter",
})

local M = {}

M.tools = tools

M.has_category = has_category

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
