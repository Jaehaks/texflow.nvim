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
	---@field clear_ext table file extensions which is forced clear before tex file is compiled
	---@field openAfter boolean open viewer after compile.
	---@field onSave boolean compile automatically after save
	latex = {
		shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
		shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
		engine = 'latexmk',
		args = {
			-- '-pdf' : Create a output file in .pdf format. If there is no '-pdflatex=' option, use 'pdflatex' as engine
			-- '-pdflatex=' : specific tex engine to create pdf. it overwrite '-pdf' option.
			'-pdf',
			'-interaction=nonstopmode',
			'-synctex=1',
			'-silent', -- small stdout result of compile
			'@maintex',
		},
		-- It you use 'latexmk', `latexmk -c` is called when cleanup_auxfiles() executes.
		-- It will remove aux files except of result files like `.bbl, .synctex.gz, .pdf`.
		-- If you want to remove additional files in result directory, set them in clear_ext.
		-- If you use other latex engine which doesn't support command to clear auxiliary files,
		-- you need to write all aux file extension patterns to remove.
		clear_ext = {
			'%.bbl$',
			'%.synctex%.gz$',
			'%.aux$', -- for aux file of sub tex files
		},
		openAfter = false,
		onSave = false,
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
			'--forward-search-file @maintex',
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
