-- Assemble a root blueprint book from book.json and the blueprint JSON files uploaded into
-- storage.mcp_asm by factorio.ps1 (key '__manifest' = book.json text, other keys = file contents).
-- Leaves the book in storage.mcp_inv[3], writes its import string to script-output/mcp/book.txt
-- and prints a one-line summary.
local asm = storage.mcp_asm or {}
local manifest = helpers.json_to_table(asm['__manifest'] or '')
if not manifest then rcon.print('ERROR: manifest is not valid JSON') return end

local v = {}
for part in string.gmatch(script.active_mods.base, '%d+') do v[#v+1] = tonumber(part) end
local VERSION = v[1] * 2^48 + v[2] * 2^32 + (v[3] or 0) * 2^16

local problems, n_books, n_blueprints = {}, 0, 0

local function build(node, path)
  if node.file then
    local raw = asm[node.file]
    local t = raw and helpers.json_to_table(raw)
    if not t then problems[#problems+1] = 'cannot read ' .. node.file return nil end
    local key = t.blueprint and 'blueprint' or (t.blueprint_book and 'blueprint_book') or next(t)
    local inner = t[key]
    if node.label then inner.label = node.label end
    if node.description then inner.description = node.description end
    if not inner.label or inner.label == '' then problems[#problems+1] = 'no label: ' .. node.file end
    if not inner.description or inner.description == '' then problems[#problems+1] = 'no description: ' .. node.file end
    if inner.description and #inner.description > 500 then problems[#problems+1] = 'description over 500 bytes: ' .. node.file end
    n_blueprints = n_blueprints + 1
    return {[key] = inner}
  end
  local here = path .. '/' .. tostring(node.label)
  if not node.label or node.label == '' then problems[#problems+1] = 'book without label under ' .. path end
  if not node.description or node.description == '' then problems[#problems+1] = 'book without description: ' .. here end
  if node.description and #node.description > 500 then problems[#problems+1] = 'description over 500 bytes: ' .. here end
  local items = {}
  for _, child in ipairs(node.children or {}) do
    local built = build(child, here)
    if built then
      built.index = #items
      items[#items+1] = built
    end
  end
  n_books = n_books + 1
  local book = {item = 'blueprint-book', label = node.label, description = node.description, active_index = 0, version = VERSION}
  if #items > 0 then book.blueprints = items end
  return {blueprint_book = book}
end

local root = build(manifest, '')
local str = '0' .. helpers.encode_string(helpers.table_to_json(root))

-- The game itself is the judge of whether the string is a valid book.
storage.mcp_inv = storage.mcp_inv or game.create_inventory(10)
local st = storage.mcp_inv[3]
st.clear()
local rc = st.import_stack(str)
local ok = rc <= 0 and st.valid_for_read and st.is_blueprint_book and #problems == 0
if ok then helpers.write_file('mcp/book.txt', str, false) end
storage.mcp_asm = nil

rcon.print((ok and 'OK' or 'ERROR') .. ' book="' .. tostring(manifest.label) .. '" import_result=' .. rc .. ' books=' .. n_books .. ' blueprints=' .. n_blueprints
  .. ' length=' .. #str .. ' problems=' .. (#problems == 0 and 'none' or table.concat(problems, '; ')))
