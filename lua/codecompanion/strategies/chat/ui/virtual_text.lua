--[[
Virtual text management for the chat buffer - handles intro messages and other virtual text
--]]
local api = vim.api

local CONSTANTS = {
  NS_VIRTUAL_TEXT = api.nvim_create_namespace("CodeCompanion-virtual_text"),
}

---@class CodeCompanion.Chat.UI.VirtualText
---@field chat_bufnr integer
---@field intro_message boolean|nil
local VirtualText = {}

---@class CodeCompanion.Chat.UI.VirtualTextArgs
---@field chat_bufnr integer

---@param args CodeCompanion.Chat.UI.VirtualTextArgs
function VirtualText.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
    intro_message = nil,
  }, { __index = VirtualText })
end

---Set the welcome message in the chat buffer
---@param message string The intro message to display
---@return CodeCompanion.Chat.UI.VirtualText|nil
function VirtualText:set_intro_msg(message)
  if self.intro_message then
    return self
  end

  local config = require("codecompanion.config")
  if not config.display.chat.start_in_insert_mode then
    local extmark_id = self:set(message, "eol")
    api.nvim_create_autocmd("InsertEnter", {
      buffer = self.chat_bufnr,
      callback = function()
        self:clear(extmark_id)
      end,
    })
    self.intro_message = true
  end

  return self
end

---Set virtual text in the chat buffer
---@param message string
---@param method? string "eol", "inline" etc
---@param range? table<number, number>
---@return number The id of the extmark
function VirtualText:set(message, method, range)
  range = range or { api.nvim_buf_line_count(self.chat_bufnr) - 1, 0 }

  return api.nvim_buf_set_extmark(self.chat_bufnr, CONSTANTS.NS_VIRTUAL_TEXT, range[1], range[2], {
    virt_text = { { message, "CodeCompanionVirtualText" } },
    virt_text_pos = method or "eol",
  })
end

---Clear virtual text in the chat buffer
---@param extmark_id number The id of the extmark to delete
---@return nil
function VirtualText:clear(extmark_id)
  api.nvim_buf_del_extmark(self.chat_bufnr, CONSTANTS.NS_VIRTUAL_TEXT, extmark_id)
end

---Clear all virtual text in the chat buffer
---@return nil
function VirtualText:clear_all()
  api.nvim_buf_clear_namespace(self.chat_bufnr, CONSTANTS.NS_VIRTUAL_TEXT, 0, -1)
end

return VirtualText