-- Treesitter probe: wait for installs, then open a Rust file and report TS state.
local out = vim.env.PROBE_OUT
local f = assert(io.open(out, "w"))
local function log(s) f:write(s .. "\n"); f:flush() end
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  log(("[notify %s] %s"):format(tostring(level), tostring(msg)))
  return orig_notify(msg, level, opts)
end

local function report()
  local buf = vim.api.nvim_get_current_buf()
  log("=== buf " .. vim.api.nvim_buf_get_name(buf) .. " ft=" .. vim.bo.filetype)
  log("highlighter active: " .. tostring(vim.treesitter.highlighter.active[buf] ~= nil))
  local ok, ac = pcall(require, "astrocore.treesitter")
  if ok then
    log("astrocore has_parser: " .. tostring(ac.has_parser(buf)) .. "  is_enabled: " .. tostring(ac.is_enabled(buf)))
  end
  log("indentexpr: " .. vim.bo.indentexpr .. "  foldexpr: " .. vim.wo.foldexpr)
  for _, lhs in ipairs { "af", "if", "]f" } do
    local m = vim.fn.maparg(lhs, lhs:sub(1, 1) == "]" and "n" or "x", false, true)
    log(("map %s: %s"):format(lhs, m.desc or (m.rhs or "<none>")))
  end
  log("parsers on rtp: " .. table.concat(vim.tbl_map(function(p) return vim.fn.fnamemodify(p, ":t") end,
    vim.api.nvim_get_runtime_file("parser/*", true)), " "))
  log("rust highlights.scm files: " .. table.concat(vim.api.nvim_get_runtime_file("queries/rust/highlights.scm", true), " | "))
  log("plugins loaded: nvim-treesitter=" .. tostring(package.loaded["nvim-treesitter"] ~= nil)
    .. " textobjects=" .. tostring(package.loaded["nvim-treesitter-textobjects"] ~= nil)
    .. " tsm=" .. tostring(package.loaded["tree-sitter-manager"] ~= nil))
end

-- wait for installs (ensure_installed / auto_install) then open the Rust file fresh
vim.defer_fn(function()
  vim.cmd.edit(vim.env.PROBE_RS)
  vim.defer_fn(function()
    report()
    log("=== :messages")
    log(vim.api.nvim_exec2("messages", { output = true }).output)
    f:close()
    vim.cmd "qa!"
  end, tonumber(vim.env.PROBE_WAIT2 or "5000"))
end, tonumber(vim.env.PROBE_WAIT1 or "5000"))
