-- Block frame: four reserved slots at the quarter points of a block whose top-left rail corner is (bx, by).
local function build_frame(bx, by)
  local fail = {}
  for _, q in pairs({{24, 24, 21, 21}, {72, 24, 75, 21}, {24, 72, 21, 75}, {72, 72, 75, 75}}) do
    local rp, pp = {bx + q[1], by + q[2]}, {bx + q[3], by + q[4]}
    clear(rp, 5)
    if not s.create_entity{name='roboport', position=rp, force=f} then fail[#fail+1] = 'roboport@' .. rp[1] .. ',' .. rp[2] end
    if not s.create_entity{name='big-electric-pole', position=pp, force=f} then fail[#fail+1] = 'pole@' .. pp[1] .. ',' .. pp[2] end
  end
  return fail
end
local out = {}
s.request_to_generate_chunks({528, -48}, 3)
s.force_generate_chunk_requests()
wipe(480, -96, 576, 0)
clear_area(480, -96, 576, 0)
local fail = build_frame(480, -96)
out[#out+1] = 'build_fail=' .. #fail .. ' ' .. table.concat(fail, ' ')
local str, n = capture_blueprint(480, -96, 576, 0,
  'Каркас блока',
  'Резерв в каждом блоке: 4 станции дронов в центрах четвертей и опора ЛЭП у каждой. Дроны покрывают весь блок и связаны с соседними блоками, опоры сами цепляются к магистрали в рельсах. Начинки блока обходят эти места.',
  'mcp/block-frame.txt')
out[#out+1] = 'captured=' .. n .. ' length=' .. #str

-- Verify the way the player uses it: stamp off-grid into two neighbouring blocks that already have rails.
local trunk = s.find_entities_filtered{name='big-electric-pole', position={192, -82}, radius=1}[1]
for _, at in pairs({{233, -41}, {300, -77}}) do
  local g, left, box = stamp_blueprint(str, at[1], at[2])
  out[#out+1] = 'stamp@' .. at[1] .. ',' .. at[2] .. ' ghosts=' .. g .. ' left=' .. left .. ' bbox=' .. table.concat(box, ',')
end
local poles_ok, poles_bad = 0, {}
for _, e in pairs(s.find_entities_filtered{name='big-electric-pole', area={{192, -96}, {384, 0}}}) do
  if e.electric_network_id == trunk.electric_network_id then poles_ok = poles_ok + 1 else poles_bad[#poles_bad+1] = e.position.x .. ',' .. e.position.y end
end
out[#out+1] = 'poles_on_trunk_network=' .. poles_ok .. ' off=' .. table.concat(poles_bad, ' ')
local nets, rp_unpowered = {}, 0
for _, e in pairs(s.find_entities_filtered{name='roboport', area={{192, -96}, {384, 0}}}) do
  local net = e.logistic_network
  nets[net and net.network_id or -1] = true
  if not e.is_connected_to_electric_network() then rp_unpowered = rp_unpowered + 1 end
end
local nn = 0 for _ in pairs(nets) do nn = nn + 1 end
out[#out+1] = 'logistic_networks_across_two_blocks=' .. nn .. ' roboports_without_power=' .. rp_unpowered
local uncovered = 0
for x = 192, 383 do for y = -96, -1 do
  if not s.find_logistic_network_by_position({x + 0.5, y + 0.5}, f) then uncovered = uncovered + 1 end
end end
out[#out+1] = 'tiles_without_logistic_coverage=' .. uncovered .. ' of ' .. (192 * 96)
game.take_screenshot{surface=s, position={288, -48}, resolution={1500, 800}, zoom=0.22, path='mcp/frame.png', daytime=0, show_entity_info=true, force_render=true}
rcon.print(table.concat(out, ' | '))
