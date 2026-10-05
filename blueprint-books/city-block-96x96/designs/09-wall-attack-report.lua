local w = storage.mcp_wall
local area = {{w.bx, w.by}, {w.bx + 96, w.by + 96}}
local kills = 0
for _, e in pairs(s.find_entities_filtered{type={'ammo-turret', 'electric-turret', 'fluid-turret'}, area=area}) do kills = kills + e.kills end
local alive = s.count_entities_filtered{force='enemy', type='unit', area={{w.bx - 60, w.by - 120}, {w.bx + 160, w.by + 100}}}
rcon.print('kills=' .. kills .. ' enemies_alive=' .. alive .. ' walls ' .. w.walls0 .. '->' .. s.count_entities_filtered{name='stone-wall', area=area} .. ' turrets ' .. w.turrets0 .. '->' .. s.count_entities_filtered{type={'ammo-turret', 'electric-turret', 'fluid-turret'}, area=area})
