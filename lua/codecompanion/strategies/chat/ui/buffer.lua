--[[
Buffer management for the chat buffer - handles buffer state, locking, and cursor management
--]]
local config = require("codecompanion.config")

local api = vim.api

---@class CodeCompanion.Chat.UI.Buffer
---@field chat_bufnr integer
local Buffer = {}

---@class CodeCompanion.Chat.UI.BufferArgs
---@field chat_bufnr integer

---@param args CodeCompanion.Chat.UI.BufferArgs
function Buffer.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
  }, { __index = Buffer })
end

---Lock the chat buffer from editing
function Buffer:lock()
  vim.bo[self.chat_bufnr].modified = false
  vim.bo[self.chat_bufnr].modifiable = false
end

---Unlock the chat buffer for editing
function Buffer:unlock()
  vim.bo[self.chat_bufnr].modified = false
  vim.bo[self.chat_bufnr].modifiable = true
end

---Get the last line, column and line count in the chat buffer
---@return integer, integer, integer
function Buffer:last()
  local line_count = api.nvim_buf_line_count(self.chat_bufnr)

  local last_line = line_count - 1
  if last_line < 0 then
    return 0, 0, line_count
  end

  local last_line_content = api.nvim_buf_get_lines(self.chat_bufnr, -2, -1, false)
  if not last_line_content or #last_line_content == 0 then
    return last_line, 0, line_count
  end

  local last_column = #last_line_content[1]

  return last_line, last_column, line_count
end

---Add a line break to the chat buffer
---@return nil
function Buffer:add_line_break()
  local _, _, line_count = self:last()

  self:unlock()
  api.nvim_buf_set_lines(self.chat_bufnr, line_count, line_count, false, { "" })
  self:lock()
end

---Write lines to the buffer
---@param lines table
---@param opts? table
---@return nil
function Buffer:write_lines(lines, opts)
  opts = opts or {}
  
  self:unlock()
  local last_line, last_column, line_count = self:last()

  if opts.insert_at then
    last_line = opts.insert_at
    last_column = 0
  end

  api.nvim_buf_set_text(self.chat_bufnr, last_line, last_column, last_line, last_column, lines)
end

---Set lines in the buffer
---@param lines table
---@param start_line? integer
---@param end_line? integer
---@return nil
function Buffer:set_lines(lines, start_line, end_line)
  start_line = start_line or 0
  end_line = end_line or -1
  
  self:unlock()
  api.nvim_buf_set_lines(self.chat_bufnr, start_line, end_line, false, lines)
end

return Buffer