-- Snippet first: inside an active snippet, <Tab>/<S-Tab> jump between snippet fields even when the
-- completion menu is open (stock AstroNvim moves through the menu first). Outside snippets the
-- behaviour is stock; in a snippet, move through the menu with <C-n>/<C-p> or <C-j>/<C-k>.
-- This reorders AstroNvim's own action lists instead of copying them, so its other actions
-- (e.g. "open the menu after a word") are kept. Delete this file to go back to stock.

---@type LazySpec
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    local function snippet_first(key, jump)
      local actions = vim.tbl_get(opts, "keymap", key)
      if type(actions) ~= "table" then return end
      for i, action in ipairs(actions) do
        if action == jump then
          table.remove(actions, i)
          break
        end
      end
      table.insert(actions, 1, jump)
    end
    snippet_first("<Tab>", "snippet_forward")
    snippet_first("<S-Tab>", "snippet_backward")
  end,
}
