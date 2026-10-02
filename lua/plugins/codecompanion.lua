-- Customize CodeCompanion (installed by `astrocommunity.ai.codecompanion-nvim`, keys under <Leader>A)
-- The chat talks to Claude Code through the `claude_code` ACP adapter, which spawns the
-- `claude-agent-acp` bridge, which must be on PATH. Install it once per machine (current releases
-- need node >=22):
--   npm install -g @agentclientprotocol/claude-agent-acp
-- With a root-owned npm prefix (e.g. MacPorts node), add `--prefix ~/.local` to avoid sudo.
-- Login: the bridge reuses the existing `claude` CLI login, so no token is needed here.
-- NOTE: ACP adapters are chat-only. Inline (<Leader>Aq, :CodeCompanion) and :CodeCompanionCmd still
-- default to Copilot and will fail until an HTTP adapter (e.g. `anthropic` + API key) is set below.

---@type LazySpec
return {
  "olimorris/codecompanion.nvim",
  opts = {
    -- Model: Claude Code's "default" is used unless overridden. `ga` in the chat switches it for that
    -- session only. To change the default for Neovim's chat only (the terminal `claude` is unaffected),
    -- pass ANTHROPIC_MODEL to the bridge. Values: default, opus[1m], claude-fable-5[1m], sonnet, haiku.
    -- A function is used so the value is taken literally rather than looked up as an env var name.
    -- adapters = {
    --   acp = {
    --     claude_code = function()
    --       return require("codecompanion.adapters").extend("claude_code", {
    --         env = { ANTHROPIC_MODEL = function() return "sonnet" end },
    --       })
    --     end,
    --   },
    -- },
    interactions = {
      chat = { adapter = "claude_code" },
    },
  },
}
