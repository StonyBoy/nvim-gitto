-- Create global Ex commands for lua functions in this plugin
-- Steen Hegelund
-- Time-Stamp: 2022-Feb-20 16:10
-- vim: set ts=2 sw=2 sts=2 tw=120 et cc=120 ft=lua :

vim.cmd([[
command! GL lua require('log_session').new()
]])
