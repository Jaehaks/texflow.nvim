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
		cwd = file.filepath,
		stdout_buffered = true, -- output will be transferred at once when job complete
		on_exit = function(_, code, _)
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

				-- open viewer after compile
				if ext and ext.openAfter then
					M.view()
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
		end
	})
end

-- view pdf file
M.view = function (opts)
	-- get data of file
	local curdir = vim.fn.getcwd()
	local file = Utils.get_filedata()

	-- check current file is valid tex
	if not Utils.is_tex(file) then
		vim.notify('TexFlow : Execute command on *.tex file only', vim.log.levels.ERROR)
		return
	end

	-- get opts
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- check viewer engine
	if not Utils.has_command(opts.viewer.engine) then
		vim.notify('TexFlow : ' .. opts.viewer.engine .. 'is not installed', vim.log.levels.ERROR)
		return
	end

	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.viewer)

	-- show progress message
	local ok, fidget = pcall(require, 'fidget')

	-- show viewer start
	job_id.viewer = vim.fn.jobstart(cmd, {
		cwd = file.filepath,
		detach = false, -- detach = false needs to remove cmd prompt window blinking
		on_exit = function (_, code, _)
			if code ~= 0 then
				if ok then
					fidget.notify('Fail to open viewer(' .. code .. ')', vim.log.levels.ERROR, { ttl = 1 })
				else
					vim.notify('[TexFlow] Fail to open viewer(' .. code .. ')', vim.log.levels.ERROR)
				end
			end
		end})

	-- make autocmd to close job when related tex buffer is closed
	vim.api.nvim_create_autocmd({'BufDelete'}, {
		group = 'TexFlow',
		buffer = file.bufnr,
		once = true,
		callback = function ()
			vim.fn.jobstop(job_id.viewer)
			job_id.viewer = nil
		end
	})
	vim.api.nvim_create_autocmd({'VimLeave'}, {
		group = 'TexFlow',
		pattern = '*',
		once = true,
		callback = function ()
			vim.fn.jobstop(job_id.viewer)
			job_id.viewer = nil
		end
	})
end


return M
