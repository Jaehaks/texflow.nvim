local M = {}

M.setup_commands = function()
  -- vim.keymap.set("n", "<leader>ll", function()
  --   local config = require("mylatex.config").get()
  --   local run = require("mylatex.run")
  --   local file = vim.fn.expand("%:p")
  --   if file:match("%.tex$") then
  --     run.compile_and_view(file, config)
  --   else
  --     vim.notify("TeX 파일이 아닙니다.")
  --   end
  -- end, { desc = "LaTeX 컴파일 & 뷰어" })
end

return M

