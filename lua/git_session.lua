-- Steen Hegelund
-- Time-Stamp: 2022-Apr-08 23:28
-- Provide Session Base Class
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :

local Module = {_sessions = {}}

local GitSession = {}

-- Options for new()
-- cwd: current working directory
-- filetype: filetype for buffer (syntax file linked)
-- cmd(): command to run: function returning a table
-- keymap: keymap for buffer
-- get_bufname(buf): function returning a string
function GitSession:new(opts)
  opts = opts or {}
  setmetatable(opts, self)
  self.__index = self
  self.marker = string.rep('==', 30)
  return opts
end

function GitSession:set_buf_keymaps()
  for k,v in pairs(self.keymap) do
    vim.api.nvim_buf_set_keymap(self.buf, 'n', k, ':lua '..v..'<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end
  local default = {
    ['<F1>'] = Module.key_handler('git_session_show_help', Module.show_help),
  }
  for k,v in pairs(default) do
    vim.api.nvim_buf_set_keymap(self.buf, 'n', k, ':lua '..v..'<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end
end

Module.create_bufwin = function(obj)
  -- save parent window
  obj.start_win = vim.api.nvim_get_current_win()
  vim.api.nvim_command('botright vnew') -- new vertical window at the far right
  obj.win = vim.api.nvim_get_current_win()
  obj.buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(obj.buf, obj:get_bufname())
  -- nofile prevents warnings about unsaved changes
  vim.api.nvim_buf_set_option(obj.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(obj.buf, 'swapfile', false)
  -- buffer will be destroyed when hidden
  vim.api.nvim_buf_set_option(obj.buf, 'bufhidden', 'wipe')
  -- set custom filetype to allow users to create autocommands or colorschemes based on filetype.
  vim.api.nvim_buf_set_option(obj.buf, 'filetype', obj.filetype)

  -- For better UX we will turn off line wrap and turn on current line highlight.
  vim.api.nvim_win_set_option(obj.win, 'wrap', false)
  vim.api.nvim_win_set_option(obj.win, 'cursorline', true)
end

Module.append_buffer = function(buf, lines, filter)
  if filter then
    lines = vim.tbl_filter(filter, lines)
  end
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  if vim.api.nvim_buf_line_count(buf) == 0 then
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, -2, -2, false, lines)
  end
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

Module.cmd_append_buffer = function(cmd, cwd, buf, filter, pos)
  vim.fn.jobstart(cmd, {
    cwd = cwd,
    on_stdout = function(_, lines, _)
      Module.append_buffer(buf, lines, filter)
      if pos then
        vim.fn.winrestview(pos)
      else
        vim.fn.setpos('.', {buf, 1, 1, 0})
      end
    end,
  })
end

function GitSession:run()
  Module.create_bufwin(self)
  self:set_buf_keymaps()
  Module.cmd_append_buffer(self:cmd(), self.cwd, self.buf, self.buffer_filter)
  return self
end

function GitSession:rerun()
  local pos = vim.fn.winsaveview()
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
  Module.cmd_append_buffer(self:cmd(), self.cwd, self.buf, self.buffer_filter, pos)
  return self
end

function GitSession:continue()
  local pos = vim.fn.winsaveview()
  Module.cmd_append_buffer(self:cmd(), self.cwd, self.buf, self.buffer_filter, pos)
  return self
end

function GitSession:show_help()
  print('no help for this session')
end

function GitSession:show_help_text(helptext)
  local lines = vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', true)
  if lines[1] == self.marker then
    vim.api.nvim_buf_set_lines(self.buf, 0, #helptext + 2, false, {})
  else
    table.insert(helptext, 1, self.marker)
    table.insert(helptext, self.marker)
    vim.api.nvim_buf_set_lines(self.buf, 0, 0, false, helptext)
  end
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', false)
end

function GitSession:close()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

function GitSession:quit()
  for idx, session in ipairs(Module._sessions) do
    if (session.buf == self.buf) then
      session:close()
      table.remove(Module._sessions, idx)
      return self
    end
  end
end

function GitSession:event(evt)
  for _,session in ipairs(Module._sessions) do
    if (session ~= self) then
      session:on_event(evt)
    end
  end
end

function GitSession:on_event(evt)
  print('on_event', vim.inspect(evt))
end

Module.GitSession = GitSession

Module.show_help = function()
  Module.find(vim.api.nvim_get_current_buf()):show_help()
end

Module.add = function(session)
  table.insert(Module._sessions, session)
  return session
end

Module.find = function(buf)
  for _,session in ipairs(Module._sessions) do
    if (session.buf == buf) then
      return session
    end
  end
  return nil
end

Module.on_key_event = function(evt_name)
  if Module.key_event_table[evt_name] then
    Module.key_event_table[evt_name]()
  end
end

Module.key_event_table = {}

function Module.key_handler(evt_name, func)
  Module.key_event_table[evt_name] = func
  return string.format("require('git_session').on_key_event('%s')<CR>", evt_name)
end

Module.shutdown = function()
  local count = 10
  while #Module._sessions > 0 and count > 0 do
    for idx, session in ipairs(Module._sessions) do
      session:close()
      table.remove(Module._sessions, idx)
    end
    count = count - 1
  end
end

-- Shutdown handling via NVIM events
vim.cmd [[
augroup neovim_shutdown
    autocmd!
    autocmd QuitPre * :lua require("git_session").shutdown()
augroup END
]]

return Module
