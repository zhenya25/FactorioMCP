local rec = p.get_quick_bar_slot(p.get_active_quick_bar_page(2), 2).record
local t = helpers.json_to_table(helpers.decode_string(string.sub(rec.export_record(), 2)))
local function child(book, i) return book.blueprint_book.blueprints[i] end
local defense = child(t, 5)
local set = child(defense, 1)
local WHICH = tonumber(storage.mcp_refwall or 1)
local b = child(set, WHICH).blueprint
local CH = {['stone-wall']='#', gate='G', ['gun-turret']='g', ['laser-turret']='z', ['flamethrower-turret']='f', ['artillery-turret']='A', substation='S', ['big-electric-pole']='B', roboport='R', ['small-lamp']='*', pipe='o', ['pipe-to-ground']='o', ['long-handed-inserter']='i', ['bulk-inserter']='i', ['requester-chest']='c', radar='D', ['legacy-straight-rail']='=', ['rail-signal']='s'}
local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
for _, e in pairs(b.entities) do x1 = math.min(x1, e.position.x) y1 = math.min(y1, e.position.y) x2 = math.max(x2, e.position.x) y2 = math.max(y2, e.position.y) end
local W, H = math.floor(x2 - x1) + 2, math.floor(y2 - y1) + 2
local g = {}
for r = 0, H do g[r] = {} for c = 0, W do g[r][c] = ' ' end end
for _, e in pairs(b.entities) do
  local c, r = math.floor(e.position.x - x1), math.floor(e.position.y - y1)
  local ch = CH[e.name]
  if not ch then if string.find(e.name, 'belt') then ch = '-' else ch = '?' end end
  if e.name == 'gate' then ch = (e.direction == 4 or e.direction == 12) and 'H' or 'G' end
  g[r][c] = ch
end
local out = {b.label .. ' ' .. W .. 'x' .. H .. ' (rows ' .. (storage.mcp_r0 or 0) .. '..)'}
local r0 = tonumber(storage.mcp_r0 or 0)
for r = r0, math.min(H, r0 + 44) do out[#out+1] = table.concat(g[r], '', 0, W) end
rcon.print(table.concat(out, '\n'))
