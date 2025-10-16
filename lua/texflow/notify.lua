local M = {}

-- check fidget availability
local fidget_avail, fidget = pcall(require, 'fidget')

---@class texflow.notify
---@field title string
---@field msg string
---@field fidget_avail boolean
---@field loglevel vim.log.levels

-- create progress message
---@param items texflow.notify
---@return ProgressHandle?
M.progress_start = function(items)
	items.title = items.title or ''
	items.msg = items.msg or ''
	items.fidget_avail = items.fidget_avail or fidget_avail
	items.loglevel = items.loglevel or vim.log.levels.INFO

	local progress = nil
	if items.fidget_avail then
		progress = fidget.progress.handle.create({
			message = items.msg,
			title = items.title,
			lsp_client = { name = 'texflow.nvim' },
		})
	else
		vim.notify(items.title .. ' : ' .. items.msg .. '...', items.loglevel)
	end
	return progress
end

-- update progress message
---@param progress ProgressHandle?
---@param items texflow.notify
M.progress_report = function(progress, items)
	-- limit to too long string to 30 characters
	if #items.msg > 30 then items.msg = string.sub(items.msg, 1, 30) .. '...' end
	if progress then
		progress:report({ message = items.msg })
	else
		vim.notify(items.title .. ' : ' .. items.msg, items.loglevel)
	end
end

---@param progress ProgressHandle?
---@param items texflow.notify
M.progress_finish = function(progress, items)
	if #items.msg > 30 then items.msg = string.sub(items.msg, 1, 30) .. '...' end
	if progress then
		progress:report({ message = items.msg, done = true })
		progress:finish()
	else
		vim.notify(items.title .. ' : ' .. items.msg, items.loglevel)
	end
end

---@param items texflow.notify
M.progress_notify = function(items)
	if items.fidget_avail then
		fidget.notify(items.msg, items.loglevel, { ttl = 1 })
	else
		vim.notify(items.title .. ' : ' .. items.msg, items.loglevel)
	end
end

return M
