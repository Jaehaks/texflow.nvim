local M = {}

-- check OS
local WinOS = vim.fn.has('win32') == 1
local function is_WinOS()
	return WinOS
end

-- check command is executable
M.has_command = function(cmd)
	return vim.fn.executable(cmd) == 1
end

-- change separator on directory depends on OS
---@param path string relative path
---@param sep_to string path separator after change
---@param sep_from string path separator before change
local function sep_unify(path, sep_to, sep_from)
	local drive = path:match('^([a-zA-Z]):[\\/]')
	if drive then
		path = drive:upper() .. path:sub(2)
	end
	sep_to = sep_to or (WinOS and '\\' or '/')
	sep_from = sep_from or ((sep_to == '/') and '\\' or '/')
	return path:gsub(sep_from, sep_to)
end
M.sep_unify = sep_unify

-- find files from dir
---@param dir string directory path without '/' at tail.  '.' means current path
---@param file string filename which you want to find <filename.ext> format
local function get_filepath(dir, file)
	-- find files in dir with depth 1 first,
	local pattern = sep_unify(dir .. '/' .. file)
	local files = vim.fn.glob(pattern, false, true)
	if #files > 0 then
		return files[1]
	end
	-- find files in dir after depth 2
	-- find files without suffix option / and return all matched files with list
	-- the depth will limited by 2
	pattern = sep_unify(dir .. '/**/' .. file)
	files = vim.fn.glob(pattern, false, true)
	if #files > 0 then
		return files[1]
	end
	return ''
end

-- get root of this plugin
local plugin_root = nil
local function get_plugin_root()
	if plugin_root then
		return plugin_root
	end

	-- get plugin root from current file
	local cur_file = debug.getinfo(1, 'S').source:match('^@(.+)')
	plugin_root = vim.fs.root(cur_file, {'.git'})

	return plugin_root
end

-- replace @ token from command table
---@param command table config.<command>
M.replace_cmd_token = function(command)
	local sep = ':::::' -- separator between command table component
	local file = M.get_filedata(0)
	local cmd_t = vim.list_extend({command.shell, command.shellcmdflag, command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, sep)

	-- @pdf
	local pdfpath = file.pdffile

	-- @InverseSearch
	local inverseSearchPath = get_plugin_root() .. '/rplugin/python3/InverseSearch.py'
	inverseSearchPath = sep_unify(inverseSearchPath)

	-- @LogParser
	local LogParserPath = get_plugin_root() .. '/rplugin/python3/LogParser.py'
	LogParserPath = sep_unify(LogParserPath)

	-- replace token
	cmd_s = cmd_s:gsub('(@texname)', file.filename_only)
				 :gsub('(@tex)', file.filename)
				 :gsub('(@line)', file.line)
				 :gsub('(@pdf)', pdfpath)
				 :gsub('(@InverseSearch)', inverseSearchPath)
				 :gsub('(@LogParser)', LogParserPath)
				 :gsub('(@servername)', vim.v.servername)
	cmd_t = vim.split(cmd_s, sep, {plain = true, trimempty = true})

	return cmd_t
end

---@class texflow.filedata table includes current state of file
---@field line number line number under the cursor
---@field fullpath string absolute path of the file
---@field filepath string absolute path of parent directory of the file
---@field filename string filename with extension
---@field filename_only string filename without extension
---@field extension string extension of the file
---@field bufnr number buffer number of the file
---@field pdffile string full filepath of pdf file related with tex
---@field logfile string full filepath of log file related with tex
---@field outdir string outdir from latex command

-- get file data
---@param bufnr number?
---@return texflow.filedata
M.get_filedata = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local line          = vim.api.nvim_win_get_cursor(0)[1] -- get cursor of current window
	local fullpath      = vim.api.nvim_buf_get_name(bufnr)
	local filepath      = vim.fn.fnamemodify(fullpath, ':h')
	local filename      = vim.fn.fnamemodify(fullpath, ':t')
	local filename_only = vim.fn.fnamemodify(filename, ':r')
	local extension     = vim.fn.fnamemodify(filename, ':e')
	local pdffile 		= get_filepath(filepath, filename_only .. '.pdf')
	local logfile 		= get_filepath(filepath, filename_only .. '.log')

	return {
		line          = line,
		fullpath      = fullpath,
		filepath      = filepath,
		filename      = filename,
		filename_only = filename_only,
		extension     = extension,
		bufnr         = bufnr,
		pdffile 	  = pdffile,
		logfile 	  = logfile,
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
