-- conform.nvim, driven entirely by lua/languages/*.lua: formatters_by_ft is
-- built from the registry, filtered to formatters whose binary is actually
-- installed (missing ones are silently left out -- no startup warning, and
-- :leader lf reports "no formatter available" only when you actually try
-- to format with none configured).
local conform = require("conform")
local languages = require("languages.registry")
local tools = require("tools.registry")
local detection = require("tools.detection")
local cmdreg = require("util.command_registry")
local km = require("util.keymap_registry")
local scratch = require("util.scratch")
local notify = require("util.notify")

-- conform's built-in formatter modules use these ids directly (verified
-- against stevearc/conform.nvim's lua/conform/formatters/*.lua). Two of our
-- tools have no built-in conform module, so they get a minimal custom
-- definition instead of being silently dropped.
local CUSTOM_FORMATTERS = {
  google_java_format = { command = "google-java-format", args = { "-" }, stdin = true },
  dotnet_format = { command = "dotnet", args = { "format", "--include", "$FILENAME" }, stdin = false },
}

local formatters_by_ft = {}
local missing_by_ft = {}

for _, lang in ipairs(languages.all()) do
  if lang.formatters and #lang.formatters > 0 then
    local available, missing = {}, {}
    for _, tool_id in ipairs(lang.formatters) do
      local tool = tools.get(tool_id)
      if tool and detection.installed(tool) then
        table.insert(available, tool_id)
      else
        table.insert(missing, tool and tool.name or tool_id)
      end
    end
    for _, ft in ipairs(lang.filetypes) do
      if #available > 0 then
        formatters_by_ft[ft] = available
      end
      if #missing > 0 then
        missing_by_ft[ft] = missing
      end
    end
  end
end

conform.setup({
  formatters = CUSTOM_FORMATTERS,
  formatters_by_ft = formatters_by_ft,
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return nil
    end
    if formatters_by_ft[vim.bo[bufnr].filetype] == nil then
      return nil
    end
    return { timeout_ms = 2000, lsp_format = "fallback" }
  end,
})

local function format_current()
  local ft = vim.bo.filetype
  if formatters_by_ft[ft] == nil then
    local missing = missing_by_ft[ft]
    if missing then
      notify.once(
        "formatter-missing:" .. ft,
        string.format("No formatter available for %s. Expected: %s.", ft, table.concat(missing, " or ")),
        vim.log.levels.WARN
      )
    else
      notify.once("formatter-none:" .. ft, "No formatter registered for filetype '" .. ft .. "'.", vim.log.levels.WARN)
    end
    -- Still try LSP-formatting as a fallback (e.g. jdtls, omnisharp) so
    -- "no conform formatter" doesn't mean "no formatting at all".
    conform.format({ timeout_ms = 2000, lsp_format = "fallback", formatters = {} })
    return
  end
  conform.format({ async = true, lsp_format = "fallback" })
end

km.map({ mode = { "n", "v" }, lhs = "<leader>lf", rhs = format_current, desc = "Format buffer", group = "Format" })

-- Format-on-save is ON by default and lives under the UI-toggle prefix
-- because that is where every other "change how the editor behaves right
-- now" switch lives. Buffer-local by default (the common case: one file
-- you don't want reformatted); <leader>uF flips it globally.
km.map({
  mode = "n",
  lhs = "<leader>uf",
  rhs = function()
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Format on save (this buffer): " .. (vim.b.disable_autoformat and "off" or "on"))
  end,
  desc = "Toggle format on save (buffer)",
  group = "UI",
})
km.map({
  mode = "n",
  lhs = "<leader>uF",
  rhs = function()
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Format on save (global): " .. (vim.g.disable_autoformat and "off" or "on"))
  end,
  desc = "Toggle format on save (global)",
  group = "UI",
})

cmdreg.command({
  name = "Format",
  desc = "Format the current buffer",
  category = "Formatting",
  example = ":Format",
  fn = format_current,
})

cmdreg.command({
  name = "FormatToggle",
  desc = "Toggle format-on-save (buffer-local; add ! for global)",
  category = "Formatting",
  example = ":FormatToggle!",
  opts = { bang = true },
  fn = function(opts)
    if opts.bang then
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      vim.notify("Format on save (global): " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
    else
      vim.b.disable_autoformat = not vim.b.disable_autoformat
      vim.notify("Format on save (buffer): " .. (vim.b.disable_autoformat and "disabled" or "enabled"))
    end
  end,
})

cmdreg.command({
  name = "FormatEnable",
  desc = "Enable format-on-save globally",
  category = "Formatting",
  example = ":FormatEnable",
  fn = function()
    vim.g.disable_autoformat = false
    vim.b.disable_autoformat = false
  end,
})

cmdreg.command({
  name = "FormatDisable",
  desc = "Disable format-on-save globally",
  category = "Formatting",
  example = ":FormatDisable",
  fn = function()
    vim.g.disable_autoformat = true
  end,
})

cmdreg.command({
  name = "FormatStatus",
  desc = "Show whether format-on-save is currently active for this buffer, and why",
  category = "Formatting",
  example = ":FormatStatus",
  fn = function()
    local ft = vim.bo.filetype
    local has_formatter = formatters_by_ft[ft] ~= nil
    local off_global = vim.g.disable_autoformat and true or false
    local off_buffer = vim.b.disable_autoformat and true or false
    local active = has_formatter and not off_global and not off_buffer

    local reason
    if active then
      reason = "formatting with: " .. table.concat(formatters_by_ft[ft], ", ")
    elseif off_global then
      reason = "disabled globally (:FormatEnable or <leader>uF to re-enable)"
    elseif off_buffer then
      reason = "disabled for this buffer (<leader>uf to re-enable)"
    else
      reason = "no formatter available for filetype '" .. ft .. "' (see :FormatterStatus)"
    end
    vim.notify("Format on save: " .. (active and "ON" or "OFF") .. " -- " .. reason)
  end,
})

cmdreg.command({
  name = "FormatterStatus",
  desc = "Show which formatter(s) are configured/available for the current buffer, and all formatters by filetype",
  category = "Formatting",
  example = ":FormatterStatus",
  fn = function()
    local lines = { "# Formatter Status", "", "Current buffer (" .. vim.bo.filetype .. "):" }
    local current = formatters_by_ft[vim.bo.filetype]
    if current then
      table.insert(lines, "  available: " .. table.concat(current, ", "))
    else
      table.insert(
        lines,
        "  none available"
          .. (
            missing_by_ft[vim.bo.filetype]
              and (" (missing: " .. table.concat(missing_by_ft[vim.bo.filetype], ", ") .. ")")
            or ""
          )
      )
    end
    table.insert(lines, "")
    table.insert(lines, "## All filetypes")
    table.insert(lines, "")
    local fts = {}
    for ft in pairs(vim.tbl_extend("keep", formatters_by_ft, missing_by_ft)) do
      table.insert(fts, ft)
    end
    table.sort(fts)
    for _, ft in ipairs(fts) do
      local avail = formatters_by_ft[ft]
      local miss = missing_by_ft[ft]
      table.insert(
        lines,
        string.format(
          "- %-16s available: %-30s missing: %s",
          ft,
          avail and table.concat(avail, ",") or "-",
          miss and table.concat(miss, ",") or "-"
        )
      )
    end
    scratch.open("nvim-config://formatter-status", lines)
  end,
})
