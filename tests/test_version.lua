-- The Neovim version contract. util.version.supports() is a pure function
-- over a version table precisely so this can assert against versions this
-- machine is not running.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("version: 0.12.0 contract", function()
  local version = require("util.version")

  lib.assert_eq(version.MINIMUM.major, 0, "minimum major")
  lib.assert_eq(version.MINIMUM.minor, 12, "minimum minor")
  lib.assert_eq(version.MINIMUM.patch, 0, "minimum patch")

  local function v(major, minor, patch)
    return { major = major, minor = minor, patch = patch }
  end

  -- Unsupported: everything below 0.12.0.
  lib.assert_eq(version.supports(v(0, 11, 0)), false, "0.11.0 must be unsupported")
  lib.assert_eq(version.supports(v(0, 11, 9)), false, "0.11.9 must be unsupported")
  lib.assert_eq(version.supports(v(0, 9, 5)), false, "0.9.5 must be unsupported")
  lib.assert_eq(version.supports(v(0, 0, 1)), false, "0.0.1 must be unsupported")

  -- Supported: exactly the minimum, and anything above it.
  lib.assert_eq(version.supports(v(0, 12, 0)), true, "0.12.0 must be supported (boundary)")
  lib.assert_eq(version.supports(v(0, 12, 1)), true, "0.12.1 must be supported")
  lib.assert_eq(version.supports(v(0, 12, 4)), true, "0.12.4 must be supported")
  lib.assert_eq(version.supports(v(0, 13, 0)), true, "0.13.0 must be supported")
  lib.assert_eq(version.supports(v(1, 0, 0)), true, "1.0.0 must be supported")
  lib.assert_eq(version.supports(v(2, 5, 3)), true, "2.5.3 must be supported")

  -- Missing fields default to 0 rather than erroring.
  lib.assert_eq(version.supports({ major = 0, minor = 12 }), true, "0.12 (no patch) must be supported")
  lib.assert_eq(version.supports({ major = 0, minor = 11 }), false, "0.11 (no patch) must be unsupported")

  -- Not a version at all.
  lib.assert_eq(version.supports(nil), false, "nil must be unsupported")
  lib.assert_eq(version.supports("0.12.0"), false, "a string must be unsupported")

  -- An explicit minimum can be supplied (used by the installer probe).
  lib.assert_eq(version.supports(v(0, 12, 0), v(0, 13, 0)), false, "explicit higher minimum")
  lib.assert_eq(version.supports(v(0, 13, 0), v(0, 13, 0)), true, "explicit equal minimum")

  -- The Neovim actually running these tests must satisfy the contract --
  -- otherwise the rest of the suite is testing an unsupported setup.
  lib.assert_true(
    version.current_is_supported(),
    "the Neovim running this suite is " .. version.tostring(version.current()) .. ", below the 0.12.0 contract"
  )

  -- The rejection message must name both the requirement and what was found.
  local msg = version.unsupported_message(v(0, 11, 3))
  lib.assert_true(msg:find("0.12.0", 1, true) ~= nil, "message must state the required version")
  lib.assert_true(msg:find("0.11.3", 1, true) ~= nil, "message must state the detected version")
end)
