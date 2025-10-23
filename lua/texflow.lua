local M = {}

M.setup = function(opts)
	require("texflow.config").set(opts)
	require("texflow.io").prune_serverdata()
	require("texflow.io").add_serverdata('recent')
end

-- // Proxy pattern
return setmetatable(M, {
	__index = function(_, k)
		return require('texflow.commands')[k]
	end
})
