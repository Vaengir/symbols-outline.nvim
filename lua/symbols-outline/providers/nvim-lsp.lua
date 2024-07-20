local config = require("symbols-outline.config")
local lsp_utils = require("symbols-outline.utils.lsp_utils")
local jsx = require("symbols-outline.utils.jsx")

local M = {}

local function getParams()
  return { textDocument = vim.lsp.util.make_text_document_params(), }
end

---@param bufnr integer
---@param params table
---@param on_info string
function M.hover_info(bufnr, params, on_info)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, })
  local used_client
  for id, client in pairs(clients) do
    if config.is_client_blacklisted(id) then
      goto continue
    else
      if client.server_capabilities.hoverProvider then
        used_client = client
        break
      end
    end
    ::continue::
  end
  if not used_client then
    on_info(nil, {
      contents = {
        kind = "markdown",
        content = { "No extra information availaible!", },
      },
    })
  end
  used_client.request("textDocument/hover", params, on_info, bufnr)
end

---@param bufnr integer
function M.should_use_provider(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, })
  local ret = false
  for id, client in pairs(clients) do
    if config.is_client_blacklisted(id) then
      goto continue
    else
      if client.server_capabilities.documentSymbolProvider then
        ret = true
        break
      end
    end
    ::continue::
  end
  return ret
end

function M.postprocess_symbols(response)
  local symbols = lsp_utils.flatten_response(response)
  local jsx_symbols = jsx.get_symbols()
  if #jsx_symbols > 0 then
    return lsp_utils.merge_symbols(symbols, jsx_symbols)
  else
    return symbols
  end
end

---@param on_symbols function
function M.request_symbols(on_symbols)
  vim.lsp.buf_request_all(
    0,
    "textDocument/documentSymbol",
    getParams(),
    function(response)
      on_symbols(M.postprocess_symbols(response))
    end
  )
end

return M
