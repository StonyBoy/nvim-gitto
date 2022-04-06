-- Steen Hegelund
-- Time-Stamp: 2022-Mar-23 17:22
-- Provide a Git commit session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local utils = require('utils')
local gs = require('git_session')
local GitBranchSession = gs.GitSession:new()

Module.checkout = function()
  local branchline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  local bpath = vim.split(branchline[2], '/')
  local branchname = bpath[#bpath]
  gs.find(vim.api.nvim_get_current_buf()):checkout(branchname)
end

Module.delete = function()
  local branchline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  local bpath = vim.split(branchline[2], '/')
  local branchname = bpath[#bpath]

  if utils.answer_yes('Delete branch ' .. branchname) then
    gs.find(vim.api.nvim_get_current_buf()):delete(branchname)
  end
end

Module.refresh = function()
  gs.find(vim.api.nvim_get_current_buf()):rerun()
end

Module.close = function()
  gs.find(vim.api.nvim_get_current_buf()):quit()
end

function GitBranchSession:checkout(branchname)
  local cmd = {'git', '-C', self.cwd, 'checkout', branchname}
  local res = vim.fn.systemlist(cmd)
  if string.match(res[1], '^Switched to branch') then
    self:rerun()
    self:event({
      name = 'checkout', branch = branchname,
    })
  end
  utils.show_message('Git checkout branch:', res)
end

function GitBranchSession:delete(branchname)
  local cmd = {'git', '-C', self.cwd, 'branch', '--delete', '--force', branchname}
  local res = vim.fn.systemlist(cmd)
  if string.match(res[1], '^Deleted branch ') then
    self:rerun()
    self:event({
      name = 'delete_branch', branch = branchname,
    })
  end
  utils.show_message('Git delete branch:', res)
end

function GitBranchSession:cmd()
  return { 'git', 'branch', '-ra', '--format=%(HEAD) | %(refname) | %(objectname) | %(worktreepath) | %(contents:subject)'}
end

function GitBranchSession:get_bufname()
  return  'GitBranches' .. ' #' .. self.buf
end

function GitBranchSession:show_help()
  local helptext = {
    'The git branch session shows the branches in this git repository',
    'From this list it is possible to checkout a branch',
    '',
    'Available Keymaps',
    '  - <F1>: this help message',
    '  - go: checkout the selected branch',
    '  - gd: delete the selected branch',
    '  - gr: refresh the git branch list',
    '  - gq: close git branch session',
    '',
  }
  self:show_help_text(helptext)
end

Module.new = function(cwd)
  local ses = GitBranchSession:new({
    cwd = cwd,
    filetype = 'gitto_branch',
    keymap = {
      go = gs.key_handler('branch_session_checkout', Module.checkout),
      gd = gs.key_handler('branch_session_delete', Module.delete),
      gr = gs.key_handler('branch_session_refresh', Module.refresh),
      gq = gs.key_handler('branch_session_close', Module.close),
    }
  })
  return gs.add(ses):run()
end

return Module
