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
---@param path string|string[] relative path
---@param sep_to string path separator after change
---@param sep_from string path separator before change
local function sep_unify(path, sep_to, sep_from)
	local results = {}
	local filepaths = {}
	if type(path) == 'string' then
		filepaths = {path}
	else
		filepaths = path
	end

	sep_to = sep_to or (WinOS and '\\' or '/')
	sep_from = sep_from or ((sep_to == '/') and '\\' or '/')
	for _, filepath in ipairs(filepaths) do
		local drive = filepath:match('^([a-zA-Z]):[\\/]')
		if drive then
			filepath = drive:upper() .. filepath:sub(2)
		end
		results[#results+1] = filepath:gsub(sep_from, sep_to)
	end
	if #results == 1 then
		return results[1]
	end
	return results
end
M.sep_unify = sep_unify

-- scan and get files in rootdir recursively
---@param rootdir string
---@param patterns string[] regex pattern which include in result
---@return string[]
local function scan_dir(rootdir, patterns)
	local results = {}
	local fs = vim.uv.fs_scandir(rootdir)
	if not fs then return results end
	while true do
		local filename, filetype = vim.uv.fs_scandir_next(fs)
		if not filename then break end
		local filepath = rootdir .. '/' .. filename
		if filetype == 'directory' then
			vim.list_extend(results, scan_dir(filepath, patterns))
		else
			for _, pattern in ipairs(patterns) do
				local ok = filename:match(pattern)
				if ok then
					results[#results+1] = sep_unify(filepath)
					break
				end
			end
		end
	end
	return results
end
M.scan_dir = scan_dir

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

local cand_rcfiles = {'.latexmkrc', 'latexmkrc', 'Tectonic.toml'}
-- get root directory of this project
---@param bufnr integer buffer number
---@return string root directory
local function get_rootdir(bufnr)
	---@return vim.lsp.Client[]
	local clients = vim.lsp.get_clients({bufnr = bufnr, name = 'texlab'}) -- check lsp is attached
	local root = nil
	if not vim.tbl_isempty(clients) then
		root = clients[1].config.root_dir
	else
		root = vim.fs.root(bufnr, cand_rcfiles)
	end
	root = root or vim.fn.expand('%:p:h')
	return sep_unify(root)
end


-- check the argument path is absolute path
---@param path string
---@return boolean
local function is_AbsolutePath(path)
	if is_WinOS() then
		return path:match('^[%w]:[\\/]') ~= nil
	else
		return path:match('^/') ~= nil
	end
end
M.is_AbsolutePath = is_AbsolutePath

-- check the file is readable
---@param filepath string
---@return boolean
local function is_filereadable(filepath)
	return vim.fn.filereadable(filepath) == 1
end
M.is_filereadable = is_filereadable

-- delete file if it is existed
---@param filepath string
---@return number 0:success, 1:failed, 2:not existed
M.delete_file = function (filepath)
	if is_filereadable(filepath) then
		return vim.fn.delete(filepath)
	end
	return -2
end

M.delete_file_async = function (files, opts, cb)
	opts = opts or require('texflow.config').get()
	if #files == 0 then
		if cb then cb(opts) end
		return
	end

	-- delete files, use async method
	local total = #files
	local done = 0
	for _, delete_file in ipairs(files) do
		vim.uv.fs_unlink(delete_file, vim.schedule_wrap(function (err)
			if err then
				vim.notify(vim.fn.fnamemodify(delete_file, ':t') .. ' cannot be deleted automatically, manual deleteion is required', vim.log.levels.WARN)
			end

			done = done + 1
			if done == total and cb then
				cb(opts)
			end
		end))
	end
end

-- search whether magic comment like '% !TEX root = main.tex' exists in current file
---@return string? absolute path of main file
local function search_main_in_magic_comment()
	local lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] -- check first line in current buffer
	local file = lines:match('^%%%s*!%s*[Tt][Ee][Xx]%s+[Rr][Oo][Oo][Tt]%s*%=%s*(.+)$')
	if file then
		file = vim.fn.trim(file) -- remove white space of both side
		local mainfile = ''
		if is_AbsolutePath(file) then
			mainfile = file
		else -- get absolute path from relative path based on current buffer location
			-- '!TEX root' recognizes the main file which is relative path is based on the sub-file.
			local curdir = vim.fn.expand('%:p:h')
			mainfile = vim.fn.fnamemodify(curdir .. '/' .. file, ':p')
		end

		-- check the file is real.
		if is_filereadable(mainfile) then
			return sep_unify(mainfile)
		else
			vim.notify('ERROR : main file ' .. file .. ' cannot be found using !TEX comment ', vim.log.levels.ERROR)
			return ''
		end
	end
	return nil
end

-- get line content which pattern is matched with from file.
---@param filepath string absolute path of file
---@param patterns string|table pattern to find in file, it can allow 1 capture
---@return string? line which is matched whit pattern
local function search_pattern_in_file(filepath, patterns)
	-- read file contents
	local ok, lines = pcall(vim.fn.readfile, filepath)
	if not ok then
		return nil
	end
	local contents = table.concat(lines, '\n')

	-- find line that matches pattern in file
	if type(patterns) == 'string' then
		patterns = {patterns}
	end
	for _, pattern in ipairs(patterns) do
		local matched = contents:match(pattern)
		if matched then
			return matched
		end
	end
	return nil
end

---@param rootdir string root directory of latex project
---@param opts texflow.config
---@return string? main file list
local function search_main_in_rc(rootdir, opts)
	-- check main file is set in rcfile
	---@param filename string rcfile name
	---@param patterns table pattern to get main file in rcfile, it needs to include (.+) to capture the main file name only.
	local function is_mainfile(filename, patterns)
		local rcfile = sep_unify(rootdir .. '/' .. filename)
		if is_filereadable(rcfile) then
			local matched = search_pattern_in_file(rcfile, patterns)
			if matched then
				local mainfiles = vim.split(matched, ',', {plain = true, trimempty = true})
				-- viewer will has option like 'use this window' to implement forward search.
				-- If there are multiple independent files to compile and open viewer,
				-- the later viewer will opens by covering previous one. It is confused.
				-- So It is  better to limit the number of main file to 1.
				if #mainfiles > 1 then
					vim.notify('ERROR : More than 2 main files are set in ' .. filename .. '. reduce to 1', vim.log.levels.ERROR)
					return ''
				end
				local mainfile = mainfiles[1]
				mainfile = vim.fn.trim(mainfile) -- remove whitespace
				mainfile = mainfile:gsub('"', ''):gsub("'", "") -- remove quotes
				mainfile = vim.fn.fnamemodify(mainfile, ':t') -- get file name only
				local mainfilepath = vim.fs.find(mainfile, { path = rootdir, type = 'file', limit = 1, })[1] -- get full path
				mainfilepath = sep_unify(mainfilepath)

				if is_filereadable(mainfilepath) then
					return mainfilepath
				else
					vim.notify('ERROR : main file ' .. mainfile .. ' cannot be found using !TEX comment ', vim.log.levels.ERROR)
					return ''
				end
			end
		end
		return nil
	end

	if opts.latex.engine == 'latexmk' then
		for _, filename in ipairs({'.latexmkrc', 'latexmkrc'}) do
			local mainfile = is_mainfile(filename, {
				"^@default_files%s*%=%s*%((.+)%)%s*;",  -- @default_files = ('main.tex')
			})
			if mainfile then return mainfile end
		end
	elseif opts.latex.engine == 'tectonic' then
		for _, filename in ipairs({'Tectonic.toml'}) do
			local mainfiles = is_mainfile(filename, {
				"^@inputs%s*%=%s*%[(.+)%]",  -- inputs = ['main.tex'], must use one line format.
			})
			if mainfiles then return mainfiles end
		end
	end
	return nil
end

---@param rootdir string
---@return string? main file list
local function search_documentclass(rootdir)
	-- find \documentclass in current file
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local contents = table.concat(lines, '\n')
	local matched = contents:match('\\documentclass')
	if matched then
		return sep_unify(vim.api.nvim_buf_get_name(0))
	end

	-- find \documentclass for other files in rootdir
	local tex_files = scan_dir(rootdir, {'%.tex$'}) -- get all .tex file and output to table
	for _, file in ipairs(tex_files) do
		local content = table.concat(vim.fn.readfile(file, '', 100), '\n') -- get 100 lines at top
		if content:match('\\documentclass') then
			return sep_unify(file)
		end
	end

	return nil
end

-- get main files
---@param rootdir string absolute path of project root
---@param opts texflow.config
---@return string? absolute path of main tex file
local function get_mainfile(rootdir, opts)

	-- 1) latexmkrc takes precedence over '!TEX root'
	-- 2) If there are no any comment about main file, It detects using documentclass

	local mainfile = search_main_in_rc(rootdir, opts)     -- First, check rcfile
	if mainfile == '' then -- if it has error, quit searching main file
		return nil
	elseif mainfile then
		return mainfile
	end

	mainfile = search_main_in_magic_comment() -- Second, check !TEX comment
	if mainfile == '' then
		return nil
	elseif mainfile then
		return mainfile
	end

	mainfile = search_documentclass(rootdir)  -- Third, check \documentclass
	if mainfile == '' then
		return nil
	elseif mainfile then
		return mainfile
	end

	return nil
end
M.get_mainfile = get_mainfile

-- replace @ token from command table
---@param command table config.<type>
M.replace_cmd_token = function(command)
	local sep = ':::::' -- separator between command table component
	local file = M.get_filedata()
	local cmd_t = vim.list_extend({command.shell, command.shellcmdflag, command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, sep)

	-- @InverseSearch
	local inverseSearchPath = get_plugin_root() .. '/rplugin/python3/InverseSearch.py'
	inverseSearchPath = sep_unify(inverseSearchPath)

	-- @LogParser
	local LogParserPath = get_plugin_root() .. '/rplugin/python3/LogParser.py'
	LogParserPath = sep_unify(LogParserPath)

	-- replace token
	cmd_s = cmd_s:gsub('(@texname)', file.filename_only)
				 :gsub('(@curtex)', file.filename)
				 :gsub('(@maintex)', file.mainname)
				 :gsub('(@line)', file.line)
				 :gsub('(@pdf)', file.pdffile)
				 :gsub('(@InverseSearch)', inverseSearchPath)
				 :gsub('(@LogParser)', LogParserPath)
				 :gsub('(@servername)', vim.v.servername)
	cmd_t = vim.split(cmd_s, sep, {plain = true, trimempty = true})

	return cmd_t
end

---@class texflow.filedata table includes current state of file
---@field line number line number under the cursor
---@field rootdir string absolute path of project root
---@field filepath string absolute path of current file
---@field filedir string absolute path of parent directory of current file
---@field filename string current filename with extension
---@field filename_only string current filename without extension
---@field fileext string extension of current file
---@field mainpath string absolute path of main tex file
---@field maindir string absolute path of directory where main tex file is.
---@field mainname string filename with extension of main tex file.
---@field mainname_only string filename without extension of main tex file.
---@field compiledir string absolute path where compile is executed
---@field compilename string filename where compile executes
---@field compilename_only string filename only  where compile executes
---@field bufnr number buffer number of current file
---@field pdffile string full filepath of pdf file related with tex
---@field logfile string full filepath of log file related with tex
---@field outdir string outdir from latex command
---@field auxdir string auxdir from latex command
local filedata = {}

-- get file data
---@param bufnr number?
---@param opts texflow.config
M.update_filedata = function(bufnr, opts)
	filedata = {}
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local rootdir = get_rootdir(0)

	local line          = vim.api.nvim_win_get_cursor(0)[1] -- get cursor of current window
	local filepath      = vim.api.nvim_buf_get_name(bufnr)
	local filedir       = vim.fn.fnamemodify(filepath, ':h')
	local filename      = vim.fn.fnamemodify(filepath, ':t')
	local filename_only = vim.fn.fnamemodify(filename, ':r')
	local fileext       = vim.fn.fnamemodify(filename, ':e')

	local mainpath 		= get_mainfile(rootdir, opts)
	if not mainpath then
		vim.notify('ERROR : main tex file cannot be detected!')
		return
	end
	local maindir       = vim.fn.fnamemodify(mainpath, ':h')
	local mainname      = vim.fn.fnamemodify(mainpath, ':t')
	local mainname_only = vim.fn.fnamemodify(mainname, ':r')

	-- get outdir/auxdir from latex command args
	-- WARNING: Don't use @token in `-outdir` or `-auxdir`
	local outdir, auxdir = nil, nil
	local compilename_only, compilename, compiledir = nil, nil, nil
	for _, arg in ipairs(opts.latex.args) do
		-- If current file is not tex file when you set @curtex, abort.
		if string.match(arg, '@curtex') and fileext ~= 'tex' then
			vim.notify('ERROR : current file is not *.tex file')
			return
		end

		-- set outdir / auxdir
		outdir = outdir or string.match(arg, '^%-outdir%s*=?%s*(.*)')
		auxdir = auxdir or string.match(arg, '^%-auxdir%s*=?%s*(.*)')

		-- set variable related with compile location
		if not compiledir and string.match(arg, '@curtex') then
			compiledir = filedir
			compilename = filename
			compilename_only = filename_only
		elseif not compiledir and string.match(arg, '@maintex') then
			compiledir = maindir
			compilename = mainname
			compilename_only = mainname_only
		end
	end
	outdir = outdir and (compiledir .. '/' .. outdir)
	auxdir = auxdir and (compiledir .. '/' .. auxdir)
	outdir = outdir and sep_unify(outdir)
	auxdir = auxdir and sep_unify(auxdir)

	-- get output file path
	local pdffile = sep_unify((outdir or compiledir) .. '/' .. compilename_only .. '.pdf')
	local logfile = sep_unify((auxdir or (outdir or compiledir)) .. '/' .. compilename_only .. '.log')

	filedata = {
		line             = line,
		rootdir          = rootdir,
		filepath         = filepath,
		filedir          = filedir,
		filename         = filename,
		filename_only    = filename_only,
		fileext          = fileext,
		mainpath         = mainpath,
		maindir          = maindir,
		mainname         = mainname,
		mainname_only    = mainname_only,
		compiledir       = compiledir,
		compilename      = compilename,
		compilename_only = compilename_only,
		bufnr            = bufnr,
		pdffile          = pdffile,
		logfile          = logfile,
		outdir           = outdir,
		auxdir           = auxdir,
	}
end

---@return texflow.filedata
M.get_filedata = function ()
	return filedata
end


-- check valid filetype
M.is_tex = function ()
	local ft_allow = {'tex', 'plaintex', 'latex'}
	if not vim.tbl_contains(ft_allow, vim.bo.filetype) then
		return false
	end
	return true
end

return M
