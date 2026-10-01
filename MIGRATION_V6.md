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
- **Stick to stock AstroNvim wherever possible** (my rule, 2026-10-01): prefer AstroNvim's own
  pins and defaults over local overrides; keep an override only with a proven, current need.
- **Aerial `^4` override dropped** (`lua/plugins/aerial.lua` deleted, 2026-10-01). AstroNvim
  v6.1's `^3` pin gives v3.1.0, which already has the real fix (`f93dcee`, `iter_matches` lists);
  the old "node:start() removed in 0.12" reason was wrong. Evidence in "Step 5" below.
- **Treesitter: AstroCore `opts.treesitter` + nvim-treesitter (option A), tree-sitter-manager
  dropped** (2026-10-01). Reason: gives TS indent, folds, textobjects and the statusline
  indicator, which AstroCore only enables when nvim-treesitter reports the parser; parsers
  install themselves; the nvim-treesitter commit is AstroNvim's tested pin. Never run both
  (shared `site/parser` + `site/queries`). Evidence in "Step 3" below.
- **Keep blink "snippet first"** (`lua/plugins/blink.lua`, tried and kept 2026-10-01). Stock
  `<Tab>` moves through an open menu before jumping snippet fields; inside snippets the
  auto-shown menu got in the way (check 15). The file reorders AstroNvim's own lists to
  `{ snippet_forward, select_next, <show-fn>, fallback }` (same for `<S-Tab>`); in a snippet the
  menu is driven with `<C-n>`/`<C-p>`. Proven need (my feel), so it passes the stock rule.
  Revert = delete the file.
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

## Step 3 evidence (treesitter, 2026-10-01) — decided: A

Test: a fully isolated copy (own `XDG_CONFIG/DATA/STATE/CACHE_HOME` in the scratchpad), with
`treesitter-manager.lua` deleted and `treesitter.lua` replaced by an AstroCore spec
(`opts.treesitter.ensure_installed = { ... }`). `Lazy! sync` cloned nvim-treesitter at the
AstroNvim pin `61df849`; on start it installed 22 parsers (my list + AstroNvim defaults +
community packs) into `stdpath("data")/site/parser`, using `/usr/local/bin/tree-sitter` 0.27.0.
On a Rust buffer:

| feature (Rust buffer)          | A: AstroCore + nvim-treesitter | B: tree-sitter-manager (now) |
|--------------------------------|--------------------------------|------------------------------|
| highlighting                   | yes (tested)                   | yes (v5 today)               |
| TS indent (`indentexpr`)       | yes (tested)                   | no                           |
| TS folds (`astroui.folding`)   | yes (`has_parser` true)        | no                           |
| textobjects `af`/`if`/`]f`     | yes (maps set)                 | no                           |
| statusline TS indicator        | yes (`is_enabled` true)        | no                           |
| parsers installed              | auto (`auto_install = true`)   | by hand (UI)                 |

Why B loses the rest: `astrocore.treesitter.installed()` asks nvim-treesitter
(`astrocore/treesitter.lua:64-67`); with nvim-treesitter disabled `has_parser` is always false,
so AstroCore never enables indent/textobjects and `astroui/folding.lua:22` never uses TS folds.
v5 has the same gap today.

Clash (from source, not a run): both default to `stdpath("data")/site/parser` and `site/queries`
(tree-sitter-manager `config.lua:24-25`; nvim-treesitter wrote `site/queries/rust/highlights.scm`
in the test). Two installers writing the same files at different grammar revisions is the classic
parser/query mismatch: run one or the other, never both.

Notes for the edit (if A): delete `treesitter-manager.lua`; do NOT re-enable the old
`treesitter.lua` (its `commit = "HEAD"` would override AstroNvim's tested pin); put the parser
list in AstroCore `opts.treesitter.ensure_installed` (a plain list merged fine in the test; the
community-pack style `list_insert_unique` is cleaner). `auto_install_cli` only pulls
`tree-sitter-cli` from Mason if `tree-sitter` is missing; keep the brew one (Mason's macOS
binaries can be arm64-only, see `selene`). Test artefact: `ENAMETOOLONG` from `vim.loader`'s
cache on the long scratch path made `recipes.diagnostic-virtual-lines-current-line` fail to load
in that run only; unrelated to treesitter.

### Step 3 done

- `lua/plugins/treesitter-manager.lua` deleted (`Lazy! sync` cleaned the plugin).
- `lua/plugins/treesitter.lua` is now an AstroCore spec adding my parsers with
  `list_insert_unique`: lua vim c cpp bash rust toml ron json. `jsonc` dropped: not a parser in
  nvim-treesitter `main` at the pinned commit (`lua/nvim-treesitter/parsers.lua` has no entry).
- Real v6 install: nvim-treesitter at `61df849`; 22 parsers in
  `~/.local/share/astronvim_v6/site/parser`. Rust buffer: highlighter on, AstroCore
  `has_parser`/`is_enabled` true, TS `indentexpr`, `astroui.folding` foldexpr, `af`/`if`/`]f`
  mapped. Steady-state start: nothing reinstalled, `:messages` empty, no deprecations.
- First start compiles parsers in the background (cpp/cuda/objc take a while). Quitting during
  a compile just restarts that parser next time. One headless run sat at "Compiling parser" for
  280 s without finishing while a later run finished all of them in ~20 s; not explained, no
  leftover processes. Watch the first interactive start.
- The v5 hand-installed set (55 `.dylib`s) is not replicated: `auto_install` fetches the rest on
  first use.

## Step 4 results (AstroCommunity, 2026-10-01)

AstroCommunity at `68db6e1` (main, 2026-09-30). All 21 imports in `lua/community.lua` exist.
Probe `probe_all.lua`: read lazy.nvim's spec warnings (`Config.spec.notifs`), then
`require("lazy").load` every plugin one by one, catch notifies, dump `:messages`. Three runs:

| mode                                   | plugins | spec warnings | load errors | `:messages` |
|----------------------------------------|---------|---------------|-------------|-------------|
| normal                                 | 58      | none          | none        | empty       |
| `--cmd "let g:neovide=v:true"`         | 58      | none          | none        | empty       |
| `g:vscode=1` + stub `vscode` module    | 9       | none          | none        | empty       |

(vscode mode disabling all but 9 plugins is the recipe's design.) No change needed.

### Clean-ups decided and done (2026-10-01): both imports removed from `lua/community.lua`

- **`diagnostics.lsp_lines-nvim` dropped.** lsp_lines (last commit 2024-12-21) overwrites
  `vim.diagnostic.handlers.virtual_lines` (`lsp_lines/init.lua:34`) and only reads its own
  `only_current_line`, so the recipe's native `virtual_lines = { current_line = true }` was
  ignored. Test (fake errors on lines 1 and 3, cursor on 1): with lsp_lines virtual lines under
  both; native handler only under line 1. Also: its `<Leader>uD` hid AstroNvim's "Dismiss
  notifications"; it was a source of the silent `vim.validate{}` deprecation. Now `<Leader>uD`
  = dismiss notifications, `<Leader>uV`/`<Leader>uv` = AstroNvim's virtual lines/text toggles.
- **`recipes.ai` dropped.** It was not inert: it replaced blink's `<Tab>` with
  `{ snippet_forward, ai_accept, fallback }` (no menu cycling); nothing sets `vim.g.ai_accept`
  since Codeium was removed. Now `<Tab>` is AstroNvim's default
  `{ select_next, snippet_forward, show-after-word, fallback }` (resolved from lazy opts).
- After: 57 plugins, load-all probe clean, `:messages` empty; only deprecation left is the
  silent upstream `vim.validate{}` in `mason-null-ls.nvim` `settings.lua:46`.

## Step 5 evidence (leftovers, 2026-10-01) — decided: drop the aerial override

- Deprecation warning: gone since step 2 (`:messages` empty in every probe since).
- **The recorded reason for the aerial `^4` pin was wrong.** `TSNode:start()` is NOT removed in
  nvim 0.12.5: documented in `runtime/doc/treesitter.txt:921`, and
  `nvim --clean` shows `node:start()` works. Real cause of the v5 error: nvim 0.12's
  `Query:iter_matches` returns a *list* of nodes per capture (the old `{ all = false }` option is
  gone); aerial v2 still passed `{ all = false }`, got a list, and called `:start()` on it ->
  "attempt to call method 'start' (a nil value)". Fixed in aerial `f93dcee` "remove use of
  deprecated iter_matches({all = false})", contained in tags v3.1.0 and v4.0.0.
- Proof (`nvim --clean` + v6 parsers, aerial treesitter backend only, Rust + Lua file):
  v2.7.0 fails with the exact v5 error at `helpers.lua:13`; v3.1.0 and v4.0.0 both ok (5 and 1
  symbols). AstroNvim v6.1 pins `^3` -> v3.1.0, which already has the fix.
- v3.1.0 -> v4.0.0: only breaking change is `dd80db7` "drop support for nvim <0.12"; plus elm
  support and `node:range()` in place of `node:start()`.
- In the real v6 install (aerial v4.0.0): `<Leader>lS` opens the outline on Rust and Lua; the
  treesitter backend run directly gives the full symbol list; `:messages` clean.
- Done: `lua/plugins/aerial.lua` deleted; `Lazy! sync` checked out aerial v3.1.0 (`645d108`).
  Same probe on v3.1.0: `<Leader>lS` opens the outline on Rust and Lua, treesitter backend
  `fetch_symbols_sync` ok, `:messages` clean.

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
- [x] 3. Treesitter decision: AstroCore `opts.treesitter` vs keeping tree-sitter-manager (bring
      evidence: does v6's setup install parsers on 0.12.5? do the two clash?).
- [x] 4. AstroCommunity: confirm the 21 imports load cleanly on v6 (`pack.*`, `recipes.ai`,
      `recipes.vscode` first).
- [x] 5. Leftovers: is the deprecation warning gone? does aerial `^4` still work (`<Leader>lS`)?
      (Answer: yes; and the `^4` override was not needed, dropped.)
- [ ] 6. My interactive checks (list below), then delete this file and `CLAUDE.md` and merge `v6` into `main`
      (only on my explicit go; then chezmoi's `--ff-only` pull keeps working).

## Test steps (mine, interactive)

Filled in as steps land. Always start the v6 editor with `NVIM_APPNAME=astronvim_v6 nvim`.
Plain `nvim` must keep starting v5 unchanged.

- Step 2: in a Rust file, `<Leader>uY` toggles semantic highlighting with no warning;
  `:messages` has no "deprecated" line; codelens labels ("Run Test") sit on a virtual line
  above the code; `<Leader>lL` (capital L = run; `<Leader>ll` = refresh) on the `fn` line
  below the label runs it. `<Leader>la` is code actions, a different feature.
- Step 3: in a Rust file: colours look like v5; `vaf` selects the whole function, `]f` jumps to
  the next one; `zc` folds a function (Rust folds come from the LSP first, then treesitter,
  then indent); statusline shows ` TS` (icon U+F192, a dot in a circle). Open a filetype
  with no parser yet (e.g. a `.go` file): it installs on its own, no error.
- Step 4: `s` + two letters jumps (flash); `<Leader>xx` opens Trouble; with two Rust errors:
  cursor on a clean line = end-of-line text on both; cursor on an error line = virtual line
  under it only, and end-of-line text off everywhere. `<Leader>uV` toggles virtual lines,
  `<Leader>uD` dismisses notifications; in the completion menu `<Tab>`/`<S-Tab>` move through
  items, `<Tab>` after a word opens the menu; `:Lazy` shows no red entries. If I use them:
  Neovide starts normally, and VS Code with vscode-neovim works.
- Snippets (blink.lua): inside a snippet `<Tab>`/`<S-Tab>` jump fields even with the menu open;
  `<C-n>`/`<C-p>` drive the menu there.
- Step 5: `<Leader>lS` opens the symbols outline in a Rust and a Lua file; jumping from it to a
  symbol works; `:messages` has no error.

Results 2026-10-01: all 17 checks pass (codelens and statusline icon after correcting my
expectations, see above); snippet-first override tried and kept. Not yet done: Neovide,
VS Code (only if I use them).
