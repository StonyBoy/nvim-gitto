-- Steen Hegelund
-- Time-Stamp: 2025-Jan-10 15:08
-- Provide various helper functions
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

---Get the git root path of a given path.
---@param path string
---@return string|nil
function Module.git_toplevel(path)
  local out = vim.fn.systemlist({ 'git', '-C', path, 'rev-parse', '--show-toplevel' })
  if string.match(out[1], '^fatal:') then
    return nil
  end
  return out[1] and vim.trim(out[1])
end

---Get the path to the .git directory.
---@param path string
---@return string|nil
function Module.git_dir(path)
  local out = vim.fn.systemlist({ 'git', '-C', path, 'rev-parse', '--path-format=absolute', '--git-dir' })
  return out[1] and vim.trim(out[1])
end

Module.show_message = function(title, tbl)
  if #tbl > 0 and #tbl[1] > 0 then
    vim.print(title .. ' ' .. vim.inspect(table.concat(tbl, ', ')))
  end
end

Module.answer_yes = function(prompt)
  vim.fn.inputsave()
  local response = string.lower(vim.fn.input(prompt .. ' y/N? ')) == 'y'
  vim.fn.inputrestore()
  return response
end

return Module
