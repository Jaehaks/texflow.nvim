local commands = require("texflow.commands")
local config = require("texflow.config")

local M = {}

M.setup = function(opts)
  config.set(opts)
  commands.setup_commands()
end

M.get_config = config.get

return M
