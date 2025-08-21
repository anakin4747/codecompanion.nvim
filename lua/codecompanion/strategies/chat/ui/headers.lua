--[[
Header management for the chat buffer - handles role headers and separators
--]]
local config = require("codecompanion.config")
local log = require("codecompanion.utils.log")

local api = vim.api

local CONSTANTS = {
  NS_HEADER = api.nvim_create_namespace("CodeCompanion-headers"),
}

---Set the LLM role based on the adapter
---@param role string|function
---@param adapter table
---@return string
local function set_llm_role(role, adapter)
  if type(role) == "function" then
    return role(adapter)
  end
  return role
end

---@class CodeCompanion.Chat.UI.Headers
---@field chat_bufnr integer
---@field adapter table
---@field roles table
local Headers = {}

---@class CodeCompanion.Chat.UI.HeadersArgs
---@field chat_bufnr integer
---@field adapter table
---@field roles table

---@param args CodeCompanion.Chat.UI.HeadersArgs
function Headers.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
    adapter = args.adapter,
    roles = args.roles,
  }, { __index = Headers })
end

---Get the formatted header for the chat buffer
---@param role string The role of the user
---@return string
function Headers:format_header(role)
  local header = "## " .. role
  if config.display.chat.show_header_separator then
    header = string.format("%s %s", header, config.display.chat.separator)
  end

  return header
end

---Format the header in the chat buffer
---@param tbl table containing the buffer contents
---@param role string The role of the user to display in the header
---@return nil
function Headers:set_header(tbl, role)
  -- If the role is the LLM then we need to swap this out for a user func
  if type(role) == "function" then
    role = set_llm_role(role, self.adapter)
  end

  table.insert(tbl, self:format_header(role))
  table.insert(tbl, "")
end

---Render the headers in the chat buffer and apply extmarks
---@return nil
function Headers:render()
  if not config.display.chat.show_header_separator then
    return
  end

  local separator = config.display.chat.separator
  local lines = api.nvim_buf_get_lines(self.chat_bufnr, 0, -1, false)
  local llm_role = set_llm_role(self.roles.llm, self.adapter)

  for line, content in ipairs(lines) do
    if content:match("^## " .. vim.pesc(self.roles.user)) or content:match("^## " .. vim.pesc(llm_role)) then
      local col = vim.fn.strwidth(content) - vim.fn.strwidth(separator)

      api.nvim_buf_set_extmark(self.chat_bufnr, CONSTANTS.NS_HEADER, line - 1, col, {
        virt_text_win_col = col,
        virt_text = { { string.rep(separator, vim.go.columns), "CodeCompanionChatSeparator" } },
        priority = 100,
      })

      -- Set the highlight group for the header
      api.nvim_buf_set_extmark(self.chat_bufnr, CONSTANTS.NS_HEADER, line - 1, 0, {
        end_col = col + 1,
        hl_group = "CodeCompanionChatHeader",
      })
    end
  end
  log:trace("Rendering headers in the chat buffer")
end

---Clear all header extmarks
---@return nil
function Headers:clear()
  api.nvim_buf_clear_namespace(self.chat_bufnr, CONSTANTS.NS_HEADER, 0, -1)
end

return Headers