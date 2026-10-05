early_game_force()
storage.mcp_jobs = {}
game.speed = 8
local function site96(bx, by) wipe(bx - 4, by - 4, bx + 100, by + 100) clear_area(bx, by, bx + 96, by + 96) watch(bx - 10, by - 8) end
local function fixtures(bx, by, o)
  local F = {place('electric-energy-interface', bx + 20, by + 54), place('substation', bx + 22, by + 56)}
  stock_station(bx, by, 33, o.a, 20)
  if o.b then stock_station(bx, by, 77, o.b, 20) end
  return F
end
do
  local bx, by = 480, 96
  site96(bx, by)
  local o = {machine='electric-furnace', n=12, a='iron-ore', out='iron-plate'}
  build_simple_block(bx, by, o)
  local function v(key, ore_item, ore, plate, what, rate)
    return {file='smelt-' .. key, label='Плавка: ' .. what, stop_to='[item=' .. ore_item .. '] Разгрузка',
      desc='Блок: 24 электропечи. Поезд привозит ' .. ore .. ' на левую станцию, ' .. plate .. ' уезжает с правой (' .. rate .. ' при полной ленте). Разгрузка с двух сторон вагонов в полную ленту, погрузка через делитель на 4 вагона.'}
  end
  local v1 = v('iron', 'iron-ore', 'железную руду', 'железные плиты', 'железо', '15/с')
  local v2 = v('copper', 'copper-ore', 'медную руду', 'медные плиты', 'медь', '15/с') v2.stop_from = '[item=iron-ore] Разгрузка'
  local v3 = v('brick', 'stone', 'камень', 'кирпич', 'кирпич', '7.5/с') v3.stop_from = '[item=copper-ore] Разгрузка'
  local v4 = v('steel', 'iron-plate', 'железные плиты', 'сталь', 'сталь', '3/с') v4.stop_from = '[item=stone] Разгрузка'
  job{items={'iron-plate'}, x1=bx, y1=by, x2=bx + 96, y2=by + 96, file='smelt-iron', fixtures=fixtures(bx, by, o), variants={v1, v2, v3, v4}, empty_chests=true}
end
do
  local bx, by = 480, 288
  site96(bx, by)
  local o = {machine='assembling-machine-2', recipe='iron-gear-wheel', n=4, a='iron-plate', out='iron-gear-wheel'}
  build_simple_block(bx, by, o)
  job{items={'iron-gear-wheel'}, x1=bx, y1=by, x2=bx + 96, y2=by + 96, file='gears', fixtures=fixtures(bx, by, o), empty_chests=true,
    label='Шестерни', desc='Блок: 8 сборщиков шестерён, 7.5 шестерни/с при полной ленте плит. Железные плиты - левая станция, шестерни уезжают с правой.'}
end
do
  local bx, by = 672, 288
  site96(bx, by)
  local o = {machine='assembling-machine-2', final='electronic-circuit', mid='copper-cable', n=12, a='iron-plate', b='copper-plate', out='electronic-circuit'}
  build_pair_block(bx, by, o)
  job{items={'electronic-circuit'}, x1=bx, y1=by, x2=bx + 96, y2=by + 96, file='green-circuits', fixtures=fixtures(bx, by, o), empty_chests=true,
    label='Зелёные схемы', desc='Блок: 12 пар сборщиков, провод делается на месте и сразу идёт в схемы. Железные плиты - левая станция, медные - крайняя правая, схемы уезжают со средней.'}
end
do
  local bx, by = 864, 288
  site96(bx, by)
  local o = {machine='assembling-machine-2', final='automation-science-pack', mid='iron-gear-wheel', n=12, a='copper-plate', b='iron-plate', out='automation-science-pack'}
  build_pair_block(bx, by, o)
  job{items={'automation-science-pack'}, x1=bx, y1=by, x2=bx + 96, y2=by + 96, file='science-red', fixtures=fixtures(bx, by, o), empty_chests=true,
    label='Красная наука', desc='Блок: 12 пар сборщиков, шестерни делаются на месте. Медные плиты - левая станция, железные - крайняя правая, банки уезжают со средней. Выход 1.8 банки/с.'}
end
test_start()
rcon.print('built sig_fail=' .. #sig_fail)
