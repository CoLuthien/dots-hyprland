-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VSCode-style keymaps (LazyVim 방식)
local map = vim.keymap.set

-- <leader>l (Lazy) → <leader>\ 로 이동, <leader>l 을 LSP prefix로 확보
vim.keymap.del("n", "<leader>l")
map("n", "<leader>\\", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- <leader>cf (Format) → <leader>lf
vim.keymap.del({ "n", "x" }, "<leader>cf")
map({ "n", "x" }, "<leader>lf", function()
  LazyVim.format({ force = true })
end, { desc = "Format" })

-- <leader>cd (Line Diagnostics) → <leader>ld
vim.keymap.del("n", "<leader>cd")
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- <leader>0: 현재 버퍼 닫기 (VSCode: closeActiveEditor)
map("n", "<leader>0", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

-- <leader>1: 다른 창 모두 닫기 (VSCode: closeEditorsInOtherGroups)
map("n", "<leader>1", "<cmd>only<cr>", { desc = "Close Other Windows" })

-- <leader>3: 세로 화면 분할 (VSCode: splitEditor)
map("n", "<leader>3", "<cmd>vsplit<cr>", { desc = "Split Window Right" })


-- <leader><Tab>: 최근 파일 목록 (nowait: tabs 그룹 타임아웃 방지)
map("n", "<leader><Tab>", function()
  Snacks.picker.recent()
end, { desc = "Recent Files", nowait = true })

-- <leader>o: 파일 빠른 열기 (VSCode: quickOpen)
map("n", "<leader>o", function()
  Snacks.picker.files()
end, { desc = "Find Files" })

