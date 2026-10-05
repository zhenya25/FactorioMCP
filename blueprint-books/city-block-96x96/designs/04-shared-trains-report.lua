local out = {string.format('%.0fs', (game.tick - storage.mcp_t0) / 60)}
local keys = {}
for k in pairs(storage.mcp_visits) do keys[#keys+1] = k end
table.sort(keys)
for _, k in pairs(keys) do out[#out+1] = k .. ' x' .. storage.mcp_visits[k] end
local names = {}
for k, v in pairs(defines.train_state) do names[v] = k end
for i, tr in pairs(storage.mcp_trains) do
  local c = {}
  for _, it in pairs(tr.get_contents()) do c[#c+1] = it.name .. '=' .. it.count end
  out[#out+1] = 'поезд' .. i .. ': ' .. tostring(names[tr.state]) .. ' at=' .. tostring(tr.station and tr.station.backer_name) .. ' cargo[' .. table.concat(c, ',') .. ']'
end
for _, st in pairs(s.find_entities_filtered{name='train-stop', area={{192, -96}, {384, 0}}}) do
  if string.find(st.backer_name, 'Разгрузка', 1, true) then
    local sum = {}
    for _, ch in pairs(s.find_entities_filtered{name='steel-chest', position=st.position, radius=40}) do
      if math.abs(ch.position.x - st.position.x) < 6 then for _, it in pairs(ch.get_inventory(defines.inventory.chest).get_contents()) do sum[it.name] = (sum[it.name] or 0) + it.count end end
    end
    out[#out+1] = st.backer_name .. ' chests=' .. serpent.line(sum)
  end
end
rcon.print(table.concat(out, '\n'))
