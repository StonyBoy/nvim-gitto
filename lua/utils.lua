-- Steen Hegelund
-- Time-Stamp: 2022-Mar-14 22:54
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

-- Helper function: get the dirname of a filepath
Module.dirname = function(path)
  local strip_dir_pat = '/([^/]+)$'
  local strip_sep_pat = '/$'
  if not path or #path == 0 then
    return
  end
  local result = path:gsub(strip_sep_pat, ''):gsub(strip_dir_pat, '')
  if #result == 0 then
    return '/'
  end
  return result
end

Module.basename = function(filepath, ext)
  local sep = '/'
  local base = filepath
  if base:find(sep) then
    base = base:match(("%s([^%s]+)$"):format(sep, sep))
  end
  if ext then
    return base:match("(.+)%.(.+)")
  else
    return base
  end
end

-- Helper function: join path elements to a full path
Module.path_join = function(...)
    return table.concat(vim.tbl_flatten { ... }, '/')
end

Module.tempdir = function()
   return Module.dirname(vim.fn.tempname())
end

Module.show_message = function(title, tbl)
  if #tbl > 0 and #tbl[1] > 0 then
    print(title, vim.inspect(table.concat(tbl, ', ')))
  end
end

Module.answer_yes = function(prompt)
  vim.fn.inputsave()
  local response = string.lower(vim.fn.input(prompt .. ' y/N? ')) == 'y'
  vim.fn.inputrestore()
  return response
end

return Module
