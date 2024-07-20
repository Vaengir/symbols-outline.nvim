local so = require("symbols-outline")
local util = vim.lsp.util

local M = {}

local function get_hover_params(node, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local fn = vim.uri_from_bufnr(bufnr)

  return {
    textDocument = { uri = fn, },
    position = { line = node.line, character = node.character, },
    bufnr = bufnr,
  }
end

-- handler yoinked from the default implementation
function M.show_hover()
  local current_line = vim.api.nvim_win_get_cursor(so.view.winnr)[1]
  local node = so.state.flattened_outline_items[current_line]

  local hover_params = get_hover_params(node, so.state.code_win)

  vim.lsp.buf_request(
    hover_params.bufnr,
    "textDocument/hover",
    hover_params,
    ---@diagnostic disable-next-line: param-type-mismatch
    function(_, result, _, config)
      if not (result and result.contents) then
        -- return { 'No information available' }
        return
      end
      local markdown_lines = util.convert_input_to_markdown_lines(
        result.contents
      )
      local lines = {}
      for _, str in ipairs(markdown_lines) do
        if str ~= "" then
          lines.insert(result, str)
        end
      end
      if vim.tbl_isempty(lines) then
        -- return { "No information available", }
        return
      end
      return util.open_floating_preview(lines, "markdown", config)
    end
  )
end

return M
