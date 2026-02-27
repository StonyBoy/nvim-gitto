-- Steen Hegelund
-- Time-Stamp: 2025-Jan-10 14:55
-- Provide a Git commit session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local gs = require('git_session')
local gfds = require('file_diff_session')

local GitCommitSession = gs.GitSession:new()

Module.open = function()
  local ses = gs.find(vim.api.nvim_get_current_buf())
  local commitpath = string.match(vim.api.nvim_get_current_line(), ' (%S+)%s+%| [+-]*')
  if ses then
    if commitpath then
      return gfds.new(ses.cwd, ses.commit, commitpath, ses.commit .. '~1')
    end
    commitpath = string.match(vim.api.nvim_get_current_line(), 'diff %S+ a%/(%S+)%s+b%/%S+')
    if commitpath then
      return gfds.new(ses.cwd, ses.commit, commitpath, ses.commit .. '~1')
    end
    commitpath = string.match(vim.api.nvim_get_current_line(), '[+-]+ %d+ lines: diff %S+ a/(%S+)%s+b/%S+')
    if commitpath then
      return gfds.new(ses.cwd, ses.commit, commitpath, ses.commit .. '~1')
    end
  end
  print('not found:', vim.api.nvim_get_current_line())
end

Module.close = function()
  gs.find(vim.api.nvim_get_current_buf()):quit()
end

function GitCommitSession:cmd()
  return {'git', 'show', '--format=fuller', '-p', '-U', '--stat', self.commit}
end

function GitCommitSession:get_bufname()
  return  'GitCommit' .. ' #' .. self.commit
end

function GitCommitSession:show_help()
  local helptext = {
    'The git commit session shows contents of the commit',
    '',
    'Available Keymaps',
    '  - <F1>: this help message',
    '  - gq / <BS>: close git commit session',
    '',
  }
  self:show_help_text(helptext)
end

Module.new = function(cwd, commit)
  local ses = GitCommitSession:new({
    cwd = cwd,
    commit = commit,
    filetype = 'diff',
    keymap = {
      go = gs.key_handler('commit_session_open', Module.open),
      gq = gs.key_handler('commit_session_close', Module.close),
      ['<BS>'] = gs.key_handler('commit_session_close', Module.close),
    },
    callback = function()
      -- fold diff sections
      vim.cmd [[setlocal foldmethod=expr]]
      vim.cmd [[setlocal foldexpr=getline(v:lnum)=~'^diff'?'>1':1]]
      -- open first section: the commit message
      vim.cmd [[1,1foldopen]]
      -- left arrow to close fold, enter/right arrow to open fold
      vim.api.nvim_buf_set_keymap(0, 'n', '<Left>', 'zc', {
        nowait = true, noremap = true, silent = true
      })
      vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', 'za', {
        nowait = true, noremap = true, silent = true
      })
    end,
  })
  return gs.add(ses):run()
end

return Module
