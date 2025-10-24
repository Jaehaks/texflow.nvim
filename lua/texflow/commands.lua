local M = {}
local Build = require('texflow.build')
local Config = require('texflow.config')

---@return texflow.config
M.get_config = function()
	return Config.get()
end

---@param opts texflow.config
M.compile = function(opts)
	Build.compile(opts)
end

---@param opts texflow.config
M.view = function(opts)
	Build.view(opts)
end

---@param opts texflow.config
---@param cb fun(opts: texflow.config)?
M.cleanup_auxfiles = function(opts, cb)
	Build.cleanup_auxfiles(opts, cb)
end

return M

