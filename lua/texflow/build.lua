local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')
local Diag = require('texflow.diagnostic')
local Notify = require('texflow.notify')
local Check = require('texflow.check')

---@class texflow.job_id
---@field compile number?
---@field viewer number?
local job_id = { -- check job is running
	compile = nil,
	viewer = nil,
	cleanup = nil,
}

---@class texflow.valid check valid condition
---@field latex texflow.valid.latex
---@field viewer texflow.valid.viewer
local valid = {
	---@class texflow.valid.latex
	---@field execute boolean
	---@field autocmd boolean
	---@field errored boolean true if compile has error in previous task
	latex = {
		execute = false,
		autocmd = false,
		errored	= false,
	},

	---@class texflow.valid.viewer
	---@field execute boolean
	---@field autocmd boolean
	viewer = {
		execute = false,
		autocmd = false,
	},
}


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
---@param opts texflow.config
local function valid_check(type, opts)
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


	-- check main file is existed.
	-- so you don't need to execute compile while .tex file is focusing. you can do it everywhere in rootdir
	local file = Utils.get_filedata()
	if vim.tbl_isempty(file) then
		vim.notify('TexFlow : filedata cannot be resolved', vim.log.levels.ERROR)
		valid[type].execute = false
		return false
	end

	-- check pdf file is existed.
	if type == 'viewer' then
		if file.pdffile == '' then
			vim.notify('TexFlow : Cannot detect pdf file', vim.log.levels.ERROR)
			valid[type].execute = false
			return false
		end
	end

	-- -- check current file is valid tex
	-- if not Utils.is_tex(file) then
	-- 	vim.notify('TexFlow : Execute command on *.tex file only', vim.log.levels.ERROR)
	-- 	valid[type].execute = false
	-- 	return valid[type].execute
	-- end

	-- check latex engine
	if not Utils.has_command(opts[type].engine) then
		vim.notify('TexFlow : ' .. opts[type].engine .. 'is not installed', vim.log.levels.ERROR)
		valid[type].execute = false
		return valid[type].execute
	end

	-- check max_print_line was set in *.ini file.
	Check.check_max_print_line()

	valid[type].execute = true
	return valid[type].execute
end

-- open viewer
---@param opts texflow.config
local function view_core(opts)
	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.viewer)
	local file = Utils.get_filedata()

	-- show viewer start
	vim.fn.Texflow_save_server_mapping(Utils.sep_unify(file.filepath, '/'))
	set_autocmd('viewer', file)
	local jid = vim.fn.jobstart(cmd, {
		cwd = file.filedir,
		detach = false,      -- detach = false needs to remove cmd prompt window blinking
		on_exit = function (_, code, _)
			if code ~= 0 and job_id.viewer then
				local progress_items = {
					title = 'Opening viewer',
					msg = 'Fail to open viewer(' .. code .. ')',
					loglevel = vim.log.levels.ERROR
				}
				Notify.progress_notify(progress_items)
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
	Utils.update_filedata(0, opts)

	-- check valid to execute command
	if not valid_check('viewer', opts) then
		return
	end

	-- show view
	view_core(opts)
end


-- compile tex file
---@param opts texflow.config
local function compile_core(opts)
	if job_id.compile then
		-- vim.notify('TexFlow : compile is running! Please wait to completion', vim.log.levels.WARN)
		return
	end

	-- get command with @token is replaced
	local cmd = Utils.replace_cmd_token(opts.latex)
	local file = Utils.get_filedata()

	-- show progress message
	local progress_items = {
		title = 'compiling ' .. file.compilename,
		msg = 'start with' .. opts.latex.engine,
		loglevel = vim.log.levels.INFO,
	}
	local progress = Notify.progress_start(progress_items)

	-- compile start
	job_id.compile = vim.fn.jobstart(cmd, {
		cwd = file.compiledir,
		stdout_buffered = false, 	-- output will be transferred every stdout
		on_stdout = function(_, data, _)
			if type(data) == 'string' then data = {data} end
			progress_items.msg = data[1]
			Notify.progress_report(progress, progress_items)
		end,
		on_exit = function(_, code, _)
			if code == 0 then
				progress_items.msg = 'compile completed!'
				Notify.progress_finish(progress, progress_items)
				valid['latex'].errored = false

				-- open viewer after compile
				if opts.latex.openAfter then
					M.view(opts)
				end

				-- toggle onSave autocmd
				if opts.latex.onSave then
					vim.api.nvim_create_augroup('TexFlow.Compile', {clear = true})
					vim.api.nvim_create_autocmd({'BufWritePost'}, {
						group = 'TexFlow.Compile',
						buffer = file.bufnr,
						callback = function ()
							compile_core(opts)
						end,
					})
					valid['latex'].autocmd = true
					vim.notify('TexFlow : compile on save mode ON', vim.log.levels.INFO)
				end
			else
				progress_items.msg = 'compile ERROR(' .. code .. ')'
				progress_items.loglevel = vim.log.levels.ERROR
				Notify.progress_finish(progress, progress_items)
				valid['latex'].errored = true
			end
			-- show diagnostics for error
			Diag.errorCheck(opts)
			job_clear('compile')
		end
	})
end

-- compile file
---@param opts texflow.config
M.compile = function(opts)
	-- get config
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})

	-- get data of file
	Utils.update_filedata(0, opts)

	-- if opts.latex.onSave set, compile() toggle autocmd
	if valid.latex.autocmd then
		vim.api.nvim_clear_autocmds({
			event = 'BufWritePost',
			group = 'TexFlow.Compile'
		})
		valid['latex'].autocmd = false
		vim.notify('TexFlow : compile on save mode OFF', vim.log.levels.INFO)
		return
	end

	-- check valid to execute command
	if not valid_check('latex', opts) then
		return
	end

	-- compile
	compile_core(opts)
end

-- clear aux files in `clear_ext` under all subdirectory of rootdir
---@param opts texflow.config?
---@param cb fun(opts: texflow.config)?
local function remove_clear_ext(opts, cb)
	-- check clear_ext has items
	opts = opts or Config.get()
	if #opts.latex.clear_ext == 0 then
		if cb then cb(opts) end
		return
	end

	local file = Utils.get_filedata()

	-- check outdir
	local delete_files = Utils.scan_dir(file.outdir or file.compiledir, opts.latex.clear_ext)

	-- check auxdir
	if file.auxdir then
		local auxdir_files = Utils.scan_dir(file.auxdir, opts.latex.clear_ext)
		delete_files = vim.list_extend(vim.deepcopy(delete_files), auxdir_files)
	end

	-- delete files, use async method
	Utils.delete_file_async(delete_files, opts, cb)
end


-- clear aux files and compile
---@param opts texflow.config
---@param cb fun(opts: texflow.config)?
M.cleanup_auxfiles = function(opts, cb)
	opts = opts or Config.get()
	local file = Utils.get_filedata()
	if not file.compiledir then
		vim.notify('TexFlow : Compile didn\'t run before clean up', vim.log.levels.ERROR)
		return
	end

	-- set clear command
	local clear_cmd = {}
	if opts.latex.engine == 'latexmk' then
		clear_cmd = {
			'latexmk', '-c',
			file.outdir and ('-outdir=' .. file.outdir) or nil,
			file.auxdir and ('-auxdir=' .. file.auxdir) or nil,
		}
	end
	if #clear_cmd == 0 then
		return
	end

	local progress_items = {
		title = 'clean up auxfile',
		msg = 'start with' .. opts.latex.engine,
		loglevel = vim.log.levels.INFO,
	}
	local progress = Notify.progress_start(progress_items)

	-- clear aux files ind compile after then
	job_id.cleanup = vim.fn.jobstart(clear_cmd, {
		cwd = file.compiledir,
		on_stdout = function(_, data, _)
			if type(data) == 'string' then data = {data} end
			progress_items.msg = data[1]
			Notify.progress_report(progress, progress_items)
		end,
		on_exit = function ()
			-- remove additional files by clear_ext
			remove_clear_ext(opts, function (opt)
				-- update progress
				progress_items.msg = 'clean up completed!'
				Notify.progress_finish(progress, progress_items)

				if cb then cb(opt) end
			end)
		end
	})
end

return M
