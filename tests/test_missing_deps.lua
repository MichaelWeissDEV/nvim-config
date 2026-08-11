-- Open one fixture file per language with (per tests/run.sh) a PATH
-- stripped of every optional tool binary, and assert this produces zero
-- notifications. A missing optional dependency must never be loud.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")
local fixtures = this_dir .. "/fixtures"

lib.run("missing deps: quiet degradation", function()
  local calls, restore = lib.notify_spy()

  local files = {
    "cargo-project/src/main.rs",
    "main.py",
    "main.go",
    "main.c",
    "Main.java",
    "notes.md",
    "data.csv",
    "paper.tex",
    "config.yaml",
    "data.json",
  }
  for _, f in ipairs(files) do
    vim.cmd.edit(fixtures .. "/" .. f)
  end
  vim.wait(800)

  restore()
  if #calls > 0 then
    local msgs = {}
    for _, c in ipairs(calls) do
      table.insert(msgs, tostring(c.msg))
    end
    error("missing-dependency handling produced notifications:\n" .. table.concat(msgs, "\n---\n"))
  end
end)
