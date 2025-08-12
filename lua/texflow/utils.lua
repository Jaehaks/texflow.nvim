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
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local line          = vim.api.nvim_win_get_cursor(0)[1] -- get cursor of current window
	local fullpath      = vim.api.nvim_buf_get_name(bufnr)
	local filepath      = vim.fn.fnamemodify(fullpath, ':h')
	local filename      = vim.fn.fnamemodify(fullpath, ':t')
	local filename_only = vim.fn.fnamemodify(filename, ':r')
	local extension     = vim.fn.fnamemodify(filename, ':e')

	return {
		line          = line,
		fullpath      = fullpath,
		filepath      = filepath,
		filename      = filename,
		filename_only = filename_only,
		extension     = extension,
		bufnr         = bufnr,
	}
end


-- check valid filetype
M.is_tex = function (file)
	local ft_allow = {'tex', 'plaintex', 'latex'}
	if not vim.tbl_contains(ft_allow, file.extension) then
		return false
	end
	return true
end

return M
