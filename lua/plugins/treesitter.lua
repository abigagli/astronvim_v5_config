-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Treesitter

-- NOTE: I TRIED TO FOLLOW https://www.reddit.com/r/neovim/comments/1san03g/treesitter_migration_guide_for_nvim_012_to/
-- and https://www.qu8n.com/posts/treesitter-migration-guide-for-nvim-0-12
-- but gave up and just disabled this plugin and started using treesitter-manager

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  commit = "HEAD",
  lazy = false,
  enabled = false,
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      -- add more arguments for adding more treesitter parsers
      "c",
      "cpp",
      "bash",
      "rust",
      "toml",
      "ron",
      "json",
      "jsonc",
    },
  },
}
