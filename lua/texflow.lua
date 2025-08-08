local config = require("texflow.config")

local M = {}

M.setup = function(opts)
	config.set(opts)
end

M.get_config = config.get

M.compile = function (opts)
	require('texflow.build').compile(opts)
end

return M
