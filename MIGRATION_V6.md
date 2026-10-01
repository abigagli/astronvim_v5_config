# AstroNvim v5 -> v6 migration

Working notes for migrating this config on branch `v6`. Delete this file in the last commit
before merging into `main`.

## How to resume

Start Claude Code in `~/.config/astronvim_v6` and say: "continue the v6 migration from
MIGRATION_V6.md". The first unticked box in the checklist is the resume point.

## State

- `~/.config/astronvim_v6` is a `git worktree` of `~/.config/nvim` on branch `v6` (created from
  `main` at `b4f0555`). Run it with `NVIM_APPNAME=astronvim_v6 nvim`; it has its own
  `~/.local/share|state/astronvim_v6` and `~/.cache/astronvim_v6`.
- `main` (= `~/.config/nvim`) stays the working v5 config (AstroNvim v5.3.15). chezmoi pulls
  `main` with `--ff-only` every 168h, so `main` must never diverge from GitHub.
- `v6` is not pushed yet (ask before the first push).
- Neovim v0.12.5. Target: AstroNvim v6.1.0 (`version = "^6"` in `lua/lazy_setup.lua`).
- Guide: https://docs.astronvim.com/configuration/v6_migration/ and
  https://docs.astronvim.com/recipes/treesitter/ (the guide says it may be incomplete).

## Decisions

- **Migrate my config, not the template.** Each step is a commit on `v6`; the end is a merge into
  `main`. Reason: keeps history and my customisations; the guide's own tip allows it.
- **Keep the aerial `^4` override** (`lua/plugins/aerial.lua`). Reason: v6.1.0's
  `lazy_snapshot.lua` still pins `stevearc/aerial.nvim` to `^3`; only aerial v4.0.0 has the fix
  for `node:start()`, removed in nvim 0.12.
- `~/.config/astronvim_v4` deleted 2026-10-01 (clean and pushed to `astronvim_v4_config`).

## Findings so far (2026-10-01)

- None of the guide's renames/removals appear in my config: no `williamboman/`, `Saghen/`,
  `echasnovski/`, catppuccin, ufo, illuminate, neoconf, `:Lsp*` commands, nor AstroLSP root
  `capabilities`/`flags`.
- `lua/plugins/astrolsp.lua`:
  - `handlers` table is empty but its comments describe the v5 style (keyless default
    function, `require("lspconfig")[server].setup(opts)`). v6: default is the `["*"]` key,
    default handler is `vim.lsp.enable`, handlers get only the server name.
  - line ~119 uses `client.supports_method "..."` (dot): likely one source of the
    "client.supports_method is deprecated" warning. 0.12 form: `client:supports_method(...)`.
  - line ~101 calls `vim.lsp.codelens.refresh { bufnr = ... }`: check against nvim 0.12 API.
- v6.1.0 pins `nvim-treesitter` (`main` branch) by commit (`61df849` for nvim 0.12) and
  `nvim-treesitter-textobjects` by commit; treesitter config moves to AstroCore `opts.treesitter`.
  My `lua/plugins/treesitter.lua` disables nvim-treesitter and `treesitter-manager.lua` uses
  `romus204/tree-sitter-manager.nvim` instead.

## Checklist

- [x] 0. Create worktree + branch `v6`, set `version = "^6"`, write this file.
- [ ] 1. First boot: headless `Lazy! sync` in the shadow install; collect every error/warning
      with a probe; record them here.
- [ ] 2. AstroLSP: rewrite `handlers` comments to v6 style, check `config["*"]`, fix
      `supports_method` (dot -> colon) and the codelens call.
- [ ] 3. Treesitter decision: AstroCore `opts.treesitter` vs keeping tree-sitter-manager (bring
      evidence: does v6's setup install parsers on 0.12.5? do the two clash?).
- [ ] 4. AstroCommunity: confirm the 21 imports load cleanly on v6 (`pack.*`, `recipes.ai`,
      `recipes.vscode` first).
- [ ] 5. Leftovers: is the deprecation warning gone? does aerial `^4` still work (`<Leader>lS`)?
- [ ] 6. My interactive checks (list below), then delete this file and merge `v6` into `main`
      (only on my explicit go; then chezmoi's `--ff-only` pull keeps working).

## Test steps (mine, interactive)

Filled in as steps land. Always start the v6 editor with `NVIM_APPNAME=astronvim_v6 nvim`.
Plain `nvim` must keep starting v5 unchanged.
