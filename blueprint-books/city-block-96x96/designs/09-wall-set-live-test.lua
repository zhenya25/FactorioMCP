early_game_force()
game.speed = 4
for _, e in pairs(s.find_entities_filtered{force='enemy', area={{-500, -1000}, {1100, 500}}}) do e.destroy() end
s.request_to_generate_chunks({288, -200}, 8) s.force_generate_chunk_requests()
-- clear the wall strip and block 1 (keep the grid rails)
wipe(140, -244, 436, -150) clear_area(140, -244, 436, -100)
local bx, by = 192, -96
local KEEP = {['straight-rail']=true, ['curved-rail-a']=true, ['curved-rail-b']=true, ['half-diagonal-rail']=true, ['rail-signal']=true, ['rail-chain-signal']=true, ['roboport']=true, ['big-electric-pole']=true}
for _, t in pairs({'locomotive', 'cargo-wagon', 'fluid-wagon'}) do for _, e in pairs(s.find_entities_filtered{type=t, area={{bx - 50, by - 50}, {bx + 146, by + 146}}}) do e.destroy() end end
for _, e in pairs(s.find_entities_filtered{area={{bx + 6, by + 6}, {bx + 90, by + 90}}}) do
  if e.valid and e.force == f and not KEEP[e.name] and e.type ~= 'character' then e.destroy() end
end
for _, e in pairs(s.find_entities_filtered{force=f, area={{150, -150}, {430, -100}}}) do
  if e.valid and not KEEP[e.name] and e.type ~= 'character' and e.type ~= 'electric-energy-interface' then e.destroy() end
end
for _, e in pairs(s.find_entities_filtered{type={'transport-belt', 'underground-belt', 'pipe', 'pipe-to-ground'}, area={{150, -104}, {430, -88}}}) do e.destroy() end
local n1 = build_wall_straight(144, -240, false)
local n2 = build_wall_straight(240, -240, true)
local n3 = build_wall_corner(336, -240)
build_supply_post(bx, by)
stock_station(bx, by, 33, 'firearm-magazine', 10)
for i = 0, 4 do
  local car = s.create_entity{name=(i == 0 and 'locomotive' or 'fluid-wagon'), position={bx + 77, by + 74 - i * 7}, direction=defines.direction.south, force=f}
  if i > 0 then car.insert_fluid{name='crude-oil', amount=20000} end
end
-- the straight cell is upstream of the post: feed it directly so it can be checked too
local F = {}
for _, e in pairs(source(143, -240 + 52, DIR.E, 'firearm-magazine')) do F[#F+1] = e end
local ip = place('infinity-pipe', 143, -240 + 59) ip.set_infinity_pipe_filter({name='crude-oil', percentage=1, mode='at-least'}) F[#F+1] = ip
storage.mcp_walls = {{name='straight', x=144, y=-240}, {name='entrance', x=240, y=-240}, {name='corner', x=336, y=-240}}
storage.mcp_wallF = F
local from = T.start(288 + 3, -96 + 41, 0)
local to = T.start(288 + 3, -240 + 5, 0)
local back_from = T.start(288 - 3, -240 + 5, 8)
local back_to = T.start(288 - 3, -96 + 41, 8)
rcon.print('built straight=' .. n1 .. ' entrance=' .. n2 .. ' corner=' .. n3 .. ' | train route out through the wall: ' .. tostring(can_route(from, to)) .. ', back in: ' .. tostring(can_route(back_from, back_to)) .. ' | sig_fail=' .. #sig_fail)
