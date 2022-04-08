-- Steen Hegelund
-- Time-Stamp: 2022-Apr-08 23:33
-- Provide a Git commit difference session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local utils = require('utils')
local gs = require('git_session')
local GitFileDiffSession = gs.GitSession:new()

function GitFileDiffSession:set_buf_keymaps(buf)
  for k, v in pairs(self.keymap) do
    vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua '..v..'<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end
end

Module.close = function()
  local buf = vim.api.nvim_get_current_buf()
  for idx, session in ipairs(gs._sessions) do
    if (session.left_buf == buf or session.right_buf == buf) then
      table.remove(gs._sessions, idx)
      session:close()
    end
  end
end

function GitFileDiffSession:close()
  vim.api.nvim_buf_delete(self.left_buf, {force = true})
  if not self.keep_right then
    vim.api.nvim_buf_delete(self.right_buf, {force = true})
  else
    vim.cmd('tabclose')
  end
end

function GitFileDiffSession:run()
  -- Open a new tab with two files
  -- Read into the left buffer the file from the git commit
  -- Open the local file in the right buffer
  self.name = utils.basename(self.commitpath, false)
  self:load_left_buffer()
  self:load_right_buffer()
end

function GitFileDiffSession:set_win_options(win)
  vim.api.nvim_win_set_option(win, 'diff', true)
  vim.api.nvim_win_set_option(win, 'scrollbind', true)
  vim.api.nvim_win_set_option(win, 'cursorbind', true)
  -- vim.api.nvim_win_set_option(win, 'scrollopt', { "ver", "hor", "jump" })
  vim.api.nvim_win_set_option(win, 'foldmethod', 'diff')
  vim.api.nvim_win_set_option(win, 'foldcolumn', '1')
  vim.api.nvim_win_set_option(win, 'foldlevel', 0)
end

Module.is_file_loaded = function(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      if path == vim.api.nvim_buf_get_name(buf) then
        return buf
      end
    end
  end
  return nil
end

function GitFileDiffSession:load_left_buffer()
  vim.cmd('tabnew')
  self.tabpage = vim.api.nvim_get_current_tabpage()
  self.left_win = vim.api.nvim_get_current_win()
  self.left_buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_win_set_buf(self.left_win, self.left_buf)
  self.left_path = 'git://' .. self.commit .. '/' .. self.commitpath
  vim.api.nvim_buf_set_name(self.left_buf, self.left_path)
  local cmd = {'git', '-C', self.cwd, 'show', self.commit .. ':' .. self.commitpath }
  print('left buffer', self.left_path, vim.inspect(cmd))
  gs.cmd_append_buffer(cmd, self.cwd, self.left_buf)
  vim.api.nvim_buf_set_option(self.left_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(self.left_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(self.left_buf, 'bufhidden', 'wipe')
  self:set_win_options(self.left_win)
  self:set_buf_keymaps(self.left_buf)
  vim.cmd('filetype detect')
end

function GitFileDiffSession:load_right_buffer()
  vim.cmd('belowright vsp')
  self.right_win = vim.api.nvim_get_current_win()
  self.right_path = utils.path_join(self.cwd, self.commitpath)
  local buf = Module.is_file_loaded(self.right_path)
  if buf then
    self.keep_right = true
    vim.api.nvim_set_current_buf(buf)
  else
    vim.cmd('edit '.. self.right_path)
  end
  self.right_buf = vim.api.nvim_get_current_buf()
  print('right buffer', self.right_path)
  self:set_win_options(self.right_win)
  self:set_buf_keymaps(self.right_buf)
end

function GitFileDiffSession:cmd()
  return {'git', 'diff', '--stat', self.commit}
end

function GitFileDiffSession:get_bufname()
  return  'GitFileDiff' .. ' #' .. self.commit
end

Module.new = function(cwd, commit, path)
  local ses = GitFileDiffSession:new({
    cwd = utils.git_toplevel(cwd),
    commit = commit,
    commitpath = path,
    filetype = 'gitto_commit_diff',
    files = {},
    keymap = {
      gq = gs.key_handler('file_diff_session_close', Module.close),
    }
  })
  return gs.add(ses):run()
end

return Module
