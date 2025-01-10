-- Steen Hegelund
-- Time-Stamp: 2025-Jan-10 14:54
-- Provide a Git commit difference session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local gs = require('git_session')
local GitCommitDiffSession = gs.GitSession:new()

local gfds = require('file_diff_session')

Module.close = function()
  gs.find(vim.api.nvim_get_current_buf()):quit()
end

Module.open = function()
  local ses = gs.find(vim.api.nvim_get_current_buf())
  local commitpath = string.match(vim.api.nvim_get_current_line(), '%d+\t%d+\t([%S]+)')
  if commitpath and ses then
    if ses.from_head then
      gfds.new(ses.cwd, ses.commit, commitpath)
    else
      gfds.new(ses.cwd, ses.commit, commitpath, ses.commit .. '~1')
    end
  end
end

function GitCommitDiffSession:cmd()
  return self.cmdargs
end

function GitCommitDiffSession:get_bufname()
  return  'GitCommitDiff' .. ' #' .. self.commit
end

function GitCommitDiffSession:show_help()
  local difftext = 'The git commit diff session shows the file changes in this commit'

  if self.from_head then
    difftext = 'The git commit diff session shows the file changes between this commit and HEAD'
  end
  local helptext = {
    difftext,
    'From this list it is possible to look at a file diff of single file',
    '',
    'Available Keymaps',
    '  - <F1>: this help message',
    '  - go: open git file diff session',
    '  - gq: close git log session',
    '',
  }
  self:show_help_text(helptext)
end

Module.new = function(cwd, commit, from_head)
  local ses = GitCommitDiffSession:new({
    cwd = cwd,
    commit = commit,
    filetype = 'gitto_commit_diff',
    files = {},
    from_head = from_head,
    cmdargs = {'git', 'show', '--numstat', '--format=full', commit},
    keymap = {
      go = gs.key_handler('commit_diff_session_open', Module.open),
      gq = gs.key_handler('commit_diff_session_close', Module.close),
    }
  })
  if from_head then
    ses.cmdargs = {'git', 'diff', '--numstat', commit}
  end
  return gs.add(ses):run()
end

return Module
