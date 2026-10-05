early_game_force()
local bx, by = 192, -96
local KEEP = {['straight-rail']=true, ['curved-rail-a']=true, ['curved-rail-b']=true, ['half-diagonal-rail']=true, ['rail-signal']=true, ['rail-chain-signal']=true, ['roboport']=true, ['big-electric-pole']=true}
for _, b in pairs({{192, -96}, {288, -96}}) do
  for _, t in pairs({'locomotive', 'cargo-wagon'}) do for _, e in pairs(s.find_entities_filtered{type=t, area={{b[1] - 50, b[2] - 50}, {b[1] + 146, b[2] + 146}}}) do e.destroy() end end
  for _, e in pairs(s.find_entities_filtered{area={{b[1] + 6, b[2] + 6}, {b[1] + 90, b[2] + 90}}}) do
    if e.valid and e.force == f and not KEEP[e.name] and e.type ~= 'character' then e.destroy() end
  end
  for _, e in pairs(s.find_entities_filtered{type={'infinity-container', 'loader-1x1', 'electric-energy-interface'}, area={{b[1], b[2]}, {b[1] + 96, b[2] + 96}}}) do e.destroy() end
end
local us, ux, uy = build_unload(bx, by, 33, '[item=iron-plate] Разгрузка', 32000, 'E', 'S')
local ls, lx, ly = build_load(bx, by, 61, 'Погрузка', 16000, 'E')
sink(bx + ux, by + uy, DIR.S)
source(bx + lx, by + ly, DIR.S, 'iron-plate')
place('electric-energy-interface', bx + 46, by + 44)
for _, x in pairs({40, 45, 52, 58}) do place('medium-electric-pole', bx + x, by + 42) end
local stocked = stock_station(bx, by, 33, 'iron-plate', 20)
storage.mcp_st = {tick=game.tick, bx=bx, by=by}
game.speed = 8
rcon.print('unload exit=' .. ux .. ',' .. uy .. ' load input=' .. lx .. ',' .. ly .. ' stocked chests=' .. stocked .. ' sig_fail=' .. #sig_fail)
