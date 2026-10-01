# AstroNvim v5 -> v6 migration

Working notes for migrating this config on branch `v6`. Delete this file and `CLAUDE.md` in the
last commit before merging into `main`.

## How to resume

Start Claude Code in `~/.config/astronvim_v6`: its `CLAUDE.md` imports this file, so the session
starts with it loaded. The first unticked box in the checklist is the resume point.

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
    In v5 the once-per-session warning was traced to the v5-pinned snacks.nvim, vim-illuminate
    and nvim-nio; v6 drops vim-illuminate (replaced by `snacks.words`) and pins snacks `^2`.
  - line ~101 calls `vim.lsp.codelens.refresh { bufnr = ... }`: check against nvim 0.12 API.
- v6.1.0 pins `nvim-treesitter` (`main` branch) by commit (`61df849` for nvim 0.12) and
  `nvim-treesitter-textobjects` by commit; treesitter config moves to AstroCore `opts.treesitter`.
  My `lua/plugins/treesitter.lua` disables nvim-treesitter and `treesitter-manager.lua` uses
  `romus204/tree-sitter-manager.nvim` instead.

## First boot results (step 1, 2026-10-01)

Headless `Lazy! sync` exit 0, 58 plugins, no errors (only cargo/LuaSnip build noise).
`lazy-lock.json` is in `.gitignore`, so the sync leaves no diff. The probe opened
`lua/plugins/astrolsp.lua` and a tiny cargo project's `main.rs`, ran twice (2nd run = steady
state, the same except for mason install notices). Clients attached: null-ls, lua_ls, stylua,
rust-analyzer. **No errors**; `:messages` holds only one line:
`client.supports_method is deprecated`. Every finding, by the step that handles it:

- **Step 2 (AstroLSP)**: the `supports_method` warning comes from **my**
  `lua/plugins/astrolsp.lua:119` (`check_cond`, called from astrolsp `configure_buffer` on
  `LspAttach`); stack trace shows it hits both the none-ls client and nvim's own client. No other
  source in v6, so fixing line 119 should clear the message.
- **Step 3 (treesitter)**: treesitter was not active on the Rust buffer. Cause: the v6 data
  dir has no parsers. v5 has 55 hand-installed ones in `~/.local/share/nvim/site/parser`
  (tree-sitter-manager, `ensure_installed`/`auto_install` both off). Not a v6 bug, but step 3
  must decide how v6 gets its parsers.
- **Step 4 (community)**: `vim.validate{table}` deprecation (silent: target 1.0, not shown in
  `:messages`) from `lsp_lines.nvim` `render.lua:50`, reached via the community recipe
  `diagnostic-virtual-lines-current-line`. Upstream-only; note it, no action.
- **Upstream, no action**: the same silent `vim.validate{table}` deprecation from
  `mason-null-ls.nvim` `settings.lua:46` (called by AstroNvim's own none-ls config).
- **Step 5 (aerial)**: `<Leader>lS` fed in the probe raised no error; the visual check is mine.

## Step 2 results (AstroLSP, 2026-10-01)

Changes in `lua/plugins/astrolsp.lua`, all matching the current AstroNvim template:
- `client.supports_method` -> `client:supports_method` (line 118).
- codelens autocmd: `vim.lsp.codelens.refresh { bufnr }` -> `vim.lsp.codelens.enable(true, { bufnr })`.
  Evidence: nvim 0.12.5 `runtime/lua/vim/lsp/codelens.lua` marks `refresh` `@deprecated`
  (removal 0.13.0, alternative `enable(true, { bufnr })`); `doc/deprecated.txt` says the same.
- `handlers` comments rewritten to v6 style (`["*"]` default, server name only, `vim.lsp.config`).
- `config["*"]`: not used in my config, nothing to change.

Proof: probe (now also fires `doautocmd BufEnter` to hit the codelens autocmd) run on the old
file shows 4x `supports_method` + 1x `codelens.refresh` deprecations and the `:messages` line;
on the new file there are none and `:messages` is empty.

Found on the way (not v6, no action): `selene` fails to spawn (error -86 = wrong CPU type).
Mason's registry gives `darwin_x64` the arm64-only `selene-*-macos.zip`; the v5 install has the
same arm64 binary on this x86_64 Mac.

## How to work with me (rules for every session)

- I work in short slots: keep every step small, commit it on `v6` with a clear message, and
  update this file before stopping.
- Ask before the first push of `v6`. Never push or merge `main` without my explicit go.
- Never change `~/.config/nvim` (branch `main`) nor `~/.local/share|state/nvim`, `~/.cache/nvim`:
  v5 must keep working. Nothing in the chezmoi repo (`~/.local/share/chezmoi`) needs to change.
- Back claims with evidence (plugin source, `git tag --contains`, command output); the guide may
  be wrong.
- Headless probe that works: a Lua file that wraps `vim.notify` to log to a file, feeds keys with
  `vim.defer_fn` + `nvim_feedkeys`, dumps `:messages`, then `qa!`. Run it as
  `NVIM_APPNAME=astronvim_v6 perl -e 'alarm 60; exec @ARGV' nvim --headless -c "luafile probe.lua" file`
  (macOS has no `timeout`). Interactive checks (completion, keys, UI) are mine: give me a short
  list.
- One decision at a time. Plain words; add a four-word plain tag after an unavoidable technical
  term.
- Commands I must run myself: put them in a script file and give me one short `! bash <path>`
  line (long pasted lines get wrapped and break).

## Checklist

- [x] 0. Create worktree + branch `v6`, set `version = "^6"`, write this file.
- [x] 1. First boot: headless `Lazy! sync` in the shadow install; collect every error/warning
      with a probe; record them here.
- [x] 2. AstroLSP: rewrite `handlers` comments to v6 style, check `config["*"]`, fix
      `supports_method` (dot -> colon) and the codelens call.
- [ ] 3. Treesitter decision: AstroCore `opts.treesitter` vs keeping tree-sitter-manager (bring
      evidence: does v6's setup install parsers on 0.12.5? do the two clash?).
- [ ] 4. AstroCommunity: confirm the 21 imports load cleanly on v6 (`pack.*`, `recipes.ai`,
      `recipes.vscode` first).
- [ ] 5. Leftovers: is the deprecation warning gone? does aerial `^4` still work (`<Leader>lS`)?
- [ ] 6. My interactive checks (list below), then delete this file and `CLAUDE.md` and merge `v6` into `main`
      (only on my explicit go; then chezmoi's `--ff-only` pull keeps working).

## Test steps (mine, interactive)

Filled in as steps land. Always start the v6 editor with `NVIM_APPNAME=astronvim_v6 nvim`.
Plain `nvim` must keep starting v5 unchanged.

- Step 2: in a Rust file, `<Leader>uY` toggles semantic highlighting with no warning;
  `:messages` has no "deprecated" line; codelens (e.g. "Run" above `fn main`) still shows.
