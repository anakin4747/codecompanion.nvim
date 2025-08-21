--[[
Window management for the chat buffer - handles opening, closing, and positioning windows
--]]
local config = require("codecompanion.config")
local ui = require("codecompanion.utils.ui")
local log = require("codecompanion.utils.log")
local util = require("codecompanion.utils")

local api = vim.api

---@class CodeCompanion.Chat.UI.Window
---@field chat_bufnr integer
---@field chat_id integer
---@field winnr integer|nil
local Window = {}

---@class CodeCompanion.Chat.UI.WindowArgs
---@field chat_bufnr integer
---@field chat_id integer
---@field winnr integer|nil

---@param args CodeCompanion.Chat.UI.WindowArgs
function Window.new(args)
  return setmetatable({
    chat_bufnr = args.chat_bufnr,
    chat_id = args.chat_id,
    winnr = args.winnr,
  }, { __index = Window })
end

---Open/create the chat window
---@param opts? table
---@return CodeCompanion.Chat.UI.Window|nil
function Window:open(opts)
  opts = opts or {}

  if self:is_visible() then
    return
  end
  
  if config.display.chat.start_in_insert_mode then
    -- Delay entering insert mode until after Telescope picker fully closes,
    -- since Telescope resets to normal mode on close.
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  end

  local window = config.display.chat.window
  local width = math.floor(vim.o.columns * 0.45)
  if window.width ~= "auto" then
    width = window.width > 1 and window.width or math.floor(vim.o.columns * window.width)
  end
  local height = window.height > 1 and window.height or math.floor(vim.o.lines * window.height)

  if window.layout == "float" then
    self:_open_float(window, width, height)
  elseif window.layout == "vertical" then
    self:_open_vertical(window, width)
  elseif window.layout == "horizontal" then
    self:_open_horizontal(window, height)
  else
    self:_open_current()
  end

  ui.set_win_options(self.winnr, window.opts)
  vim.bo[self.chat_bufnr].textwidth = 0

  log:trace("Chat opened with ID %d", self.chat_id)
  util.fire("ChatOpened", { bufnr = self.chat_bufnr, id = self.chat_id })

  return self
end

---Open a floating window
---@param window table
---@param width integer
---@param height integer
function Window:_open_float(window, width, height)
  local win_opts = {
    relative = window.relative,
    width = width,
    height = height,
    row = window.row or math.floor((vim.o.lines - height) / 2),
    col = window.col or math.floor((vim.o.columns - width) / 2),
    border = window.border,
    title = window.title or "CodeCompanion",
    title_pos = "center",
    zindex = 45,
  }
  self.winnr = api.nvim_open_win(self.chat_bufnr, true, win_opts)
end

---Open a vertical split window
---@param window table
---@param width integer
function Window:_open_vertical(window, width)
  local position = window.position
  local full_height = window.full_height
  
  if position == nil or (position ~= "left" and position ~= "right") then
    position = vim.opt.splitright:get() and "right" or "left"
  end
  
  if full_height then
    if position == "left" then
      vim.cmd("topleft vsplit")
    else
      vim.cmd("botright vsplit")
    end
  else
    vim.cmd("vsplit")
  end
  
  if position == "left" and vim.opt.splitright:get() then
    vim.cmd("wincmd h")
  end
  if position == "right" and not vim.opt.splitright:get() then
    vim.cmd("wincmd l")
  end
  
  if window.width ~= "auto" then
    vim.cmd("vertical resize " .. width)
  end
  
  self.winnr = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.winnr, self.chat_bufnr)
end

---Open a horizontal split window
---@param window table
---@param height integer
function Window:_open_horizontal(window, height)
  local position = window.position
  
  if position == nil or (position ~= "top" and position ~= "bottom") then
    position = vim.opt.splitbelow:get() and "bottom" or "top"
  end
  
  vim.cmd("split")
  
  if position == "top" and vim.opt.splitbelow:get() then
    vim.cmd("wincmd k")
  end
  if position == "bottom" and not vim.opt.splitbelow:get() then
    vim.cmd("wincmd j")
  end
  
  vim.cmd("resize " .. height)
  self.winnr = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.winnr, self.chat_bufnr)
end

---Open in current window
function Window:_open_current()
  self.winnr = api.nvim_get_current_win()
  api.nvim_set_current_buf(self.chat_bufnr)
end

---Hide the chat buffer from view
---@return nil
function Window:hide()
  local layout = config.display.chat.window.layout

  if layout == "float" or layout == "vertical" or layout == "horizontal" then
    if self:is_active() then
      vim.cmd("hide")
    else
      if not self.winnr then
        self.winnr = ui.buf_get_win(self.chat_bufnr)
      end
      api.nvim_win_hide(self.winnr)
    end
  else
    vim.cmd("buffer " .. vim.fn.bufnr("#"))
  end

  util.fire("ChatHidden", { bufnr = self.chat_bufnr, id = self.chat_id })
end

---Determine if the current chat buffer is active
---@return boolean
function Window:is_active()
  return api.nvim_get_current_buf() == self.chat_bufnr
end

---Determine if the chat buffer is visible
---@return boolean
function Window:is_visible()
  return self.winnr and api.nvim_win_is_valid(self.winnr) and api.nvim_win_get_buf(self.winnr) == self.chat_bufnr
end

---Chat buffer is visible but not in the current tab
---@return boolean
function Window:is_visible_non_curtab()
  return self:is_visible() and api.nvim_get_current_tabpage() ~= api.nvim_win_get_tabpage(self.winnr)
end

return Window