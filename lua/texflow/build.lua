local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')

---@class texflow.job_id
---@field compile number?
---@field viewer number?
local job_id = { -- check job is running
	compile = nil,
	viewer = nil,
}

---@class texflow.valid check valid condition
---@field latex boolean?
---@field viewer boolean?
local valid = {
	latex = false,
	viewer = false,
}

-- check fidget availability
local fidget_avail, fidget = pcall(require, 'fidget')





-- check current job_id is alive
---@param type string field name of job_id table
local function is_job_alive(type)
	local job = job_id[type]
	if not job then
		return false -- if not return false
	end

	-- Check if job is actually running
	local status = vim.fn.jobwait({job}, 0)
	if status[1] ~= -1 then -- job finished but we didn't get notified
		job_id[type] = nil
		return false
	end
	return true
end


-- set autocmd for viewer, If tex buffer is deleted, the corresponding pdf file viewer is terminated
---@param type string field name of job_id
---@param file texflow.filedata file data
local function set_autocmd(type, file)
	vim.print(is_job_alive('viewer'))
	if type == 'viewer' and not is_job_alive('viewer') then
		local function stop_viewer()
			pcall(vim.fn.jobstop, job_id.viewer)
			job_id.viewer = nil
		end

		-- make autocmd to close job when related tex buffer is closed
		vim.api.nvim_create_autocmd({'BufDelete'}, {
			group = 'TexFlow',
			buffer = file.bufnr,
			once = true,
			callback = stop_viewer,
		})
		vim.api.nvim_create_autocmd({'VimLeave'}, {
			group = 'TexFlow',
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

	if valid[type] then -- if it is valid, don't need to check more.
		vim.print('valid check is already')
		return true
	end

	-- check current file is valid tex
	if not Utils.is_tex(file) then
		vim.notify('TexFlow : Execute command on *.tex file only', vim.log.levels.ERROR)
		valid[type] = false
		return valid[type]
	end

	-- check latex engine
	if not Utils.has_command(opts[type].engine) then
		vim.notify('TexFlow : ' .. opts[type].engine .. 'is not installed', vim.log.levels.ERROR)
		valid[type] = false
		return valid[type]
	end

	valid[type] = true
	return valid[type]
end

-- open viewer
---@param file texflow.filedata
---@param opts texflow.config
local function view_core(file, opts)
	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.viewer)

	-- show viewer start
	set_autocmd('viewer', file)
	vim.fn.Texflow_save_server_mapping(Utils.sep_unify(file.fullpath, '/'))
	job_id.viewer = vim.fn.jobstart(cmd, {
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
			job_id.viewer = nil
		end})

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

-- compile file
M.compile = function(opts, ext)
	-- get config
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- get data of file
	local file = Utils.get_filedata()

	-- check valid to execute command
	if not valid_check('latex', file, opts) then
		return
	end

	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.latex)

	-- show progress message
	local progress
	if fidget_avail then
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
				if fidget_avail then
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
					view_core(file, opts)
				end
			else
				if fidget_avail then
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

return M
