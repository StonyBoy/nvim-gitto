-- Steen Hegelund
-- Time-Stamp: 2022-Apr-08 23:29
-- Provide a Git Log session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local utils = require('utils')
local gs = require('git_session')
local GitLogSession = gs.GitSession:new()

local bs = require('branch_session')
local cs = require('commit_session')
local cds = require('commit_diff_session')

local function buffer_input(pmt)
  print(pmt)
  local key = vim.fn.getchar()
  if key == 13 then
    return
  end
end

-- Create a branch at commit
Module.create_git_branch = function()
  local commitline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  if #commitline < 5 then
    print('Found no commit information')
    return
  end
  local commitid = commitline[2]

  vim.fn.inputsave()
  local branchname = vim.fn.input("new branch: ", "")
  vim.fn.inputrestore()
  gs.find(vim.api.nvim_get_current_buf()):create_branch(branchname, commitid)
end

-- Open a commit session
Module.open_git_commit = function()
  local commitline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  if #commitline < 5 then
    print('Found no commit information')
    return
  end
  local commitid = commitline[2]

  cs.new(gs.find(vim.api.nvim_get_current_buf()).cwd, commitid)
end

-- Open a commit diff session
Module.open_git_commit_diff = function()
  local commitline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  if #commitline < 5 then
    print('Found no commit information')
    return
  end
  local commitid = commitline[2]

  cds.new(gs.find(vim.api.nvim_get_current_buf()).cwd, commitid, false)
end

-- Open a commit diff head session
Module.open_git_commit_diff_head = function()
  local commitline = vim.split(vim.api.nvim_get_current_line(), ' | ')
  if #commitline < 5 then
    print('Found no commit information')
    return
  end
  local commitid = commitline[2]

  cds.new(gs.find(vim.api.nvim_get_current_buf()).cwd, commitid, true)
end

Module.git_log_refresh = function()
  local ses = gs.find(vim.api.nvim_get_current_buf())
  ses.start = 0
  ses:rerun()
end

Module.git_log_continue = function()
  local ses = gs.find(vim.api.nvim_get_current_buf())
  ses.start = ses.start + ses.max
  vim.fn.cursor(vim.fn.line('.') + ses.max, 0)
  ses:continue()
end

-- Open a branch session
Module.open_git_branches = function()
  bs.new(gs.find(vim.api.nvim_get_current_buf()).cwd)
end

Module.close_log_session = function()
  gs.find(vim.api.nvim_get_current_buf()):quit()
end

function GitLogSession:cmd()
  return {'git', 'log', '--format=%D%n | %h | %as | %an | %s', '--decorate=short', '-n', self.max, '--skip='..self.start}
end

function GitLogSession:create_branch(branchname, commitid)
  local cmd = {'git', '-C', self.cwd, 'branch', branchname, commitid}
  local res = vim.fn.systemlist(cmd)
  utils.show_message('Git branch created:'.. branchname, res)
  self:rerun()
end

function GitLogSession:on_event(evt)
  if evt.name == 'checkout' then
    self:rerun()
  end
  if evt.name == 'delete_branch' then
    self:rerun()
  end
end

function GitLogSession:get_bufname()
  return  'GitLog' .. ' #' .. self.buf
end

function GitLogSession:show_help()
  local helptext = {
    'The git log session shows the timeline with commit information: SHA, date, author and subject.',
    'From this list it is possible to look at a single commit, or the files changed from this commit to the currect commit.',
    'It is also possible to open a list of branches.',
    '',
    'Available Keymaps',
    '  - <F1>: this help message',
    '  - go: open git commit session - show the content of the commit',
    '  - gb: open git branch session - show a list of local and remote branches',
    '  - gc: create branch name at commit',
    '  - gd: open git commit diff session - changes in this commit',
    '  - gh: open git commit diff head session - changes from this commit to HEAD',
    '  - gr: refresh the git log',
    '  - gn: get next batch of log entries',
    '  - gq: close git log session',
    '',
  }
  self:show_help_text(helptext)
end

local empty_line_filter = function(item)
  return #item > 0
end

Module.new = function()
  local bufpath = utils.dirname(vim.api.nvim_buf_get_name(0))
  local gitpath = utils.git_toplevel(bufpath)
  if not gitpath then
    print(bufpath, 'is not in a git repo')
    return nil
  end
  local ses = GitLogSession:new({
    cwd = gitpath,
    start = 0,
    max = 100,
    filetype = 'gitto_log',
    keymap = {
      go = gs.key_handler('open_git_commit', Module.open_git_commit),
      gb = gs.key_handler('open_git_branches', Module.open_git_branches),
      gc = gs.key_handler('create_git_branch', Module.create_git_branch),
      gd = gs.key_handler('open_git_commit_diff', Module.open_git_commit_diff),
      gh = gs.key_handler('open_git_commit_diff_head', Module.open_git_commit_diff_head),
      gr = gs.key_handler('git_log_refresh', Module.git_log_refresh),
      gn = gs.key_handler('git_log_continue', Module.git_log_continue),
      gq = gs.key_handler('close_log_session', Module.close_log_session),
    }
  })
  ses.buffer_filter = empty_line_filter
  return gs.add(ses):run()
end

return Module
