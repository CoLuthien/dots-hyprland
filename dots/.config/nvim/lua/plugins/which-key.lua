return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      -- <leader>l 을 LSP 그룹으로 등록
      { "<leader>l", group = "lsp" },
      -- <leader>c 그룹 제거 (키들을 <leader>l 로 이동했으므로)
      { "<leader>c", group = false },
    },
  },
}
