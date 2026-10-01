-- Load every plugin, log spec-import warnings, load errors, notifies and :messages.
local f = assert(io.open(vim.env.PROBE_OUT, "w"))
local function log(s) f:write(s .. "\n"); f:flush() end
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  log(("[notify %s] %s"):format(tostring(level), tostring(msg)))
  return orig_notify(msg, level, opts)
end

vim.defer_fn(function()
  local Config = require "lazy.core.config"
  log("=== spec notifs (import/merge warnings)")
  for _, n in ipairs(Config.spec.notifs or {}) do log(("  [%s] %s"):format(tostring(n.level), n.msg)) end
  local names, disabled = {}, {}
  for name, _ in pairs(Config.plugins) do names[#names + 1] = name end
  for name, _ in pairs(Config.spec.disabled or {}) do disabled[#disabled + 1] = name end
  table.sort(names); table.sort(disabled)
  log(("=== %d enabled plugins; disabled: %s"):format(#names, table.concat(disabled, ", ")))
  log("=== loading all")
  for _, name in ipairs(names) do
    local ok, err = pcall(require("lazy").load, { plugins = { name } })
    if not ok then log(("  LOAD ERROR %s: %s"):format(name, tostring(err))) end
  end
  vim.defer_fn(function()
    log("=== :messages")
    log(vim.api.nvim_exec2("messages", { output = true }).output)
    f:close()
    vim.cmd "qa!"
  end, 8000)
end, 3000)
