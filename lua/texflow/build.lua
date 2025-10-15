local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')
local Diag = require('texflow.diagnostic')

---@class texflow.job_id
---@field compile number?
---@field viewer number?
local job_id = { -- check job is running
	compile = nil,
	viewer = nil,
}

---@class texflow.valid check valid condition
---@field latex texflow.valid.latex
---@field viewer texflow.valid.viewer
local valid = {
	---@class texflow.valid.latex
	---@field excute boolean?
	---@field autocmd boolean?
	latex = {
		execute = false,
		autocmd = false,
	},

	---@class texflow.valid.viewer
	---@field excute boolean?
	---@field autocmd boolean?
	viewer = {
		execute = false,
		autocmd = false,
	},
}

-- check fidget availability
local fidget_avail, fidget = pcall(require, 'fidget')



-- clear job_id flag when the job is alive only
---@param type string field name of job_id table
local function job_clear(type)
	-- Check if job is actually running
	local status = vim.fn.jobwait({job_id[type]}, 0)
	if status[1] ~= -1 then -- if job is terminated, status is -1
		job_id[type] = nil
		return false
	end
	return true
end


-- set autocmd for viewer, If tex buffer is deleted, the corresponding pdf file viewer is terminated
---@param type string field name of job_id
---@param file texflow.filedata file data
local function set_autocmd(type, file)
	if type == 'viewer' and not job_id.viewer then
		-- stop local function
		local function stop_viewer()
			pcall(vim.fn.jobstop, job_id.viewer)
			job_id.viewer = nil
		end

		-- make autocmd to close job when related tex buffer is closed
		vim.api.nvim_create_augroup('TexFlow.Viewer', {clear = true})
		vim.api.nvim_create_autocmd({'BufDelete'}, {
			group = 'TexFlow.Viewer',
			buffer = file.bufnr,
			once = true,
			callback = stop_viewer,
		})
		vim.api.nvim_create_autocmd({'VimLeave'}, {
			group = 'TexFlow.Viewer',
			pattern = '*',
			once = true,
			callback = stop_viewer,
		})
	end
end

-- check valid condition
---@param type string field name of texflow.valid
---@param file texflow.filedata
---@param opts texflow.config
local function valid_check(type, file, opts)
	-- check job is running
	if type == 'latex' then
		if job_id.compile then
			vim.notify('TexFlow : ' .. type .. ' is running! Please wait to completion', vim.log.levels.WARN)
			return false
		end
	end

	if valid[type].execute then -- if it is valid, don't need to check more.
		return true
	end

	-- check current file is valid tex
	if not Utils.is_tex(file) then
		vim.notify('TexFlow : Execute command on *.tex file only', vim.log.levels.ERROR)
		valid[type].execute = false
		return valid[type].execute
	end

	-- check latex engine
	if not Utils.has_command(opts[type].engine) then
		vim.notify('TexFlow : ' .. opts[type].engine .. 'is not installed', vim.log.levels.ERROR)
		valid[type].execute = false
		return valid[type].execute
	end

	valid[type].execute = true
	return valid[type].execute
end

-- open viewer
---@param file texflow.filedata
---@param opts texflow.config
local function view_core(file, opts)
	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.viewer)

	-- show viewer start
	vim.fn.Texflow_save_server_mapping(Utils.sep_unify(file.fullpath, '/'))
	set_autocmd('viewer', file)
	local jid = vim.fn.jobstart(cmd, {
		cwd = file.filepath,
		detach = false, -- detach = false needs to remove cmd prompt window blinking
		on_exit = function (_, code, _)
			if code ~= 0 then
				if fidget_avail then
					fidget.notify('Fail to open viewer(' .. code .. ')', vim.log.levels.ERROR, { ttl = 1 })
				else
					vim.notify('[TexFlow] Fail to open viewer(' .. code .. ')', vim.log.levels.ERROR)
				end
			end
			job_clear('viewer')
		end}
	)

	-- The first job id recorded when a viewer was created after it was not there
	if not job_id.viewer then
		job_id.viewer = jid
	end
end

-- view pdf file
M.view = function (opts)
	-- get opts
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- get data of file
	local file = Utils.get_filedata()

	-- check valid to execute command
	if not valid_check('viewer', file, opts) then
		return
	end

	-- show view
	view_core(file, opts)
end

-- compile tex file
---@param file texflow.filedata
---@param opts texflow.config
local function compile_core(file, opts)
	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.latex)

	-- show progress message
	local progress
	local progress_title = 'compiling ' .. vim.fn.expand('%:t')
	if fidget_avail then
		progress = fidget.progress.handle.create({
			message = 'start with' .. opts.latex.engine,
			title = progress_title,
			lsp_client = { name = 'texflow.nvim' },
		})
	else
		vim.notify(progress_title .. ' : ' .. 'start with ' .. opts.latex.engine .. '...', vim.log.levels.INFO)
	end

	-- compile start
	job_id.compile = vim.fn.jobstart(cmd, {
		cwd = file.filepath,
		stdout_buffered = false, -- output will be transferred every stdout
		on_stdout = function(_, data, _)
			if type(data) == 'string' then data = {data} end
			-- limit to too long string to 30 characters
			if #data[1] > 30 then data[1] = string.sub(data[1], 1, 30) .. '...' end
			-- show progress
			if fidget_avail then
				progress:report({ message = data[1] })
			else
				vim.notify(progress_title .. ' : ' .. data[1], vim.log.levels.INFO)
			end
		end,
		on_exit = function(_, code, _)
			if code == 0 then
				if fidget_avail then
					progress:report({ message = 'compile completed!' })
					progress:finish()
				else
					vim.notify(progress_title .. ' : ' .. 'compile completed!', vim.log.levels.INFO)
				end

				-- open viewer after compile
				if opts.latex.openAfter then
					view_core(file, opts)
				end

				-- toggle onSave autocmd
				if opts.latex.onSave then
					vim.api.nvim_create_augroup('TexFlow.Compile', {clear = true})
					vim.api.nvim_create_autocmd({'BufWritePost'}, {
						group = 'TexFlow.Compile',
						buffer = file.bufnr,
						callback = function ()
							compile_core(file, opts)
						end,
					})
					valid['latex'].autocmd = true
					vim.notify('TexFlow : compile on save mode ON', vim.log.levels.INFO)
				end
			else
				if fidget_avail then
					progress:report({ message = 'compile ERROR(' .. code .. ')', done = true })
					progress:finish()
				else
					vim.notify(progress_title .. ' : ' ..'compile failed! (' .. code .. ')', vim.log.levels.ERROR)
				end

			end
			-- show diagnostics for error
			Diag.errorCheck(opts)
			job_clear('compile')
		end
	})
end

-- compile file
M.compile = function(opts)
	-- get config
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- get data of file
	local file = Utils.get_filedata()

	-- if opts.latex.onSave set, compile() toggle autocmd
	if valid.latex.autocmd then
		vim.api.nvim_clear_autocmds({
			event = 'BufWritePost',
			buffer = file.bufnr,
			group = 'TexFlow.Compile'
		})
		valid['latex'].autocmd = false
		vim.notify('TexFlow : compile on save mode OFF', vim.log.levels.INFO)
		return
	end

	-- check valid to execute command
	if not valid_check('latex', file, opts) then
		return
	end

	compile_core(file, opts)
end

return M
