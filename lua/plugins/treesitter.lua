-- Customize Treesitter
-- AstroNvim v6 drives nvim-treesitter (`main` branch, pinned by AstroNvim) through AstroCore
-- `opts.treesitter` (`:h astrocore`). Parsers missing here are installed on first use
-- (`auto_install = true` in AstroNvim's defaults). Needs the `tree-sitter` CLI (brew).
-- NOTE: `jsonc` is not a parser in nvim-treesitter `main`; `json` is installed instead.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@param opts AstroCoreOpts
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    opts.treesitter.ensure_installed = require("astrocore").list_insert_unique(opts.treesitter.ensure_installed, {
      "lua",
      "vim",
      "c",
      "cpp",
      "bash",
      "rust",
      "toml",
      "ron",
      "json",
    })
  end,
}
