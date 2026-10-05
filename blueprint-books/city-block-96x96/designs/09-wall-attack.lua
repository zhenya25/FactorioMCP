local w = storage.mcp_wall
local area = {{w.bx, w.by}, {w.bx + 96, w.by + 96}}
w.walls0 = s.count_entities_filtered{name='stone-wall', area=area}
w.turrets0 = s.count_entities_filtered{type={'ammo-turret', 'electric-turret', 'fluid-turret'}, area=area}
local n = 0
for i = 1, 60 do
  local name = (i % 4 == 0) and 'medium-spitter' or 'medium-biter'
  local e = s.create_entity{name=name, position={w.bx + 20 + (i % 12) * 5, w.by - 45 - math.floor(i / 12) * 3}, force='enemy'}
  if e then
    n = n + 1
    e.commandable.set_command{type=defines.command.attack_area, destination={w.bx + 48, w.by + 12}, radius=30, distraction=defines.distraction.by_anything}
  end
end
game.speed = 4
rcon.print('spawned ' .. n .. ' walls=' .. w.walls0 .. ' turrets=' .. w.turrets0)
