local M = {}

-- local uv = vim.uv or vim.loop

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

	local cmd_t = vim.list_extend({command.engine}, command.args)
	local cmd_s = table.concat(cmd_t, ' ')
	cmd_s = cmd_s:gsub('@tex', filename):gsub('@line', line) -- replace token
	cmd_t = vim.split(cmd_s, ' ', {plain = true, trimempty = true})

	return cmd_t
end

-- compile file
function M.compile_and_view(config)
	-- get config
	if not config then
		config = require('texflow.config').get()
	end

	-- check latex engine
	if not has_command(config.latex.engine) then
		vim.notify('TexFlowError : ' .. config.latex.engine .. 'is not installed', vim.log.levels.ERROR)
		return
	end

	-- compile
	local cmd = replace_cmd_token(config.latex) -- replace @ token from latex command
	vim.print(cmd)
	vim.fn.jobstart(cmd, {
		stdout_buffered = true, -- output will be transferred at once when job complete
		on_exit = function(jid, code)
			vim.print(cmd)
			-- if code == 0 then
			-- 	local pdf_file = file:gsub("%.tex$", ".pdf")
			-- 	local viewer_args = vim.list_extend({config.viewer}, config.viewer_args)
			-- 	table.insert(viewer_args, pdf_file)
			-- 	vim.fn.jobstart(viewer_args, {detach = true})
			-- 	vim.notify("컴파일 및 뷰어 실행 완료")
			-- else
			-- 	vim.notify("컴파일 실패", vim.log.levels.ERROR)
			-- end
		end
	})
end

return M
