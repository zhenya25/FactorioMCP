-- permanent power for the rail trunk, parked in the rail median next to a trunk pole (outside every block)
local pole = s.find_entities_filtered{name='big-electric-pole', position={206, -96}, radius=1.5}[1]
for _, e in pairs(s.find_entities_filtered{name='electric-energy-interface', position={209, -96}, radius=3}) do e.destroy() end
local src = s.create_entity{name='electric-energy-interface', position={208, -96}, force=f}
src.power_production = 5e9 / 60 src.electric_buffer_size = 5e9
rcon.print('pole=' .. tostring(pole ~= nil) .. ' same network=' .. tostring(pole and src.electric_network_id == pole.electric_network_id))
