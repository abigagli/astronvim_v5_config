-- smart-splits.nvim v3 (2026-09): multiplexer support moved into separate backend plugins.
-- AstroNvim's lazy_snapshot pins "^2"; this overrides it. The WezTerm half (wezterm.lua, chezmoi)
-- already uses smart-splits-nvim/backend-wezterm; this is the Neovim half of the same backend.
-- Herdr: no v3 backend exists (only v2.1.1-final had one); Neovim is not used inside Herdr here
-- (decided 2026-11-17). The plugin moved to smart-splits-nvim/smart-splits.nvim; the old URL below
-- (same as AstroNvim's spec) redirects there, so lazy.nvim sees no URL change.
-- Rex (2026-11-24): community backend rawnly/smart-splits-backend-rex, the Neovim half of the
-- ctrl+hjkl / alt+hjkl keys in Rex's init.lua (chezmoi). Backends are tried in list order, so the
-- same setup works in Rex and in WezTerm. Not pinned on purpose: if a Rex update breaks detection,
-- the fix arrives as a plugin update. That happened once: Rex preview.23 stopped setting REX_SESSION,
-- and the plugin's 0.0.4 (2026-11-25) detects Rex from REX_BLOCK alone.
---@type LazySpec
return {
  "mrjones2014/smart-splits.nvim",
  version = "^3",
  dependencies = {
    { "rawnly/smart-splits-backend-rex", main = "smart-splits-backend-rex", opts = {} },
    { "smart-splits-nvim/backend-wezterm", main = "smart-splits-backend-wezterm", opts = {} },
  },
  opts = {
    mux = { backend = { "smart-splits-backend-rex", "smart-splits-backend-wezterm" } },
  },
}
