-- Completion stack: nvim-cmp + LSP/buffer/path sources + LuaSnip.
--
-- Decision: nvim-cmp over blink.cmp. blink.cmp's fuzzy matcher downloads a
-- prebuilt Rust binary (or needs a Rust toolchain to build one) on first
-- use unless `fuzzy.implementation` is forced to "lua" -- which gives up
-- its main performance advantage anyway. For a config whose first
-- requirement is "no downloads, ever, unless explicit", nvim-cmp vendored
-- as plain Lua is the defensible choice even though blink.cmp is newer.
local cmp = require("cmp")
local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer", keyword_length = 3 },
    { name = "path" },
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
})

-- Command-line completion (cmp-cmdline). Neovim's built-in wildmenu already
-- completes on <Tab>; this adds the same popup-with-selection UI insert mode
-- has, so `:` behaves consistently with the rest of the editor.
--
-- `:` and `/` get different source sets on purpose: `/` and `?` search the
-- current buffer, so buffer words are the useful completions there, while
-- `:` wants command names and their arguments. cmp-cmdline's `cmdline`
-- source wraps Neovim's own `getcompletion()`, so every command this config
-- registers through util.command_registry is completed automatically --
-- including argument completion like `:ToolsInstall <profile>`.
cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = "buffer" } },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    {
      name = "cmdline",
      -- Don't fire on shell escapes (`:!cmd`), where the useful completion
      -- is the shell's, not Neovim's.
      option = { ignore_cmds = { "Man", "!" } },
    },
  }),
  matching = { disallow_symbol_nonprefix_matching = false },
})
