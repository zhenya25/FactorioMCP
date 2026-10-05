-- Build each wall piece on clean land (no grid rails around) and capture it. The designs themselves are
-- checked in the live grid by 09-wall-set-live-test.lua.
early_game_force()
for _, e in pairs(storage.mcp_wallF or {}) do if e.valid then e.destroy() end end
for _, e in pairs(s.find_entities_filtered{force='enemy', area={{900, -1200}, {2000, 0}}}) do e.destroy() end
s.request_to_generate_chunks({1400, -600}, 12) s.force_generate_chunk_requests()
local out = {}
local function site(x0, y0, h) wipe(x0 - 4, y0 - 4, x0 + 100, y0 + h + 4) clear_area(x0, y0, x0 + 96, y0 + h) end
local function cap(x0, y0, h, key, label, desc)
  local _, n = capture_blueprint(x0, y0, x0 + 96, y0 + h, label, desc, 'mcp/' .. key .. '.json')
  out[#out+1] = key .. '=' .. n
end
site(1152, -672, 122) build_wall_straight(1152, -672, false)
cap(1152, -672, 122, 'wall-straight', 'Стена: прямая секция',
  'Ячейка стоит по центру узла сетки, стена идёт по самой линии сетки; фронт на север (поворот - R). Снаружи 5 линий стенок с разрывами, стена в 2 ряда, пулемёты с лентой, лазеры, огнемёты с трубой и насосом. Клетки 58-61 - ворота для игрока.')
site(1344, -672, 122) build_wall_straight(1344, -672, true)
cap(1344, -672, 122, 'wall-entrance', 'Стена: въезд поезда',
  'Та же секция, но через центр проходят два пути рельсовой линии; во всех линиях стенок на рельсах ворота, лента и труба уходят под пути. Ставится там, где линия сетки выходит за стену.')
site(1536, -672, 122) build_wall_corner(1536, -672)
cap(1536, -672, 122, 'wall-corner', 'Стена: угол',
  'Угловая ячейка по центру узла, фронт на север и восток (поворот - R). Стенки, лента и труба огибают угол; на изломе трубы огнемёт стоит под 45 градусов.')
site(1152, -480, 192) build_supply_post(1152, -384)
cap(1152, -480, 192, 'wall-supply-post', 'Пост снабжения стены',
  'Блок во втором ряду за стеной. Левая станция принимает патроны (открыта, когда их меньше 2000), правая - цистерны с топливом в 4 бака. Лента и труба идут на север под рельсами и входят в секцию стены справа сверху. Значки в названиях станций замените на свои.')
rcon.print(table.concat(out, ' ') .. ' sig_fail=' .. #sig_fail)
