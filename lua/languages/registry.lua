-- The central language registry. Every per-language file under
-- lua/languages/*.lua (except this one and init.lua) returns exactly one
-- LanguageSpec table; this module discovers, validates and indexes them.
--
-- Nothing in this file talks to LSP clients, conform, nvim-lint or DAP
-- directly -- lsp/init.lua, plugins/formatting.lua, plugins/linting.lua and
-- dap/registry.lua each read this registry and drive their own plugin.
-- That keeps "which language has which tool" in exactly one place.
--
-- @class LanguageSpec
--   id            string                unique id, matches the filename
--   filetypes     string[]              vim filetypes this spec applies to
--   extensions    string[]?             file extensions, documentation only
--   treesitter    string[]?             nvim-treesitter parser names
--   root_markers  string[]?             files/dirs that mark a project root
--   lsp           { tool: string, settings: table?, extra: table?, enabled: fun():boolean? }?
--                 `enabled` (optional) is re-evaluated on every LSP registry
--                 refresh; returning false keeps (or switches) the server off.
--                 Python uses it to choose between ty and basedpyright.
--   extra_lsp     { tool: string, settings: table?, extra: table?, enabled: fun():boolean? }[]?
--                 additional LSP clients attached alongside `lsp` for the same
--                 filetypes/root_markers (Neovim allows multiple clients per
--                 buffer natively). Use sparingly -- two servers both producing
--                 diagnostics/completions for the same buffer can be noisy;
--                 this exists for cases like Python's ruff server (lint + fixes
--                 next to the type checker), not as the default way to add a
--                 language server.
--   formatters    string[]?             tool ids from tools.registry, in order
--   linters       string[]?             tool ids from tools.registry
--   debugger      { tool: string, adapter: fun():table, configurations: fun():table[] }?
--   indent        { shiftwidth: integer, expandtab: boolean? }?  documentation;
--                 applied for real via after/ftplugin/<filetype>.lua
--   keymaps       fun(bufnr: integer)?  buffer-local, filetype-scoped keymaps
--   notes         string?

local LANGUAGE_IDS = {
  -- Core / Scripting
  "lua",
  "vim",
  "python",
  "ruby",
  "perl",
  "crystal",
  "tcl",
  "r",
  "julia",
  -- Shells
  "bash",
  "zsh",
  "fish",
  "nu",
  "powershell",
  "awk",
  -- Systems / Native
  "c",
  "cpp",
  "objc",
  "cuda",
  "asm",
  "rust",
  "go",
  "zig",
  "odin",
  "nim",
  "d",
  "fortran",
  "swift",
  "vala",
  "vlang",
  -- Build systems
  "cmake",
  "make",
  "meson",
  "just",
  -- JVM
  "java",
  "kotlin",
  "scala",
  "groovy",
  -- .NET
  "csharp",
  "fsharp",
  -- Functional
  "haskell",
  "ocaml",
  "elixir",
  "erlang",
  "clojure",
  "gleam",
  "elm",
  "racket",
  -- Web / Frontend / Mobile / Blockchain
  "javascript",
  "typescript",
  "html",
  "css", -- also handles scss/sass/less
  "vue",
  "svelte",
  "astro",
  "php",
  "dart",
  "graphql",
  "prisma",
  "solidity",
  -- Data / Config formats
  "json",
  "yaml",
  "toml",
  "xml",
  "kdl",
  "pkl",
  "sql",
  "csv",
  "dotenv",
  "ini",
  "proto",
  -- DevOps / IaC
  "dockerfile",
  "terraform",
  "nix",
  "ansible",
  "helm",
  "jsonnet",
  "rego",
  "cue",
  "hyprlang",
  -- GameDev / Shaders / Hardware
  "gdscript",
  "glsl",
  "wgsl",
  "verilog",
  "vhdl",
  -- Documentation
  "markdown",
  "rst",
  "latex",
  "typst",
  "asciidoc",
}

--- Short and natural aliases accepted by :LangInstall / :LangInfo (e.g.
--- `:LangInstall ts js`, `:LangInstall py`, `:LangInstall c++`).
local ALIASES = {
  -- Web / JS / TS
  ts = "typescript",
  tsx = "typescript",
  js = "javascript",
  jsx = "javascript",
  mjs = "javascript",
  cjs = "javascript",
  htm = "html",
  scss = "css",
  sass = "css",
  less = "css",
  gql = "graphql",
  -- Systems
  ["c++"] = "cpp",
  cxx = "cpp",
  cc = "cpp",
  hpp = "cpp",
  ["objective-c"] = "objc",
  ["obj-c"] = "objc",
  cu = "cuda",
  rs = "rust",
  golang = "go",
  s = "asm",
  nasm = "asm",
  masm = "asm",
  assembly = "asm",
  dlang = "d",
  f90 = "fortran",
  f95 = "fortran",
  v = "vlang",
  makefile = "make",
  justfile = "just",
  -- Scripting / Shells
  py = "python",
  rb = "ruby",
  pl = "perl",
  cr = "crystal",
  sh = "bash",
  nushell = "nu",
  ps1 = "powershell",
  pwsh = "powershell",
  vimscript = "vim",
  viml = "vim",
  jl = "julia",
  rmd = "r",
  -- JVM / .NET
  kt = "kotlin",
  kts = "kotlin",
  sbt = "scala",
  gradle = "groovy",
  cs = "csharp",
  ["c#"] = "csharp",
  fs = "fsharp",
  ["f#"] = "fsharp",
  -- Functional
  hs = "haskell",
  ml = "ocaml",
  ex = "elixir",
  exs = "elixir",
  erl = "erlang",
  clj = "clojure",
  edn = "clojure",
  scm = "racket",
  scheme = "racket",
  rkt = "racket",
  -- Mobile / Blockchain / GameDev / Hardware
  flutter = "dart",
  sol = "solidity",
  gd = "gdscript",
  godot = "gdscript",
  sv = "verilog",
  systemverilog = "verilog",
  vhd = "vhdl",
  -- DevOps / Config / Data / Docs
  yml = "yaml",
  tf = "terraform",
  hcl = "terraform",
  docker = "dockerfile",
  containerfile = "dockerfile",
  k8s = "helm",
  opa = "rego",
  hypr = "hyprlang",
  hyprland = "hyprlang",
  env = "dotenv",
  cfg = "ini",
  dosini = "ini",
  tsv = "csv",
  protobuf = "proto",
  md = "markdown",
  tex = "latex",
  bib = "latex",
  bibtex = "latex",
  typ = "typst",
  adoc = "asciidoc",
}

local PACK_ORDER = {
  "core",
  "systems",
  "c-family",
  "web",
  "python",
  "jvm",
  "dotnet",
  "scripting",
  "shell",
  "functional",
  "devops",
  "data",
  "docs",
  "mobile",
  "scientific",
  "gamedev",
  "hardware",
  "blockchain",
}

--- Language packs / bundles for `:LangInstall <pack>` (e.g. `:LangInstall web`,
--- `:LangInstall systems`, `:LangInstall all`). Installing a pack installs
--- every member language's LSP, formatter, linter, debugger and Tree-sitter
--- parsers in a single batch.
local PACKS = {
  core = { "lua", "vim", "bash", "json", "toml", "yaml", "markdown" },
  systems = {
    "c",
    "cpp",
    "objc",
    "cuda",
    "asm",
    "rust",
    "go",
    "zig",
    "odin",
    "nim",
    "d",
    "fortran",
    "vala",
    "vlang",
    "cmake",
    "make",
    "meson",
    "just",
    "proto",
  },
  ["c-family"] = { "c", "cpp", "objc", "cuda", "asm", "cmake", "make", "meson" },
  web = {
    "html",
    "css",
    "javascript",
    "typescript",
    "vue",
    "svelte",
    "astro",
    "elm",
    "php",
    "graphql",
    "prisma",
    "json",
  },
  python = { "python" },
  jvm = { "java", "kotlin", "scala", "groovy" },
  dotnet = { "csharp", "fsharp" },
  scripting = {
    "python",
    "ruby",
    "perl",
    "lua",
    "tcl",
    "crystal",
    "bash",
    "zsh",
    "fish",
    "nu",
    "powershell",
    "awk",
  },
  shell = { "bash", "zsh", "fish", "nu", "powershell", "awk", "make", "just" },
  functional = {
    "haskell",
    "ocaml",
    "elixir",
    "erlang",
    "clojure",
    "gleam",
    "elm",
    "racket",
    "fsharp",
    "scala",
  },
  devops = {
    "dockerfile",
    "terraform",
    "ansible",
    "helm",
    "nix",
    "jsonnet",
    "rego",
    "cue",
    "yaml",
    "toml",
    "json",
    "xml",
    "kdl",
    "pkl",
    "sql",
    "dotenv",
    "ini",
    "hyprlang",
    "bash",
    "just",
  },
  data = {
    "sql",
    "json",
    "yaml",
    "toml",
    "xml",
    "kdl",
    "pkl",
    "csv",
    "ini",
    "dotenv",
    "graphql",
    "proto",
    "prisma",
    "jsonnet",
    "cue",
  },
  docs = { "markdown", "latex", "typst", "rst", "asciidoc" },
  mobile = { "swift", "kotlin", "java", "dart", "objc" },
  scientific = { "python", "r", "julia", "fortran", "cuda", "latex", "typst" },
  gamedev = { "cpp", "c", "csharp", "rust", "lua", "gdscript", "glsl", "wgsl", "odin", "zig" },
  hardware = { "verilog", "vhdl", "asm", "c", "cpp", "cmake", "make" },
  blockchain = { "solidity", "rust", "go", "typescript" },
}

local M = {}

local by_id = {}
local by_filetype = {}

local function validate(id, spec)
  assert(type(spec) == "table", id .. ": language spec must return a table")
  assert(type(spec.filetypes) == "table" and #spec.filetypes > 0, id .. ": filetypes required")
  if spec.lsp then
    assert(spec.lsp.tool, id .. ": lsp.tool required when lsp is set")
  end
  if spec.extra_lsp then
    for i, lsp_spec in ipairs(spec.extra_lsp) do
      assert(lsp_spec.tool, id .. ": extra_lsp[" .. i .. "].tool required")
    end
  end
  if spec.debugger then
    assert(spec.debugger.tool, id .. ": debugger.tool required when debugger is set")
  end
end

local function load_all()
  if next(by_id) ~= nil then
    return -- already loaded
  end
  for _, id in ipairs(LANGUAGE_IDS) do
    local ok, spec = pcall(require, "languages." .. id)
    if not ok then
      require("util.notify").config_error("languages." .. id, tostring(spec))
    else
      validate(id, spec)
      spec.id = id
      by_id[id] = spec
      for _, ft in ipairs(spec.filetypes) do
        by_filetype[ft] = spec
      end
    end
  end
end

--- @return LanguageSpec[]
function M.all()
  load_all()
  local out = {}
  for _, id in ipairs(LANGUAGE_IDS) do
    if by_id[id] then
      table.insert(out, by_id[id])
    end
  end
  return out
end

--- @param id string
--- @return LanguageSpec|nil
function M.get(id)
  load_all()
  return by_id[id]
end

--- @param filetype string
--- @return LanguageSpec|nil
function M.by_filetype(filetype)
  load_all()
  return by_filetype[filetype]
end

--- Resolve a single language identifier: canonical id, short alias (e.g.
--- "ts", "js", "py", "rs", "c++"), or vim filetype.
--- @param name string
--- @return LanguageSpec|nil
function M.resolve(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  load_all()
  local key = name:lower()
  if by_id[key] then
    return by_id[key]
  end
  if ALIASES[key] and by_id[ALIASES[key]] then
    return by_id[ALIASES[key]]
  end
  return by_filetype[key] or by_filetype[name]
end

--- Resolve a language pack name (or "all") into its LanguageSpec list.
--- @param pack string
--- @return LanguageSpec[]|nil
function M.by_pack(pack)
  if type(pack) ~= "string" or pack == "" then
    return nil
  end
  load_all()
  local key = pack:lower()
  if key == "all" then
    return M.all()
  end
  local ids = PACKS[key]
  if not ids then
    return nil
  end
  local out = {}
  for _, id in ipairs(ids) do
    if by_id[id] then
      table.insert(out, by_id[id])
    end
  end
  return out
end

--- Packs that contain language `id`, in PACK_ORDER.
--- @param id string
--- @return string[]
function M.packs_for(id)
  local out = {}
  for _, pack in ipairs(PACK_ORDER) do
    if vim.tbl_contains(PACKS[pack] or {}, id) then
      table.insert(out, pack)
    end
  end
  return out
end

--- Short aliases that resolve to language `id`, sorted alphabetically.
--- @param id string
--- @return string[]
function M.aliases_for(id)
  local out = {}
  for alias, target in pairs(ALIASES) do
    if target == id then
      table.insert(out, alias)
    end
  end
  table.sort(out)
  return out
end

M.ids = LANGUAGE_IDS
M.aliases = ALIASES
M.packs = PACKS
M.pack_names = PACK_ORDER

return M
