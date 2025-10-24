local M = {}
local uv = vim.uv

-- #####################################################
-- check texconfig path
-- #####################################################

-- get latex distribution
---@return string?
local function get_tex_distribution()
	if vim.fn.executable('initexmf') == 1 then
		return 'miktex'
	elseif vim.fn.executable('tex') == 1 then
		return 'texlive'
	else
		vim.notify('No LaTex distribution found', vim.log.levels.WARN)
		return nil
	end
end

-- check max_print_line in ini file and write them
---@param filepath string .ini file path
local function update_ini(filepath)
	-- open or create file
	local fd = uv.fs_open(filepath, (vim.fn.filereadable(filepath) == 1) and 'r+' or 'w+', 438)
	if not fd then
		vim.notify('TexFlow : Failed to open ' .. filepath, vim.log.levels.ERROR)
		return
	end

	-- read the file contents
	local stat = uv.fs_fstat(fd)
	local contents = ''
	if stat and stat.size > 0 then
		contents = uv.fs_read(fd, stat.size, 0) or ''
	end

	-- check max_print_line is existed
	local max_print_line = contents:match('max_print_line%s*=%s*(%d+)')
	local max_print_line_val = 5000
	if max_print_line then
		max_print_line = tonumber(max_print_line)
		-- do nothing if max_print_line is enough
		if max_print_line >= max_print_line_val then
			uv.fs_close(fd)
			return
		end
		-- modify if max_print_line is not enough
		contents = contents:gsub('max_print_line%s*=%s*%d+', 'max_print_line = ' .. max_print_line_val)
	else
		-- insert if max_print_line is none.
		contents = contents .. '\nmax_print_line = ' .. max_print_line_val .. '\n'
	end

	-- close fd
	uv.fs_ftruncate(fd, 0)       -- flush the previous contents
	uv.fs_write(fd, contents, 0) -- write file with new contents
	uv.fs_close(fd)
end

local function update_ini_async(filepath)
	uv.fs_open(filepath, (vim.fn.filereadable(filepath) == 1) and 'r+' or 'w+', 438, function(err, fd)
		-- deal error
		if err or not fd then
			vim.notify('TexFlow : Failed to open ' .. filepath, vim.log.levels.ERROR)
			return
		end

		-- check the file exists
		uv.fs_fstat(fd, function (_, stat)
			-- the file is valid
			if stat then
				--  read the file contents
				uv.fs_read(fd, stat.size, 0, function(_, contents)
					if not contents then
						contents = ''
					end

					-- check max_print_line is existed
					local max_print_line = contents:match('max_print_line%s*=%s*(%d+)')
					local max_print_line_val = 5000
					if max_print_line then
						max_print_line = tonumber(max_print_line)
						-- do nothing if max_print_line is enough
						if max_print_line >= max_print_line_val then
							uv.fs_close(fd)
							return
						end
						-- modify if max_print_line is not enough
						contents = contents:gsub('max_print_line%s*=%s*%d+', 'max_print_line = ' .. max_print_line_val)
					else
						-- insert if max_print_line is none.
						contents = contents .. '\nmax_print_line = ' .. max_print_line_val .. '\n'
					end

					uv.fs_ftruncate(fd, 0, function (_, success)
						if success then
							uv.fs_write(fd, contents, 0, function (err_write)
								uv.fs_close(fd, function () end)
								if err_write then
									vim.notify('TexFlow : Failed to write *.ini file')
								end
							end)
						end
					end)
				end)
			end
		end)
	end)
end

local function update_ini_sync(filepath)

	-- read the file contents
	local lines = {}
	if vim.fn.filereadable(filepath) == 1 then
		lines = vim.fn.readfile(filepath)
	end

	-- check max_print_line is existed
	local contents = table.concat(lines, '\n')
	local max_print_line = contents:match('max_print_line%s*=%s*(%d+)')
	local max_print_line_val = 5000
	if max_print_line then
		max_print_line = tonumber(max_print_line)
		-- do nothing if max_print_line is enough
		if max_print_line >= max_print_line_val then
			return
		end
		-- modify if max_print_line is not enough
		contents = contents:gsub('max_print_line%s*=%s*%d+', 'max_print_line = ' .. max_print_line_val)
	else
		-- insert if max_print_line is none.
		contents = contents .. '\nmax_print_line = ' .. max_print_line_val .. '\n'
	end

	lines = vim.split(contents, '\n', { plain=true, trimempty=true})
	pcall(vim.fn.writefile, lines, filepath)

end

-- check latex *.init file for miktex and set max_print_line
M.check_max_print_line = function()
	local dist = get_tex_distribution() -- 20ms
	if not dist then
		return
	end
	local cmd_texmfcnf = {'kpsewhich', '-var-value=TEXMFCONFIG'}

	-- update max_print_line
	local update_max_print_line = function(texconfigpath)
		local ini_list = {}
		if dist == 'miktex' then
			texconfigpath = texconfigpath .. '/miktex/config'
			ini_list = {'pdflatex.ini', 'xelatex.ini', 'lualatex.ini', 'latex.ini'}
		elseif dist == 'texlive' then
			ini_list = {'texmf.cnf'}
		end

		for _, file in ipairs(ini_list) do
			vim.schedule(function ()
				update_ini(texconfigpath .. '/' .. file) -- 10~30ms
			end)
		end
	end

	-- get texmfcnf config path and check max_print_line
	vim.fn.jobstart(cmd_texmfcnf,{
		stdout_buffered = true,
		on_stdout = function(_, data)
			if not data or #data == 0 then return end
			local texconfigpath = data[1]:gsub('\\','/')
			texconfigpath = vim.fn.trim(texconfigpath) -- trim carriage return to proper string operation
			update_max_print_line(texconfigpath)
		end,
		on_stderr = function(_, err)
			if err and #err > 0 and err[1] ~= '' then
				vim.notify('TexFlow : kpsewhich error while setup\n ' .. table.concat(err,'\n'), vim.log.levels.ERROR)
			end
		end
	})
end


return M
