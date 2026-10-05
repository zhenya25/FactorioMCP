-- export the user's reference blueprints (second quick bar row) and write an index of their labels
local index, top = {}, {}
local function walk(t, path, depth)
  local key = t.blueprint and 'blueprint' or (t.blueprint_book and 'blueprint_book') or next(t)
  local b = t[key]
  if key == 'blueprint_book' then
    index[#index+1] = string.rep('  ', depth) .. path .. ' BOOK ' .. tostring(b.label) .. ' (' .. #(b.blueprints or {}) .. ')'
    for i, ch in ipairs(b.blueprints or {}) do walk(ch, path .. '/' .. i, depth + 1) end
  elseif key == 'blueprint' then
    index[#index+1] = string.rep('  ', depth) .. path .. ' ' .. tostring(b.label) .. ' [' .. #(b.entities or {}) .. ' ent]'
  end
end
for i = 1, 10 do
  local ok, slot = pcall(function() return p.get_quick_bar_slot(p.get_active_quick_bar_page(2) or 2, i) end)
  if ok and slot and slot.record then
    local ok2, str = pcall(function() return slot.record.export_record() end)
    if ok2 and str then
      local json = helpers.decode_string(string.sub(str, 2))
      helpers.write_file('mcp/ref_slot' .. i .. '.json', json, false)
      local n0 = #index
      walk(helpers.json_to_table(json), 'slot' .. i, 0)
      top[#top+1] = 'slot' .. i .. ': ' .. tostring(slot.record.label) .. ' (' .. slot.record.type .. ', ' .. (#index - n0) .. ' entries)'
    else
      top[#top+1] = 'slot' .. i .. ': ' .. tostring(slot.record.label) .. ' NOT LOADED (preview)'
    end
  end
end
helpers.write_file('mcp/ref_index.txt', table.concat(index, '\n'), false)
rcon.print(table.concat(top, '\n'))
