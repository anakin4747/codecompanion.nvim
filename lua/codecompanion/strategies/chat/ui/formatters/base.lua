---@class CodeCompanion.Chat.UI.Formatters.Base
---@field chat CodeCompanion.Chat
---@field __class string
local BaseFormatter = {}
BaseFormatter.__class = "BaseFormatter"

---@class CodeCompanion.Chat.UI.Formatters.BaseArgs
---@field chat CodeCompanion.Chat

---@param chat CodeCompanion.Chat
function BaseFormatter:new(chat)
  if not chat then
    error("BaseFormatter:new() called with nil chat")
  end

  return setmetatable({
    chat = chat,
  }, { __index = self })
end

---Check if this formatter can handle the given data/opts
---@param message table
---@param opts table
---@param tags table
---@return boolean
function BaseFormatter:can_handle(message, opts, tags)
  error("Must implement can_handle method")
end

---Get the message type for this formatter
---@return string
function BaseFormatter:get_type()
  error("Must implement get_type method")
end

---Format the content into lines
---@param message table
---@param opts table
---@param state table
---@return table lines, table? fold_info
function BaseFormatter:format(message, opts, state)
  error("Must implement format method")
end

---Helper method to split content into lines
---@param content string
---@param trim_empty? boolean
---@return table
function BaseFormatter:split_content(content, trim_empty)
  if trim_empty == nil then
    trim_empty = false
  end
  return vim.split(content or "", "\n", { plain = true, trimempty = trim_empty })
end

---Helper method to add spacing
---@param lines table
---@param count? integer
function BaseFormatter:add_spacing(lines, count)
  count = count or 1
  for _ = 1, count do
    table.insert(lines, "")
  end
end

return BaseFormatter
