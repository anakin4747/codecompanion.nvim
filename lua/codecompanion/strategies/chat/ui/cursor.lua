--[[
Cursor and scrolling management for the chat buffer
--]]
local config = require("codecompanion.config")

local api = vim.api

---@class CodeCompanion.Chat.UI.Cursor
---@field chat_bufnr integer
---@field winnr integer|nil
local Cursor = {}

---@class CodeCompanion.Chat.UI.CursorArgs
---@field chat_bufnr integer
---@field winnr integer|nil

---@param args CodeCompanion.Chat.UI.CursorArgs
function Cursor.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
    winnr = args.winnr,
  }, { __index = Cursor })
end

---Update the window reference
---@param winnr integer
function Cursor:set_window(winnr)
  self.winnr = winnr
end

---Follow the cursor in the chat buffer
---@return nil
function Cursor:follow()
  if not self:_is_window_visible() then
    return
  end

  local last_line, last_column = self:_get_last_position()
  if last_line == 0 then
    return
  end

  api.nvim_win_set_cursor(self.winnr, { last_line + 1, last_column })
end

---Update the cursor position in the chat buffer
---@param cursor_has_moved boolean
---@return nil
function Cursor:update(cursor_has_moved)
  if config.display.chat.auto_scroll then
    if cursor_has_moved and self:_is_current_window() then
      self:follow()
    elseif not self:_is_current_window() then
      self:follow()
    end
  end
end

---Check if the window is visible
---@return boolean
function Cursor:_is_window_visible()
  return self.winnr and api.nvim_win_is_valid(self.winnr) and api.nvim_win_get_buf(self.winnr) == self.chat_bufnr
end

---Check if this is the current window
---@return boolean
function Cursor:_is_current_window()
  return api.nvim_get_current_buf() == self.chat_bufnr
end

---Get the last line and column position
---@return integer, integer
function Cursor:_get_last_position()
  local line_count = api.nvim_buf_line_count(self.chat_bufnr)

  local last_line = line_count - 1
  if last_line < 0 then
    return 0, 0
  end

  local last_line_content = api.nvim_buf_get_lines(self.chat_bufnr, -2, -1, false)
  if not last_line_content or #last_line_content == 0 then
    return last_line, 0
  end

  local last_column = #last_line_content[1]

  return last_line, last_column
end

return Cursor