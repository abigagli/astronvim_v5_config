# First run on a new machine

Read this before the first `nvim` start on a machine with no `~/.local/share/nvim` (new laptop,
or after wiping the old data).

## Before you start

- A C compiler (Xcode Command Line Tools on macOS), `curl` and `tar`: nvim-treesitter builds the
  parsers (language grammar libraries) on your machine.
- The `tree-sitter` CLI, version 0.26.1 or later. Optional: `brew install tree-sitter-cli`
  (or the distro package). If it is missing, Mason installs it on its own.

## The problem

The first start on empty data installs plugins at their **latest** commit, not at the versions
AstroNvim pins. Symptom seen on 2026-10-02: nvim-treesitter came out newer than the AstroNvim
pin, no parser got installed, and Rust files had no treesitter colours, indent or `af`/`if`.

Why: AstroNvim loads its pin list with

```lua
{ import = "astronvim.lazy_snapshot", cond = astronvim.config.pin_plugins }
```

(`astronvim/plugins/_astrocore.lua`). On the very first start AstroNvim itself is not on disk
yet, so `pin_plugins` is not set when lazy.nvim reads the plugin list, and the pin list is
skipped. From the second start on, `pin_plugins` is `true`. `lazy-lock.json` is git-ignored, so
there is no lockfile to fall back on either.

## The fix: sync twice, then let the installs finish

```shell
nvim --headless "+Lazy! sync" +qa   # 1st: installs plugins (pins skipped)
nvim --headless "+Lazy! sync" +qa   # 2nd: moves pinned plugins to AstroNvim's commits
nvim some_file.rs                   # open a real file and wait
```

Each sync must be its own `nvim` process (the pin list is read at start).
Mason tools and parsers only start installing once a real file is open (they load on the
`User AstroFile` event, not at startup). A headless `nvim` with no file just sits idle.
Wait until Mason and `[nvim-treesitter]: Installed N/N languages` are done; quitting midway
aborts those installs, and they restart on the next start.

## Check

In `nvim`, these two must print the same commit:

```vim
:lua print(require("lazy.core.config").plugins["nvim-treesitter"].commit)
:!git -C ~/.local/share/nvim/lazy/nvim-treesitter rev-parse HEAD
```

On a Rust file the statusline shows the TS icon, and `:messages` is empty.
