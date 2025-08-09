local M = {}

-- default configuration
local default_config = {
	latex = {
		engine = 'latexmk',
		args = {
			'-pdf',
			'-interaction=nonstopmode',
			'-synctex=1',
			'-verbose',
			'-file-line-error',
			'%f',
		},
	},
	viewer = {
		engine = 'sioyek',
		args = {
			'--reuse-window',
			'--nofocus',
			'--forward-search-file @tex',
			'--forward-search-line @line',
		}
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
