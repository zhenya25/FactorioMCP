-- generic: report the running test, drop test fixtures, capture every design queued in storage.mcp_jobs
local out = {}
storage.mcp_strs = storage.mcp_strs or {}
for _, j in pairs(storage.mcp_jobs or {}) do
  local line = j.file .. ': ' .. test_report(j.items, j.x1 - 12, j.y1 - 12, j.x2 + 12, j.y2 + 12)
  local w, h = j.x2 - j.x1 + 6, j.y2 - j.y1 + 6
  game.take_screenshot{surface=s, position={(j.x1 + j.x2) / 2, (j.y1 + j.y2) / 2}, resolution={1400, 1400},
    zoom=math.min(1.5, 1300 / (32 * w), 1300 / (32 * h)), path='mcp/' .. j.file .. '.png', daytime=0, show_entity_info=true, force_render=true}
  for _, e in pairs(j.fixtures or {}) do if e.valid then e.destroy() end end
  if j.empty_chests then
    -- how evenly did the loading chests fill (one number per wagon, north to south)?
    local per = {}
    for i, r0 in pairs({43, 50, 57, 64}) do
      local n = 0
      for _, ch in pairs(s.find_entities_filtered{name='steel-chest', area={{j.x1 + 62, j.y1 + r0}, {j.x1 + 65, j.y1 + r0 + 6}}}) do n = n + ch.get_inventory(defines.inventory.chest).get_item_count() end
      per[i] = n
    end
    line = line .. ' | loaded per wagon: ' .. table.concat(per, ' ')
  end
  for _, v in pairs(j.variants or {{}}) do
    if v.stop_from then
      for _, st in pairs(s.find_entities_filtered{name='train-stop', area={{j.x1, j.y1}, {j.x2, j.y2}}}) do
        if st.backer_name == v.stop_from then st.backer_name = v.stop_to end
      end
    end
    local str, n = capture_blueprint(j.x1, j.y1, j.x2, j.y2, v.label or j.label, v.desc or j.desc, 'mcp/' .. (v.file or j.file) .. '.json', j.free)
    storage.mcp_strs[v.file or j.file] = str
    line = line .. ' | ' .. (v.file or j.file) .. '=' .. n
  end
  out[#out+1] = line
end
rcon.print(table.concat(out, '\n'))
