local M = {}
local Utils = require('texflow.utils')
local Config = require('texflow.config')

-- texflow diagnostic id
local ns_name = 'texflow'
local ns_id = vim.api.nvim_create_namespace(ns_name)

-- lua cannot support |(OR) for pattern
local captures = {
	error1      = "^[^:]+:(%d+): (.+)$",
	error2      = "^!%s+l%.(%d+)%s(.+)$",
	warn       = "LaTeX Warning:%s+(.*) on input line (%d+)%.",
	warn_only  = "^LaTeX Warning:%s+[^%d]+%.",
	over       = "^Overfull.*at lines (%d+)",
	under      = "^Underfull.*at lines (%d+)",
}


-- add diagnostic
---@param file texflow.filedata
local function add_diagnostic(file, data)
	local hashes = {} -- hash to track duplicated items

	-- remove previous diagnostic messages
	vim.diagnostic.reset(ns_id)

	-- add item to show diagnostics
	local diagnostics = {} -- show diagnostics in statuscolumn
	for _, line in ipairs(data) do
		local error1    = {line:match(captures.error1)}
		local error2    = {line:match(captures.error2)}
		local warn      = {line:match(captures.warn)}
		local warn_only = {line:match(captures.warn_only)}
		local over      = {line:match(captures.over)}
		local under     = {line:match(captures.under)}


		local lnum, msg = nil, nil
		local mtype, col = nil, nil
		if error1[1] then
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
			col = #msg
		elseif over[1] then
			msg = line
			lnum = unpack(over)
			mtype = vim.diagnostic.severity.WARN
		elseif under[1] then
			msg = line
			lnum = unpack(under)
			mtype = vim.diagnostic.severity.WARN
		end

		if msg then
			local item = {
				lnum = lnum and tonumber(lnum)-1 or 0,
				col = col or 0,
				severity = mtype,
				message = msg,
				source = ns_name,
				namespace = ns_id,
			}

			-- remove duplicated item
			local key = vim.inspect(item)
			if not hashes[key] then
				hashes[key] = true
				table.insert(diagnostics, item)
			end
		end
	end

	-- show diagnostics to statuscolumn
	if #diagnostics > 0 then
		vim.diagnostic.set(ns_id, file.bufnr, diagnostics, {replace = false})
	end
end


---@param file texflow.filedata
---@param opts texflow.config
local function get_log_core_py(file, opts)

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
		cwd = file.filepath,
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
			add_diagnostic(file, ndata)
		end
	})
end


-- check *.log file to find errors using rg and show to statuscolumn
---@param opts texflow.config
M.errorCheck = function (opts)
	opts = vim.tbl_deep_extend('force', Config.get(), opts or {})
	local file = Utils.get_filedata() -- get again filedata with updated logfile data

	get_log_core_py(file, opts)
end







return M
