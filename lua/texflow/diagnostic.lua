local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')

-- texflow diagnostic id
local ns_name = 'texflow'
local ns_id = vim.api.nvim_create_namespace(ns_name)

-- lua cannot support |(OR) for pattern
local captures = {
	filename   = "^%((.+)$",
	error1     = "^[^:]+:(%d+): (.+)$",
	error2     = "^!%s+l%.(%d+)%s(.+)$",
	warn       = "LaTeX Warning:%s+(.*) on input line (%d+)%.",
	warn_only  = "^LaTeX Warning:%s+[^%d]+%.",
	warn_over  = "^Overfull.*at lines (%d+)",
	warn_under = "^Underfull.*at lines (%d+)",
	warn_other = "^%w+ warning l%.(%d+) (.+)$",
	warn_toc   = "^warning.*",
	warn_pkg   = "^Package (%w+) Warning:.*",
}


---@type table<string, texflow.diagnosticItem[]>
local diagnostics = {} -- show diagnostics in statuscolumn

-- get lnum from pattern if the file is loaded or return nil
---@param filepath string
---@param pattern string
---@return number?
local function get_lnum_from_pattern(filepath, pattern)
	local lnum = nil
	local bufnr = vim.fn.bufnr(filepath)
	if bufnr > 0 then -- if main buffer is opened
		-- detect line number where package name is located
		local lc = vim.api.nvim_buf_line_count(bufnr)
		local line_chunks = 50
		local page_chunks = math.floor(lc/line_chunks)
		for p = 1, page_chunks do
			local start_line = (p-1)*line_chunks
			local end_line = start_line + line_chunks
			local contents = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
			for i, content in ipairs(contents) do
				if string.find(content, pattern) then
					lnum = i
					break
				end
			end
			if lnum then
				break
			end
		end
	end

	return lnum
end

-- add diagnostic
---@param data table output data table from python log parser
local function add_diagnostic(data)
	local hashes = {} -- hash to track duplicated items
	local file = Utils.get_filedata()

	-- remove previous diagnostic messages
	vim.diagnostic.reset(ns_id)
	diagnostics = {}

	-- add item to show diagnostics
	local filepath = ''
	for _, line in ipairs(data) do
		local filename   = {line:match(captures.filename)}
		local error1     = {line:match(captures.error1)}
		local error2     = {line:match(captures.error2)}
		local warn       = {line:match(captures.warn)}
		local warn_only  = {line:match(captures.warn_only)}
		local warn_other = {line:match(captures.warn_other)}
		local warn_over  = {line:match(captures.warn_over)}
		local warn_under = {line:match(captures.warn_under)}
		local warn_toc   = {line:match(captures.warn_toc)}
		local warn_pkg   = {line:match(captures.warn_pkg)}


		-- get diagnostics
		local lnum, msg = nil, nil
		local mtype = nil
		if filename[1] then -- get target filename which shows diagnostic
			-- get absolute path of filename
			local _filename = unpack(filename)
			_filename = string.gsub(_filename, '^[^%w]*/','') -- remove first characters before slash like ./
			-- Relative paths are relative to the path where the latex engine was run.
			_filename = Utils.is_AbsolutePath(_filename) and _filename or vim.fn.fnamemodify(file.compiledir .. '/' .. _filename, ':p')
			filepath = Utils.sep_unify(_filename)
		elseif error1[1] then
			lnum, msg = unpack(error1)
			mtype = vim.diagnostic.severity.ERROR
		elseif error2[1] then
			lnum, msg = unpack(error2)
			mtype = vim.diagnostic.severity.ERROR
		elseif warn[1] then
			msg, lnum = unpack(warn)
			mtype = vim.diagnostic.severity.WARN
		elseif warn_only[1] then -- if line number don't exist, this warning is displayed at 0 row
			msg = unpack(warn_only)
			mtype = vim.diagnostic.severity.WARN
		elseif warn_other[1] then -- like pdfTeX warning
			lnum, msg = unpack(warn_other)
			mtype = vim.diagnostic.severity.WARN
		elseif warn_over[1] then
			msg = line
			lnum = unpack(warn_over)
			mtype = vim.diagnostic.severity.WARN
		elseif warn_under[1] then
			msg = line
			lnum = unpack(warn_under)
			mtype = vim.diagnostic.severity.WARN
		elseif warn_toc[1] then
			msg = line
			mtype = vim.diagnostic.severity.WARN
		elseif warn_pkg[1] then
			-- packages warning which is allocated in miktex runtime file like .sty,
			-- is shown in main file to notify user.
			local pkg = unpack(warn_pkg)
			local pattern = '\\usepackage.*%{' .. pkg .. '%}'
			lnum = get_lnum_from_pattern(file.mainpath, pattern)
			msg = line
			mtype = vim.diagnostic.severity.WARN
		end

		if msg then
			-- if filepath is not in compile directory, the message shows the path too.
			if not string.match(filepath, file.compiledir) then
				msg = 'In ' .. filepath .. '\n' .. msg
				filepath = warn_pkg[1] and file.mainpath or file.filepath
			end

			---@class texflow.diagnosticItem
			---@field lnum number
			---@field col number
			---@field severity number?
			---@field message string
			---@field source string
			---@field namespace number
			local item = {
				lnum = lnum and tonumber(lnum)-1 or 0,
				col = 1,
				severity = mtype,
				message = msg,
				source = ns_name,
				namespace = ns_id,
			}

			-- remove duplicated item
			local key = vim.inspect(item)
			if not hashes[key] then
				hashes[key] = true
				diagnostics[filepath] = diagnostics[filepath] or {} -- create new key
				table.insert(diagnostics[filepath], item)
			end
		end
	end

	if vim.tbl_isempty(diagnostics) then
		return
	end

	for path, diag in pairs(diagnostics) do
		local bufnr = vim.fn.bufnr(path)
		if vim.fn.bufloaded(bufnr) == 1 then -- show diagnostic for loaded buffer
			vim.diagnostic.set(ns_id, bufnr, diag)
		end
	end
end

local function set_diagnostic_autocmd()
	vim.api.nvim_create_augroup('TexFlow.Diagnostics', {clear = true})
	vim.api.nvim_create_autocmd({'BufReadPost'}, {
		group = 'TexFlow.Diagnostics',
		callback = function (args)
			-- args.file is relative of pwd. use nvim_buf_get_name()
			local filepath = Utils.sep_unify(vim.api.nvim_buf_get_name(args.buf))
			if diagnostics[filepath] then
				vim.diagnostic.set(ns_id, args.buf, diagnostics[filepath])
			end
		end,
	})
end

---@param opts texflow.config
local function get_log_core_py(opts)
	local file = Utils.get_filedata()

	-- make cmd
	local cmd = {
		shell = opts.latex.shell,
		shellcmdflag = opts.latex.shellcmdflag,
		engine = vim.g.python3_host_prog,
		args = {
			'@LogParser',
			file.logfile,
		}
	}
	cmd = Utils.replace_cmd_token(cmd)

	-- load job
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)

			-- remove additional \r for windows
			local ndata = {}
			for _, v in ipairs(data) do
				local line = v:gsub('\r', '')
				if line ~= '' then
					table.insert(ndata, line)
				end
			end

			-- add diagnostics
			add_diagnostic(ndata)
			set_diagnostic_autocmd()
		end
	})
end


-- check *.log file to find errors using rg and show to statuscolumn
---@param opts texflow.config
M.errorCheck = function (opts)
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})
	get_log_core_py(opts)
end







return M
