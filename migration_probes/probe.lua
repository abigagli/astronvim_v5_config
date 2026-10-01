-- Headless probe: log every notify, open a Lua and a Rust file, dump :messages + health-ish info.
local out = vim.env.PROBE_OUT or "/tmp/probe.log"
local f = assert(io.open(out, "w"))
local function log(s) f:write(s .. "\n"); f:flush() end

local levels = { [0] = "TRACE", "DEBUG", "INFO", "WARN", "ERROR" }
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  log(("[notify %s] %s"):format(levels[level or 2] or tostring(level), tostring(msg)))
  return orig_notify(msg, level, opts)
end
local orig_deprecate = vim.deprecate
vim.deprecate = function(name, alt, ver, plugin, backtrace)
  log(("[deprecate] %s -> %s (%s, %s)\n%s"):format(name, tostring(alt), tostring(ver), tostring(plugin),
    debug.traceback("", 2)))
  return orig_deprecate(name, alt, ver, plugin, backtrace)
end

local files = { vim.env.PROBE_LUA, vim.env.PROBE_RS }
local i = 0
local function next_step()
  i = i + 1
  if files[i] then
    log("=== edit " .. files[i])
    local ok, err = pcall(vim.cmd.edit, files[i])
    if not ok then log("[edit error] " .. err) end
    vim.defer_fn(next_step, 8000)
    return
  end
  log("=== doautocmd BufEnter (codelens augroup)")
  vim.cmd "doautocmd BufEnter"
  log("=== LSP clients")
  for _, c in ipairs(vim.lsp.get_clients()) do log("  " .. c.name) end
  log("=== treesitter active on current buf: " .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))
  log("=== feedkeys <Leader>lS (aerial)")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" lS", true, false, true), "m", false)
  vim.defer_fn(function()
    log("=== :messages")
    log(vim.api.nvim_exec2("messages", { output = true }).output)
    f:close()
    vim.cmd "qa!"
  end, 3000)
end
vim.defer_fn(next_step, 3000)
