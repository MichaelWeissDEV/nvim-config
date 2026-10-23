---@type table
return {
  filetypes = { "clojure", "edn" },
  extensions = { ".clj", ".cljs", ".cljc", ".edn" },
  treesitter = { "clojure" },
  root_markers = { "deps.edn", "project.clj", "shadow-cljs.edn", "bb.edn", ".git" },
  lsp = { tool = "clojure_lsp" },
  formatters = { "cljfmt" },
  linters = { "clj_kondo" },
}
