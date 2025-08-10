local M = {}

-- check command is executable
M.has_command = function(cmd)
	return vim.fn.executable(cmd) == 1
end

-- replace @ token from command table
---@param command table config.<command>
M.replace_cmd_token = function(command)
	local file = M.get_filedata(0)
	local cmd_t = vim.list_extend({command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, ' ')
	-- replace token
	cmd_s = cmd_s:gsub('(@texname)', file.filename_only)
				 :gsub('(@tex)', file.filename)
				 :gsub('(@line)', file.line)
	cmd_t = vim.split(cmd_s, ' ', {plain = true, trimempty = true})

	return cmd_t
end

-- get file data
M.get_filedata = function(bufnr)
	local buffer = bufnr or 0

	local line          = vim.api.nvim_win_get_cursor(buffer)[1]
	local fullpath      = vim.api.nvim_buf_get_name(buffer)
	local filepath      = vim.fn.fnamemodify(fullpath, ':h')
	local filename      = vim.fn.fnamemodify(fullpath, ':t')
	local filename_only = vim.fn.fnamemodify(fullpath, ':r')
	local extension     = vim.fn.fnamemodify(fullpath, ':e')

	return {
		line          = line,
		fullpath      = fullpath,
		filepath      = filepath,
		filename      = filename,
		filename_only = filename_only,
		extension     = extension,
	}
end

return M
