-- AstroNvim v5 pins aerial to ^2.2, whose treesitter backend calls node:start(),
-- removed in nvim 0.12 ("attempt to call method 'start'"). Fixed in aerial v4.0.0 (68ef6d0).
return { "stevearc/aerial.nvim", version = "^4" }
