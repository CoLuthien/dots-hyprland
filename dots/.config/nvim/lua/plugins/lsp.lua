-- LSP 키맵: <leader>c* → <leader>l* 로 전환
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            -- 기존 <leader>c* 비활성화
            { "<leader>cl", false },
            { "<leader>ca", false },
            { "<leader>cc", false },
            { "<leader>cC", false },
            { "<leader>cr", false },
            { "<leader>cR", false },
            { "<leader>cA", false },
            { "<leader>co", false },

            -- <leader>l* 로 재등록
            { "<leader>ll", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
            { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
            { "<leader>lc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
            { "<leader>lC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", has = "codeLens" },
            { "<leader>lr", function() Snacks.picker.lsp_references() end, desc = "References", has = "references" },
            { "<leader>ln", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
            { "<leader>lR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode = { "n" }, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
            { "<leader>lA", LazyVim.lsp.action.source, desc = "Source Action", has = "codeAction" },
            {
              "<leader>lo",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
              has = "codeAction",
              enabled = function(buf)
                local code_actions = vim.tbl_filter(function(action)
                  return action:find("^source%.organizeImports%.?$")
                end, LazyVim.lsp.code_actions({ bufnr = buf }))
                return #code_actions > 0
              end,
            },

            -- 문서 심볼 (VSCode: gotoSymbol)
            { "<leader>l<Tab>", function() Snacks.picker.lsp_symbols() end, desc = "Document Symbols", has = "documentSymbol" },
          },
        },
      },
    },
  },

  -- clangd: <leader>ch (Switch Source/Header) → <leader>lh
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          keys = {
            { "<leader>ch", false },
            { "<leader>lh", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
        },
      },
    },
  },

  -- Mason: <leader>cm → <leader>lm
  {
    "mason-org/mason.nvim",
    keys = {
      { "<leader>cm", false },
      { "<leader>lm", "<cmd>Mason<cr>", desc = "Mason" },
    },
  },
}
