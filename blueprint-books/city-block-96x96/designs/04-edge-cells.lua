local out = {}
s.request_to_generate_chunks({768, -384}, 9)
s.request_to_generate_chunks({768, -672}, 9)
s.force_generate_chunk_requests()
local defs = {
  {key='t-junction', cx=576, arms={W=true, E=true, S=true}, rot={N=true, S=true, W=true},
   label='Т-образный перекрёсток', desc='Ячейка сетки 96x96 для края города: рельсы на запад, восток и юг, без северной стороны. Поворачивается клавишей R. Сигналы и опоры ЛЭП внутри.'},
  {key='corner', cx=768, arms={S=true, E=true}, rot={W=true, S=true},
   label='Угол', desc='Ячейка сетки 96x96 для угла города: поворот между южной и восточной сторонами. Поворачивается клавишей R. Сигналы и опоры ЛЭП внутри.'},
  {key='straight', cx=960, arms={W=true, E=true}, rot={N=true, S=true},
   label='Прямой участок', desc='Ячейка сетки 96x96 без перекрёстка: два пути с запада на восток. Для края города; поворачивается клавишей R. Сигналы и опоры ЛЭП внутри.'},
}
storage.mcp_strs = storage.mcp_strs or {}
for _, d in pairs(defs) do
  local cy = -384
  wipe(d.cx - 48, cy - 48, d.cx + 48, cy + 48)
  clear_area(d.cx - 48, cy - 48, d.cx + 48, cy + 48)
  build_cell(d.cx, cy, d.arms)
  local pf = add_cell_poles(d.cx, cy, d.arms)
  local bad, txt = path_test(d.cx, cy, d.arms)
  local str, n = capture_blueprint(d.cx - 48, cy - 48, d.cx + 48, cy + 48, d.label, d.desc, 'mcp/' .. d.key .. '.json')
  storage.mcp_strs[d.key] = str
  -- rotated copy, clicked off-centre two cells further north
  local ry = -672
  wipe(d.cx - 48, ry - 48, d.cx + 48, ry + 48)
  clear_area(d.cx - 48, ry - 48, d.cx + 48, ry + 48)
  local g, left, box = stamp_blueprint(str, d.cx + 21, ry - 17, defines.direction.east)
  local rbad, rtxt = path_test(d.cx, ry, d.rot)
  out[#out+1] = d.key .. ': entities=' .. n .. ' pole_fail=' .. pf .. ' missing_routes=' .. bad .. ' [' .. txt .. '] | rotated: ghosts=' .. g .. ' left=' .. left .. ' bbox=' .. table.concat(box, ',') .. ' missing_routes=' .. rbad .. ' [' .. rtxt .. ']'
end
out[#out+1] = 'signal_fail=' .. #sig_fail
game.take_screenshot{surface=s, position={768, -384}, resolution={1700, 520}, zoom=0.1, path='mcp/edges.png', daytime=0, show_entity_info=false, force_render=true}
game.take_screenshot{surface=s, position={768, -672}, resolution={1700, 520}, zoom=0.1, path='mcp/edges_rot.png', daytime=0, show_entity_info=false, force_render=true}
rcon.print(table.concat(out, '\n'))
