-- Tiny test helper shared by tests/test_*.lua. No framework: each test
-- script is run standalone via `nvim --headless -l tests/test_x.lua` and
-- must call M.done() at the end. Deliberately minimal, matching this
-- repo's "no unnecessary abstraction" rule.
local M = {}

--- Replace vim.notify with a spy that records calls instead of (also)
--- displaying them, so a test can assert "zero notifications happened."
--- @return table calls, fun() restore
function M.notify_spy()
  local calls = {}
  local orig = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(calls, { msg = msg, level = level })
  end
  return calls, function()
    vim.notify = orig
  end
end

function M.assert_true(cond, msg)
  if not cond then
    error(msg or "assertion failed", 2)
  end
end

function M.assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", msg or "not equal", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

--- Absolute, normalised form of a path, for comparing two paths that
--- describe the same location but were spelled differently.
---
--- On Windows this matters constantly: `vim.fn.tempname()` returns
--- backslashes, `vim.fs.joinpath()` returns forward slashes, and the
--- filesystem is case-insensitive -- so three spellings of one directory
--- compare unequal as plain strings. A trailing separator is dropped for
--- the same reason.
--- @param path string
--- @return string
function M.canonical(path)
  local p = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  p = p:gsub("[/\\]+$", "")
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    p = p:lower()
  end
  return p
end

--- Assert that two paths point at the same location, whatever their
--- spelling. Use instead of assert_eq whenever either side came out of an
--- API rather than out of the test itself.
--- @param actual string
--- @param expected string
--- @param msg string|nil
function M.assert_same_path(actual, expected, msg)
  local a, e = M.canonical(actual), M.canonical(expected)
  if a ~= e then
    local detail = string.format("expected path %s, got %s (canonical: %s vs %s)", expected, actual, e, a)
    error((msg or "paths differ") .. ": " .. detail, 2)
  end
end

--- Report failures and exit with the right code, or print PASS and exit 0.
--- @param name string test name
--- @param fn function the test body; failure = anything it errors on
function M.run(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
    os.exit(0)
  else
    print("FAIL: " .. name .. ": " .. tostring(err))
    os.exit(1)
  end
end

return M
