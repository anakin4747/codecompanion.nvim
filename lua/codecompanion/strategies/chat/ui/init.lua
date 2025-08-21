--[[
Manages the UI for the chat buffer using modular components for better separation of concerns.
--]]
local config = require("codecompanion.config")

local Buffer = require("codecompanion.strategies.chat.ui.buffer")
local Cursor = require("codecompanion.strategies.chat.ui.cursor")
local Headers = require("codecompanion.strategies.chat.ui.headers")
local Renderer = require("codecompanion.strategies.chat.ui.renderer")
local VirtualText = require("codecompanion.strategies.chat.ui.virtual_text")
local Window = require("codecompanion.strategies.chat.ui.window")

local api = vim.api

local CONSTANTS = {
  NS_TOKENS = api.nvim_create_namespace("CodeCompanion-tokens"),
  AUTOCMD_GROUP = "codecompanion.chat.ui",
}

---@class CodeCompanion.Chat.UI
---@field adapter table
---@field chat_bufnr integer
---@field chat_id integer
---@field roles table
---@field settings table
---@field tokens table
---@field winnr integer|nil
---@field window CodeCompanion.Chat.UI.Window
---@field buffer CodeCompanion.Chat.UI.Buffer
---@field cursor CodeCompanion.Chat.UI.Cursor
---@field headers CodeCompanion.Chat.UI.Headers
---@field renderer CodeCompanion.Chat.UI.Renderer
---@field virtual_text CodeCompanion.Chat.UI.VirtualText
---@field folds table
local UI = {}

---@param args CodeCompanion.Chat.UIArgs
function UI.new(args)
  local self = setmetatable({
    adapter = args.adapter,
    chat_bufnr = args.chat_bufnr,
    chat_id = args.chat_id,
    roles = args.roles,
    settings = args.settings,
    tokens = args.tokens,
    winnr = args.winnr,
  }, { __index = UI })

  -- Create modular components
  self.window = Window.new({
    chat_bufnr = self.chat_bufnr,
    chat_id = self.chat_id,
    winnr = self.winnr,
  })

  self.buffer = Buffer.new({
    chat_bufnr = self.chat_bufnr,
  })

  self.cursor = Cursor.new({
    chat_bufnr = self.chat_bufnr,
    winnr = self.winnr,
  })

  self.headers = Headers.new({
    chat_bufnr = self.chat_bufnr,
    adapter = self.adapter,
    roles = self.roles,
  })

  self.renderer = Renderer.new({
    chat_bufnr = self.chat_bufnr,
    adapter = self.adapter,
    settings = self.settings,
    roles = self.roles,
    buffer = self.buffer,
    headers = self.headers,
  })

  self.virtual_text = VirtualText.new({
    chat_bufnr = self.chat_bufnr,
  })

  self.aug = api.nvim_create_augroup(CONSTANTS.AUTOCMD_GROUP .. ":" .. self.chat_bufnr, {
    clear = false,
  })
  self.folds = require("codecompanion.strategies.chat.ui.folds")

  -- Maintain backward compatibility
  self.last_role = nil

  api.nvim_create_autocmd("InsertEnter", {
    group = self.aug,
    buffer = self.chat_bufnr,
    once = true,
    desc = "Clear the virtual text in the CodeCompanion chat buffer",
    callback = function()
      self.virtual_text:clear_all()
    end,
  })

  return self
end

---Open/create the chat window
---@param opts? table
---@return CodeCompanion.Chat.UI|nil
function UI:open(opts)
  opts = opts or {}
  
  local result = self.window:open(opts)
  if result then
    self.winnr = self.window.winnr
    self.cursor:set_window(self.winnr)
    
    if not opts.toggled then
      self:follow()
    end

    self.folds:setup(self.winnr)
  end
  
  return result and self or nil
end

---Hide the chat buffer from view
---@return nil
function UI:hide()
  self.window:hide()
end

---Follow the cursor in the chat buffer
---@return nil
function UI:follow()
  self.cursor:follow()
end

---Determine if the current chat buffer is active
---@return boolean
function UI:is_active()
  return self.window:is_active()
end

---Determine if the chat buffer is visible
---@return boolean
function UI:is_visible()
  return self.window:is_visible()
end

---Chat buffer is visible but not in the current tab
---@return boolean
function UI:is_visible_non_curtab()
  return self.window:is_visible_non_curtab()
end

---Get the formatted header for the chat buffer
---@param role string The role of the user
---@return string
function UI:format_header(role)
  return self.headers:format_header(role)
end

---Format the header in the chat buffer
---@param tbl table containing the buffer contents
---@param role string The role of the user to display in the header
---@return nil
function UI:set_header(tbl, role)
  self.headers:set_header(tbl, role)
end

---Render the settings and any messages in the chat buffer
---@param context table
---@param messages table
---@param opts table
---@return self
function UI:render(context, messages, opts)
  self.renderer:render(context, messages, opts)
  -- Sync the last_role for backward compatibility
  self.last_role = self.renderer.last_role
  self:follow()
  return self
end

---Render the headers in the chat buffer and apply extmarks
---@return nil
function UI:render_headers()
  self.headers:render()
end

---Set the welcome message in the chat buffer
---@param message string The intro message to display
---@return CodeCompanion.Chat.UI|nil
function UI:set_intro_msg(message)
  return self.virtual_text:set_intro_msg(message)
end

---Set virtual text in the chat buffer
---@param message string
---@param method? string "eol", "inline" etc
---@param range? table<number, number>
---@return number The id of the extmark
function UI:set_virtual_text(message, method, range)
  return self.virtual_text:set(message, method, range)
end

---Clear virtual text in the chat buffer
---@param extmark_id number The id of the extmark to delete
---@return nil
function UI:clear_virtual_text(extmark_id)
  self.virtual_text:clear(extmark_id)
end

---Get the last line, column and line count in the chat buffer
---@return integer, integer, integer
function UI:last()
  return self.buffer:last()
end

---Display the tokens in the chat buffer
---@param parser table
---@param start_row integer
---@return nil
function UI:display_tokens(parser, start_row)
  if config.display.chat.show_token_count and self.tokens then
    local to_display = config.display.chat.token_count
    if type(to_display) == "function" then
      to_display = to_display(self.tokens, self.adapter)
      require("codecompanion.utils.tokens").display(to_display, CONSTANTS.NS_TOKENS, parser, start_row, self.chat_bufnr)
    end
  end
end

---Fold code under the user's heading in the chat buffer
---@return self
function UI:fold_code()
  local query = vim.treesitter.query.parse(
    "markdown",
    [[
(section
(
 (atx_heading
  (atx_h2_marker)
  heading_content: (_) @role
)
([
  (fenced_code_block)
  (indented_code_block)
] @code (#trim! @code))
))
]]
  )

  local parser = vim.treesitter.get_parser(self.chat_bufnr, "markdown")
  local tree = parser:parse()[1]
  vim.o.foldmethod = "manual"

  local role
  for _, matches in query:iter_matches(tree:root(), self.chat_bufnr) do
    local match = {}
    for id, nodes in pairs(matches) do
      local node = type(nodes) == "table" and nodes[1] or nodes
      match = vim.tbl_extend("keep", match, {
        [query.captures[id]] = {
          node = node,
        },
      })
    end

    if match.role then
      role = vim.trim(vim.treesitter.get_node_text(match.role.node, self.chat_bufnr))
      if role:match(self.roles.user) and match.code then
        local start_row, _, end_row, _ = match.code.node:range()
        if start_row < end_row then
          api.nvim_buf_call(self.chat_bufnr, function()
            vim.cmd(string.format("%d,%dfold", start_row, end_row))
          end)
        end
      end
    end
  end

  return self
end

---Add a line break to the chat buffer
---@return nil
function UI:add_line_break()
  self.buffer:add_line_break()
  self:move_cursor(true)
end

---Update the cursor position in the chat buffer
---@param cursor_has_moved boolean
---@return nil
function UI:move_cursor(cursor_has_moved)
  self.cursor:update(cursor_has_moved)
end

---Get the last role for state tracking
---@return string|nil
function UI:get_last_role()
  return self.renderer.last_role
end

---Set the last role for state tracking  
---@param role string
function UI:set_last_role(role)
  self.renderer.last_role = role
end

---Lock the chat buffer from editing
function UI:lock_buf()
  self.buffer:lock()
end

---Unlock the chat buffer for editing
function UI:unlock_buf()
  self.buffer:unlock()
end

return UI
