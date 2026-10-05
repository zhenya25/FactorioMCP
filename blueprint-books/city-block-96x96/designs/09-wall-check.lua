local out = {}
for _, w in pairs(storage.mcp_walls) do
  local area = {{w.x, w.y}, {w.x + 96, w.y + 96}}
  local res = {}
  local function tally(name, ok) res[name] = res[name] or {0, 0} res[name][ok and 1 or 2] = res[name][ok and 1 or 2] + 1 end
  for _, e in pairs(s.find_entities_filtered{name='gun-turret', area=area}) do tally('guns', not e.get_inventory(defines.inventory.turret_ammo).is_empty()) end
  for _, e in pairs(s.find_entities_filtered{name='flamethrower-turret', area=area}) do local fl = e.get_fluid(1) tally('flamers', fl ~= nil and fl.amount > 10) end
  for _, e in pairs(s.find_entities_filtered{name='laser-turret', area=area}) do tally('lasers', e.energy > 0) end
  for _, e in pairs(s.find_entities_filtered{type={'inserter', 'pump', 'roboport'}, area=area}) do tally('powered', e.is_connected_to_electric_network()) end
  local parts = {}
  for _, k in pairs({'guns', 'flamers', 'lasers', 'powered'}) do local v = res[k] or {0, 0} parts[#parts+1] = k .. ' ' .. v[1] .. '/' .. (v[1] + v[2]) end
  out[#out+1] = w.name .. ': ' .. table.concat(parts, ', ') .. ' | walls ' .. s.count_entities_filtered{name='stone-wall', area=area} .. ' gates ' .. s.count_entities_filtered{name='gate', area=area}
end
rcon.print(table.concat(out, '\n'))
