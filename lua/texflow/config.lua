local M = {}

-- default configuration
---@class texflow.config
---@field latex texflow.config.latex
---@field viewer texflow.config.viewer
local default_config = {
	---@class texflow.config.latex
	---@field shell string shell command (ex, cmd, powershell)
	---@field shellcmdflag string shell command arguments (ex, /c /n)
	---@field engine string compile engine for latex
	---@field args table arguments for latex engine
	latex = {
		shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
		shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
		engine = 'latexmk',
		args = {
			'-pdf',
			'-interaction=nonstopmode',
			'-synctex=1',
			'-verbose',
			'-file-line-error',
			'@tex',
		},
	},
	---@class texflow.config.viewer
	---@field shell string shell command (ex, cmd, powershell)
	---@field shellcmdflag string shell command arguments (ex, /c /n)
	---@field engine string compile engine for pdf viewer
	---@field args table arguments for pdf viewer
	viewer = {
		shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
		shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
		engine = 'sioyek',
		args = {
			'--reuse-window',
			'--nofocus',
			'--inverse-search "' .. vim.g.python3_host_prog .. ' @InverseSearch %1 %2"',
			'--forward-search-file @tex',
			'--forward-search-line @line',
			'@pdf',
		},
	}
}

local config = vim.deepcopy(default_config)

-- get configuration
M.get = function ()
	return config
end

-- set configuration
M.set = function (opts)
	config = vim.tbl_deep_extend('force', default_config, opts or {})
end


return M
