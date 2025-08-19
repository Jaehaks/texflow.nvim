local M = {}
local Utils = require('texflow.utils')
-- INFO: This file is unused.
-- We made this file to add current servername to server file.
-- Python file manage server file also, so it needs to match there form to rewrite server file between python and lua.
-- lua's vim.json.encode/decode works fine and it is compatible with json file which is made by python's json package
-- But the form is different. lua encodes the json file with one line (compressed form).
-- you can use `jq` to view the json file, but it is more convenient to check server file without jq.
-- Python's json package writes contents using json indented format.
-- so Using python integration with lua, use python implementation instead of this file
-- but this file is remained to remember what we studied


-- set texflow server file
local serverfile = vim.fn.stdpath('data')
serverfile = serverfile ..  '/texflow/texflow_server.json'
serverfile = Utils.sep_unify(serverfile)

-- JSON file processing function
---@return table json data table from serverfile
local function load_serverdata()
	-- Create the directory if it does not exist
	if vim.fn.filereadable(serverfile) ~= 1 then
        local dir = vim.fs.dirname(vim.fn.fnamemodify(serverfile, ':h'))
        vim.fn.mkdir(dir, 'p')
		return {}
	end

	-- check the json file has contents
	-- use io.open / read() to remain json indented form to compatible python
	local file = io.open(serverfile, 'r')
	if not file then
		return {}
	end

	-- read contents
	local contents = file:read('*a')
	io.close(file)

	if not contents or #contents == 0 then
		vim.notify('TexFlow: Cannot read texflow_server.json file', vim.log.levels.WARN)
		return {}
	end

	local ok, json_data = pcall(vim.json.decode, contents)
	if ok and type(json_data) == 'table' then
		return json_data
	else
		return {}
	end
end


-- add servername of current neovim instance to serverfile
---@param filepath string tex file path which is corresponding with servername
M.add_serverdata = function(filepath)
	local data = load_serverdata()

    -- update current active neovim instance servername to json file
	filepath = Utils.sep_unify(filepath, '/')
	data[filepath] = vim.v.servername

	-- native vim library only supports compressed json format, but it can be read by python
    local json_data = {vim.json.encode(data)}
    local ok, err = pcall(vim.fn.writefile, json_data, serverfile)
	if not ok then
        print("TexFlow: Failed to write file, " .. (err or "Unknown error"))
    end
end


M.prune_serverdata = function ()
	local data = load_serverdata()

	-- check the server is alive
	for key, servername in pairs(data) do
		local ok, chan = pcall(vim.fn.sockconnect, 'pipe', servername, {rpc = false})
		if not ok or chan <= 0 then -- delete dead keys from texflow server
			data[key] = nil
		else
			vim.fn.chanclose(chan) -- close activation
		end
	end

	-- write
    local json_data = {vim.json.encode(data)}
    local ok, err = pcall(vim.fn.writefile, json_data, serverfile)
	if not ok then
        print("TexFlow: Failed to write file, " .. (err or "Unknown error"))
    end
end


return M

