--[[
Rendering and presentation logic for the chat buffer
--]]
local config = require("codecompanion.config")
local helpers = require("codecompanion.strategies.chat.helpers")
local log = require("codecompanion.utils.log")
local yaml = require("codecompanion.utils.yaml")
local schema = require("codecompanion.schema")

---@class CodeCompanion.Chat.UI.Renderer
---@field chat_bufnr integer
---@field adapter table
---@field settings table
---@field roles table
---@field buffer CodeCompanion.Chat.UI.Buffer
---@field headers CodeCompanion.Chat.UI.Headers
---@field last_role string|nil
local Renderer = {}

---@class CodeCompanion.Chat.UI.RendererArgs
---@field chat_bufnr integer
---@field adapter table
---@field settings table
---@field roles table
---@field buffer CodeCompanion.Chat.UI.Buffer
---@field headers CodeCompanion.Chat.UI.Headers

---@param args CodeCompanion.Chat.UI.RendererArgs
function Renderer.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
    adapter = args.adapter,
    settings = args.settings,
    roles = args.roles,
    buffer = args.buffer,
    headers = args.headers,
    last_role = nil,
  }, { __index = Renderer })
end

---Render the settings and any messages in the chat buffer
---@param context table
---@param messages table
---@param opts table
---@return nil
function Renderer:render(context, messages, opts)
  local lines = {}

  local function spacer()
    table.insert(lines, "")
  end

  -- Prevent duplicate headers
  local last_set_role
  local last_role

  local function add_messages_to_buf(msgs)
    for i, msg in ipairs(msgs) do
      if (msg.role ~= config.constants.SYSTEM_ROLE) and not (msg.opts and msg.opts.visible == false) then
        -- For workflow prompts: Ensure main user role doesn't get spaced
        if i > 1 and self.last_role ~= msg.role and msg.role ~= config.constants.USER_ROLE then
          spacer()
        end

        if msg.role == config.constants.USER_ROLE and last_set_role ~= config.constants.USER_ROLE then
          if last_set_role ~= nil then
            spacer()
          end
          self.headers:set_header(lines, self.roles.user)
        end
        if msg.role == config.constants.LLM_ROLE and last_set_role ~= config.constants.LLM_ROLE then
          self.headers:set_header(lines, self.roles.llm)
        end

        if msg.opts and msg.opts.tag == "tool_output" then
          table.insert(lines, "")
        end

        local trimempty = not (msg.role == "user" and msg.content == "")
        for _, text in ipairs(vim.split(msg.content or "", "\n", { plain = true, trimempty = trimempty })) do
          table.insert(lines, text)
        end

        last_set_role = msg.role
        self.last_role = msg.role

        -- The Chat:Submit method will parse the last message and it to the messages table
        if i == #msgs then
          table.remove(msgs, i)
        end
      end
    end
  end

  if config.display.chat.show_settings then
    log:trace("Showing chat settings")
    lines = { "---" }
    local keys = schema.get_ordered_keys(self.adapter)
    for _, key in ipairs(keys) do
      local setting = self.settings[key]
      if type(setting) == "function" then
        setting = setting(self.adapter)
      end

      table.insert(lines, string.format("%s: %s", key, yaml.encode(setting)))
    end
    table.insert(lines, "---")
    spacer()
  end

  if vim.tbl_isempty(messages) or not helpers.has_user_messages(messages) then
    log:trace("Setting the header for the chat buffer")
    self.headers:set_header(lines, self.roles.user)
    spacer()
  else
    log:trace("Setting the messages in the chat buffer")
    add_messages_to_buf(messages)
  end

  -- If the user has visually selected some text, add that to the chat buffer
  if context and context.is_visual and not opts.stop_context_insertion then
    log:trace("Adding visual selection to chat buffer")
    table.insert(lines, "```" .. context.filetype)
    for _, line in ipairs(context.lines) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
  end

  self.buffer:set_lines(lines)
  self.headers:render()
end

return Renderer