local M = {}
local uv = vim.uv
local has_win32 = vim.fn.has('win32')

-- check command is executable
M.has_command = function(cmd)
	return vim.fn.executable(cmd) == 1
end

-- change separator on directory depends on OS
---@param path string relative path
---@param sep_to string path separator after change
---@param sep_from string path separator before change
local function sep_unify(path, sep_to, sep_from)
	sep_to = sep_to or (has_win32 and '\\' or '/')
	sep_from = sep_from or ((sep_to == '/') and '\\' or '/')
	return path:gsub(sep_from, sep_to)
end
M.sep_unify = sep_unify

-- find files from dir
---@param dir string directory path without '/' at tail.  '.' means current path
---@param file string filename which you want to find <filename.ext> format
local function get_filepath(dir, file)
	-- find files without suffix option / and return all matched files with list
	-- the depth will limited by 2
	local pattern = sep_unify(dir .. '/**/' .. file)
	local files = vim.fn.glob(pattern, false, true)
	if #files == 0 then
		return ''
	end
	return files[1]
end

-- replace @ token from command table
---@param command table config.<command>
M.replace_cmd_token = function(command)
	local sep = ':::::' -- separator between command table component
	local file = M.get_filedata(0)
	local cmd_t = vim.list_extend({command.shell, command.shellcmdflag, command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, sep)
	local pdfpath = ''
	if cmd_s:find('@pdf') then
		pdfpath = get_filepath(file.filepath, file.filename_only .. '.pdf')
	end

	-- replace token
	cmd_s = cmd_s:gsub('(@texname)', file.filename_only)
				 :gsub('(@tex)', file.filename)
				 :gsub('(@line)', file.line)
				 :gsub('(@pdf)', pdfpath)
	cmd_t = vim.split(cmd_s, sep, {plain = true, trimempty = true})

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
