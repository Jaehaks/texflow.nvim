local M = {}

M.setup = function(opts)
	require("texflow.config").set(opts)
	vim.fn.Texflow_prune_server_mapping()
	vim.fn.Texflow_save_server_mapping('recent')
end

-- // Proxy pattern
return setmetatable(M, {
	__index = function(_, k)
		return require('texflow.commands')[k]
	end
})
