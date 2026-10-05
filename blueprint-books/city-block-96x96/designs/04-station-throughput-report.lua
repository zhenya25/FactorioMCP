local q = storage.mcp_st
local secs = (game.tick - q.tick) / 60
local function sum(x1, x2, y1, y2)
  local n = 0
  for _, ch in pairs(s.find_entities_filtered{name='steel-chest', area={{q.bx + x1, q.by + y1}, {q.bx + x2, q.by + y2}}}) do n = n + ch.get_inventory(defines.inventory.chest).get_item_count('iron-plate') end
  return n
end
local unload_left = sum(29, 37, 42, 70)
local drained = 48 * 2000 - unload_left
local w = {}
for i, r0 in pairs({43, 50, 57, 64}) do w[#w+1] = sum(62, 65, r0, r0 + 6) end
local lanes = {}
local belt = s.find_entities_filtered{type='transport-belt', position={q.bx + 37.5, q.by + 72.5}, radius=0.3}[1]
if belt then for i = 1, 2 do lanes[#lanes+1] = #belt.get_transport_line(i) end end
local dark = 0
for _, e in pairs(s.find_entities_filtered{type='inserter', area={{q.bx, q.by}, {q.bx + 96, q.by + 96}}}) do if not e.is_connected_to_electric_network() then dark = dark + 1 end end
rcon.print(string.format('%.0fs | unload: %.2f items/s onto the belt, lanes at exit=%s | load chests per wagon (north to south): %s | unpowered inserters=%d', secs, drained / secs, table.concat(lanes, '/'), table.concat(w, ' '), dark))
