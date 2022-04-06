-- Steen Hegelund
-- Time-Stamp: 2022-Mar-06 14:52
-- Provide a Git commit session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local gs = require('git_session')
local GitCommitSession = gs.GitSession:new()

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
    '  - gq: close git commit session',
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
      gq = gs.key_handler('commit_session_close', Module.close),
    }
  })
  return gs.add(ses):run()
end

return Module