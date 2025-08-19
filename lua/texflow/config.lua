local M = {}

-- default configuration
local default_config = {
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
		focus = true,
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
