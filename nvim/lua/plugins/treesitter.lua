return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- Install parsers
    local parsers = {
      "bash", "c", "go", "gomod", "javascript", "json", "lua",
      "markdown", "markdown_inline", "python", "rust", "toml",
      "tsx", "typescript", "vim", "vimdoc", "yaml",
    }
    for _, parser in ipairs(parsers) do
      pcall(function()
        vim.treesitter.language.add(parser)
      end)
    end

    -- Enable treesitter highlighting
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
