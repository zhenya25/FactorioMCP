early_game_force()
local out = {}
local KEEP = {['straight-rail']=true, ['curved-rail-a']=true, ['curved-rail-b']=true, ['half-diagonal-rail']=true, ['rail-signal']=true, ['rail-chain-signal']=true}
local function reset(bx, by)
  for _, t in pairs({'locomotive', 'cargo-wagon'}) do for _, e in pairs(s.find_entities_filtered{type=t, area={{bx, by}, {bx + 96, by + 96}}}) do e.destroy() end end
  for _, e in pairs(s.find_entities_filtered{area={{bx + 5, by + 5}, {bx + 91, by + 91}}}) do
    if e.valid and e.force == f and not KEEP[e.name] and e.type ~= 'character' then e.destroy() end
  end
  for _, q in pairs({{'roboport', 24, 24}, {'roboport', 72, 24}, {'roboport', 24, 72}, {'roboport', 72, 72}, {'big-electric-pole', 21, 21}, {'big-electric-pole', 75, 21}, {'big-electric-pole', 21, 75}, {'big-electric-pole', 75, 75}}) do
    s.create_entity{name=q[1], position={bx + q[2], by + q[3]}, force=f}
  end
end
for _, key in pairs({'smelt-iron', 'gears', 'green-circuits', 'science-red'}) do
  reset(288, 0)
  out[#out+1] = fit_check(key, 288, 0)
end
-- station blueprints for book 4, built on clean cells
local defs = {
  {bx=480, by=480, kind='load', file='station-load', label='Станция погрузки',
   desc='Путь через блок с верхней линии на нижнюю и погрузка состава 1+4. Лента подаётся сверху в делитель 1 на 4: у каждого вагона своя лента и 6 сундуков, вагоны грузятся равномерно. Станция открыта, когда в сундуках набрался состав (16000 при стопке 100); лимит - 1 поезд. Все погрузки называются Погрузка.'},
  {bx=672, by=480, kind='unload', file='station-unload', label='Станция разгрузки',
   desc='Путь через блок с верхней линии на нижнюю и разгрузка состава 1+4 с обеих сторон вагонов: две ленты сводятся в одну полную, которая уходит вниз справа от пути. Станция открыта, пока в сундуках меньше двух составов (32000 при стопке 100); лимит - 1 поезд. В названии станции замените значок на свой предмет.'},
}
s.request_to_generate_chunks({624, 528}, 6) s.force_generate_chunk_requests()
for _, d in pairs(defs) do
  wipe(d.bx, d.by, d.bx + 96, d.by + 96) clear_area(d.bx, d.by, d.bx + 96, d.by + 96)
  if d.kind == 'load' then build_load(d.bx, d.by, 61, 'Погрузка', 16000, 'E')
  else build_unload(d.bx, d.by, 33, '[item=iron-plate] Разгрузка', 32000, 'E', 'S') end
  local str, n = capture_blueprint(d.bx, d.by, d.bx + 96, d.by + 96, d.label, d.desc, 'mcp/' .. d.file .. '.json')
  storage.mcp_strs[d.file] = str
  out[#out+1] = d.file .. ' entities=' .. n
end
reset(288, 0)
out[#out+1] = fit_check('station-load', 288, 0)
out[#out+1] = fit_check('station-unload', 288, 0)
rcon.print(table.concat(out, '\n'))
