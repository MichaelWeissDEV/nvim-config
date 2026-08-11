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
