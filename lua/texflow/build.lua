local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')

-- local uv = vim.uv or vim.loop
local job_id = { -- check job is running
	compile = nil,
	viewer = nil,
}

-- compile file
M.compile = function(opts, ext)
	-- check job is running
	if job_id.compile then
		vim.notify('TexFlow : compile is running! Please wait to completion', vim.log.levels.WARN)
		return
	end

	-- get data of file
	local curdir = vim.fn.getcwd()
	local file = Utils.get_filedata()

	-- check current file is valid tex
	if not Utils.is_tex(file) then
		vim.notify('TexFlow : Execute command on *.tex file only', vim.log.levels.ERROR)
		return
	end

	-- get config
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- check latex engine
	if not Utils.has_command(opts.latex.engine) then
		vim.notify('TexFlow : ' .. opts.latex.engine .. 'is not installed', vim.log.levels.ERROR)
		return
	end

	-- move workspace to location of file to compile
	vim.cmd('lcd ' .. file.filepath)

	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.latex)

	-- show progress message
	local ok, fidget = pcall(require, 'fidget')
	local progress
	if ok then
		progress = fidget.progress.handle.create({
			title = 'compiling with ' .. opts.latex.engine .. '...',
			message = vim.fn.expand('%'),
			lsp_client = { name = 'texflow.nvim' }
		})
	else
		vim.print('"' .. vim.fn.expand('%') .. '" compiling with ' .. opts.latex.engine .. '...')
	end

	-- compile start
	job_id.compile = vim.fn.jobstart(cmd, {
		stdout_buffered = true, -- output will be transferred at once when job complete
		on_exit = function(jid, code)
			if code == 0 then
				if ok then
					progress:report({
						title = 'compile completed!',
						done = true,
					})
					progress:finish()
				else
					vim.notify('compile completed!', vim.log.levels.INFO)
				end
			else
				if ok then
					progress:report({
						title = 'compile ERROR(' .. code .. ')',
						done = true,
					})
					progress:finish()
				else
					vim.notify('compile failed! (' .. code .. ')', vim.log.levels.ERROR)
				end
			end

			job_id.compile = nil
			-- restore workspace
			vim.cmd('lcd ' .. curdir)
		end
	})
end

return M
