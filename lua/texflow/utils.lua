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

return M
