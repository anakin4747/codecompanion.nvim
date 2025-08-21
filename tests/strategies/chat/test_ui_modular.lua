local config = require("tests.config")
local h = require("tests.helpers")

local new_set = MiniTest.new_set
local T = new_set()

local child = MiniTest.new_child_neovim()
T = new_set({
  hooks = {
    pre_case = function()
      h.child_start(child)
      child.lua([[
        h = require('tests.helpers')
        _G.chat = h.setup_chat_buffer()
      ]])
    end,
    post_case = function()
      child.lua([[
        _G.chat = nil
      ]])
    end,
    post_once = child.stop,
  },
})

T["UI Modular Architecture"] = new_set()

T["UI Modular Architecture"]["Window Management"] = new_set()

T["UI Modular Architecture"]["Window Management"]["creates window component"] = function()
  local result = child.lua([[
    local window = _G.chat.ui.window
    return {
      has_window = window ~= nil,
      has_chat_bufnr = window.chat_bufnr == _G.chat.bufnr,
      has_chat_id = window.chat_id == _G.chat.id,
      class_name = window.__class or "Window"
    }
  ]])

  MiniTest.expect.equality(result.has_window, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.has_chat_id, true)
end

T["UI Modular Architecture"]["Buffer Management"] = new_set()

T["UI Modular Architecture"]["Buffer Management"]["creates buffer component"] = function()
  local result = child.lua([[
    local buffer = _G.chat.ui.buffer
    return {
      has_buffer = buffer ~= nil,
      has_chat_bufnr = buffer.chat_bufnr == _G.chat.bufnr,
      can_lock = type(buffer.lock) == "function",
      can_unlock = type(buffer.unlock) == "function",
      can_get_last = type(buffer.last) == "function"
    }
  ]])

  MiniTest.expect.equality(result.has_buffer, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.can_lock, true)
  MiniTest.expect.equality(result.can_unlock, true)
  MiniTest.expect.equality(result.can_get_last, true)
end

T["UI Modular Architecture"]["Headers Management"] = new_set()

T["UI Modular Architecture"]["Headers Management"]["creates headers component"] = function()
  local result = child.lua([[
    local headers = _G.chat.ui.headers
    return {
      has_headers = headers ~= nil,
      has_chat_bufnr = headers.chat_bufnr == _G.chat.bufnr,
      can_format = type(headers.format_header) == "function",
      can_set = type(headers.set_header) == "function",
      can_render = type(headers.render) == "function"
    }
  ]])

  MiniTest.expect.equality(result.has_headers, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.can_format, true)
  MiniTest.expect.equality(result.can_set, true)
  MiniTest.expect.equality(result.can_render, true)
end

T["UI Modular Architecture"]["Virtual Text Management"] = new_set()

T["UI Modular Architecture"]["Virtual Text Management"]["creates virtual text component"] = function()
  local result = child.lua([[
    local virtual_text = _G.chat.ui.virtual_text
    return {
      has_virtual_text = virtual_text ~= nil,
      has_chat_bufnr = virtual_text.chat_bufnr == _G.chat.bufnr,
      can_set = type(virtual_text.set) == "function",
      can_clear = type(virtual_text.clear) == "function",
      can_set_intro = type(virtual_text.set_intro_msg) == "function"
    }
  ]])

  MiniTest.expect.equality(result.has_virtual_text, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.can_set, true)
  MiniTest.expect.equality(result.can_clear, true)
  MiniTest.expect.equality(result.can_set_intro, true)
end

T["UI Modular Architecture"]["Cursor Management"] = new_set()

T["UI Modular Architecture"]["Cursor Management"]["creates cursor component"] = function()
  local result = child.lua([[
    local cursor = _G.chat.ui.cursor
    return {
      has_cursor = cursor ~= nil,
      has_chat_bufnr = cursor.chat_bufnr == _G.chat.bufnr,
      can_follow = type(cursor.follow) == "function",
      can_update = type(cursor.update) == "function"
    }
  ]])

  MiniTest.expect.equality(result.has_cursor, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.can_follow, true)
  MiniTest.expect.equality(result.can_update, true)
end

T["UI Modular Architecture"]["Renderer Component"] = new_set()

T["UI Modular Architecture"]["Renderer Component"]["creates renderer component"] = function()
  local result = child.lua([[
    local renderer = _G.chat.ui.renderer
    return {
      has_renderer = renderer ~= nil,
      has_chat_bufnr = renderer.chat_bufnr == _G.chat.bufnr,
      can_render = type(renderer.render) == "function",
      has_buffer_ref = renderer.buffer ~= nil,
      has_headers_ref = renderer.headers ~= nil
    }
  ]])

  MiniTest.expect.equality(result.has_renderer, true)
  MiniTest.expect.equality(result.has_chat_bufnr, true)
  MiniTest.expect.equality(result.can_render, true)
  MiniTest.expect.equality(result.has_buffer_ref, true)
  MiniTest.expect.equality(result.has_headers_ref, true)
end

T["UI Modular Architecture"]["Backward Compatibility"] = new_set()

T["UI Modular Architecture"]["Backward Compatibility"]["maintains original API"] = function()
  local result = child.lua([[
    local ui = _G.chat.ui
    return {
      has_open = type(ui.open) == "function",
      has_hide = type(ui.hide) == "function",
      has_render = type(ui.render) == "function",
      has_lock_buf = type(ui.lock_buf) == "function",
      has_unlock_buf = type(ui.unlock_buf) == "function",
      has_follow = type(ui.follow) == "function",
      has_last = type(ui.last) == "function",
      has_is_visible = type(ui.is_visible) == "function",
      has_is_active = type(ui.is_active) == "function"
    }
  ]])

  MiniTest.expect.equality(result.has_open, true)
  MiniTest.expect.equality(result.has_hide, true)
  MiniTest.expect.equality(result.has_render, true)
  MiniTest.expect.equality(result.has_lock_buf, true)
  MiniTest.expect.equality(result.has_unlock_buf, true)
  MiniTest.expect.equality(result.has_follow, true)
  MiniTest.expect.equality(result.has_last, true)
  MiniTest.expect.equality(result.has_is_visible, true)
  MiniTest.expect.equality(result.has_is_active, true)
end

return T