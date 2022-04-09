-- Steen Hegelund
-- Time-Stamp: 2022-Apr-09 17:26
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
  self.key_default = {
    ['<F1>'] = Module.key_handler('git_session_show_help', Module.show_help),
  }
  self.buffer_filter = Module.remove_empty_trailing
  return opts
end

Module.set_buf_keymaps = function(buf, keymap, default)
  for k,v in pairs(keymap) do
    vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua '..v..'<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end
  if default then
    for k,v in pairs(default) do
      vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua '..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
    end
  end
end

Module.remove_empty_trailing = function(lines)
  for idx = #lines,1,-1 do
    if #lines[idx] == 0 then
      -- remove line
      table.remove(lines, idx)
    else
      break
    end
  end
  return lines
end

Module.config_bufwin = function(obj)
  -- save parent window
  obj.start_win = vim.api.nvim_get_current_win()
  obj.win = vim.api.nvim_get_current_win()
  obj.buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(obj.buf, obj:get_bufname())
  vim.api.nvim_buf_set_option(obj.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(obj.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(obj.buf, 'filetype', obj.filetype)
  vim.api.nvim_win_set_option(obj.win, 'wrap', false)
  vim.api.nvim_win_set_option(obj.win, 'cursorline', true)
end

Module.append_buffer = function(buf, lines, filter)
  if filter then
    lines = filter(lines)
  end
  print('append_buffer', os.date('@%M:%S'), vim.inspect(lines))
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
  vim.api.nvim_command('botright vnew') -- new empty vertical window at the far right
  Module.config_bufwin(self)
  Module.set_buf_keymaps(self.buf, self.keymap, self.key_default)
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
    if (session == self) then
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

function GitSession:has_buffer(buf)
  return buf == self.buf
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
    if session:has_buffer(buf) then
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
