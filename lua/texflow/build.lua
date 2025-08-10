local M = {}

-- local uv = vim.uv or vim.loop
local job_id = { -- check job is running
	compile = nil,
	viewer = nil,
}

-- check command is executable
local function has_command(cmd)
	return vim.fn.executable(cmd) == 1
end

-- replace @ token from command table
---@param command table config.<command>
local function replace_cmd_token(command)
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local filepath = vim.api.nvim_buf_get_name(0)
	local filename = vim.fn.fnamemodify(filepath, ':t')
	local filename_only = vim.fn.fnamemodify(filename, ':r')

	local cmd_t = vim.list_extend({command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, ' ')
	-- replace token
	cmd_s = cmd_s:gsub('(@texname)', filename_only)
				 :gsub('(@tex)', filename)
				 :gsub('(@line)', line)
	cmd_t = vim.split(cmd_s, ' ', {plain = true, trimempty = true})

	return cmd_t
end

-- compile file
M.compile = function(config)
	-- check job is running
	if job_id.compile then
		vim.notify('TexFlow : compile is running! Please wait to completion', vim.log.levels.WARN)
		return
	end

	-- get config
	if not config then
		config = require('texflow.config').get()
	end

	-- check latex engine
	if not has_command(config.latex.engine) then
		vim.notify('TexFlowError : ' .. config.latex.engine .. 'is not installed', vim.log.levels.ERROR)
		return
	end

	-- get command with @token is replaced
	local cmd = replace_cmd_token(config.latex)

	-- show progress message
	local ok, fidget = pcall(require, 'fidget')
	local progress
	if ok then
		progress = fidget.progress.handle.create({
			title = 'compiling with ' .. config.latex.engine .. '...',
			message = vim.fn.expand('%'),
			lsp_client = { name = 'texflow.nvim' }
		})
	else
		vim.print('"' .. vim.fn.expand('%') .. '" compiling with ' .. config.latex.engine .. '...')
	end

	-- compile start
	local cmd = replace_cmd_token(config.latex) -- replace @ token from latex command
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
		end
	})
end

return M
