local out = {}
-- Cell = one block from rail centre line to rail centre line. Road = 6 tiles from each centre line.
local function is_road(x, y) return x < 6 or x >= 90 or y < 6 or y >= 90 end
local function is_edge(x, y)
  return ((x == 5 or x == 90) and y >= 5 and y <= 90) or ((y == 5 or y == 90) and x >= 5 and x <= 90)
end
local landfill, block, road, both = {}, {}, {}, {}
for x = 0, 95 do for y = 0, 95 do
  local pos = {x = x, y = y}
  landfill[#landfill+1] = {name = 'landfill', position = pos}
  if is_road(x, y) then
    local name = is_edge(x, y) and 'refined-hazard-concrete-left' or 'refined-concrete'
    road[#road+1] = {name = name, position = pos}
    both[#both+1] = {name = name, position = pos}
  else
    block[#block+1] = {name = 'refined-concrete', position = pos}
    both[#both+1] = {name = 'refined-concrete', position = pos}
  end
end end
local strs = {}
local function mk(key, tiles, label, desc)
  local str, n = make_tile_blueprint(tiles, label, desc, 'mcp/' .. key .. '.json', 0, 0)
  strs[key] = str
  out[#out+1] = key .. ' tiles=' .. n
end
mk('landfill-block', landfill, 'Засыпка блока', 'Засыпает воду на всём блоке 96x96 вместе с полосой под рельсы. Ставится первым, если блок попадает на воду.')
mk('paved-block', block, 'Покрытие блока', 'Улучшенный бетон на внутренней площади блока, без полосы рельсов.')
mk('paved-road', road, 'Покрытие дороги', 'Улучшенный бетон под рельсами вокруг блока, с разметкой по краю.')
mk('paved-road-and-block', both, 'Покрытие: дорога и блок', 'Улучшенный бетон на весь блок 96x96: площадь блока и полоса рельсов с разметкой.')
storage.mcp_strs = strs

-- Lights and radar for the rail median, built on a clean cell (no rails) so only they are captured.
local cx, cy = 576, -192
s.request_to_generate_chunks({cx, cy}, 3)
s.force_generate_chunk_requests()
wipe(cx - 48, cy - 48, cx + 48, cy + 48)
clear_area(cx - 48, cy - 48, cx + 48, cy + 48)
local fail = 0
local function put(name, x, y) if not s.create_entity{name=name, position={x, y}, force=f} then fail = fail + 1 end end
for _, a in pairs({-40, -14, 14, 40}) do
  put('small-lamp', cx - 1.5, cy + a - 0.5) put('small-lamp', cx + 1.5, cy + a - 0.5)
  put('small-lamp', cx + a - 0.5, cy - 1.5) put('small-lamp', cx + a - 0.5, cy + 1.5)
end
put('radar', cx - 0.5, cy - 16.5)
local str, n = capture_blueprint(cx - 48, cy - 48, cx + 48, cy + 48,
  'Свет и радар',
  'Лампы у каждой опоры в полосе между путями и один радар на перекрёсток. Ставится поверх перекрёстка, питание берёт от его опор.',
  'mcp/lights-and-radar.json')
storage.mcp_strs['lights-and-radar'] = str
out[#out+1] = 'lights build_fail=' .. fail .. ' captured=' .. n
rcon.print(table.concat(out, ' | '))
