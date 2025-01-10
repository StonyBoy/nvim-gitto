-- Steen Hegelund
-- Time-Stamp: 2025-Jan-10 15:06
-- Provide a Git commit difference session
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :
local Module = {}

local utils = require('utils')
local gs = require('git_session')
local GitFileDiffSession = gs.GitSession:new()

Module.set_win_diffoptions = function(win)
  vim.api.nvim_win_set_option(win, 'diff', true)
  vim.api.nvim_win_set_option(win, 'scrollbind', true)
  vim.api.nvim_win_set_option(win, 'cursorbind', true)
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

Module.config_commitbufwin = function(item, keymap)
  item.win = vim.api.nvim_get_current_win()
  item.buf = vim.api.nvim_get_current_buf()
  local fpath = 'git://' .. item.commit .. '/' .. item.path
  vim.api.nvim_buf_set_name(item.buf, fpath)
  local cmd = {'git', '-C', item.cwd, 'show', item.commit .. ':' .. item.path }
  gs.cmd_append_buffer(cmd, item.cwd, item.buf, gs.remove_empty_trailing)
  vim.api.nvim_buf_set_option(item.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(item.buf, 'swapfile', false)
  vim.api.nvim_win_set_option(item.win, 'wrap', false)
  vim.api.nvim_win_set_option(item.win, 'cursorline', true)
  Module.set_win_diffoptions(item.win)
  gs.set_buf_keymaps(item.buf, keymap)
  vim.cmd('filetype detect')
end

Module.config_filebufwin = function(item, keymap)
  item.win = vim.api.nvim_get_current_win()
  item.path = vim.fs.joinpath(item.cwd, item.path)
  local buf = Module.is_file_loaded(item.path)
  if buf then
    item.keep = true
    vim.api.nvim_set_current_buf(buf)
  else
    item.keep = false
    vim.cmd('edit ' .. item.path)
  end
  item.buf = vim.api.nvim_get_current_buf()
  Module.set_win_diffoptions(item.win)
  gs.set_buf_keymaps(item.buf, keymap)
end

Module.close = function()
  gs.find(vim.api.nvim_get_current_buf()):quit()
end

function GitFileDiffSession:close()
  vim.api.nvim_buf_delete(self.items[1].buf, {force = true})
  if not self.items[2].keep then
    vim.api.nvim_buf_delete(self.items[2].buf, {force = true})
  else
    vim.cmd('tabclose')
  end
end

function GitFileDiffSession:run()
  vim.cmd('tabnew') -- new tab window without a buffer
  Module.config_commitbufwin(self.items[1], self.keymap)
  vim.api.nvim_command('botright vnew') -- new empty vertical window at the far right
  if self.ancestor then
    Module.config_commitbufwin(self.items[2], self.keymap)
  else
    Module.config_filebufwin(self.items[2], self.keymap)
  end
end

function GitFileDiffSession:cmd()
  return {'git', 'diff', '--stat', self.commit}
end

function GitFileDiffSession:get_bufname()
  return  'GitFileDiff' .. ' #' .. self.commit
end

function GitFileDiffSession:has_buffer(buf)
  return self.items[1].buf == buf or self.items[2].buf == buf
end

Module.new = function(cwd, commit, path, ancestor)
  cwd = utils.git_toplevel(cwd)
  local ses = GitFileDiffSession:new({
    name = vim.fs.basename(path),
    items = {
      { commit = ancestor or commit, cwd = cwd, path = path, },
      { commit = commit, cwd = cwd, path = path}
    },
    ancestor = ancestor,
    filetype = 'gitto_commit_diff',
    keymap = {
      gq = gs.key_handler('file_diff_session_close', Module.close),
    }
  })
  return gs.add(ses):run()
end

return Module
