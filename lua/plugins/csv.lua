-- rainbow_csv: only loaded for csv/tsv buffers.
local lazyload = require("config.lazyload")

lazyload.on_filetype({ "csv", "tsv" }, "rainbow_csv", function()
  lazyload.packadd("rainbow_csv")
end)
