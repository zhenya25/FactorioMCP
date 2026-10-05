early_game_force()
storage.mcp_jobs = {}
game.speed = 8
-- 1) green science, all in one, 0.5/s
do
  local X, Y = 1200, 140
  site(X, Y, 40, 10)
  local c = canvas(38, 9)
  local band = 3
  c:box(0, band, 3, 3, 'C') c:box(4, band, 3, 3, 'K') c:box(8, band, 3, 3, 'I') c:box(12, band, 3, 3, 'G') c:box(16, band, 3, 3, 'T')
  c:col(3, band, 3, 'r') c:set(7, band + 1, 'r') c:set(11, band + 1, 'l') c:set(15, band + 1, 'r')
  c:run(0, 1, 17, '>')                       -- plates: iron on the top lane, copper on the bottom lane
  c:run(17, 0, 20, '>')                      -- finished belts
  c:run(9, 7, 28, '>')                       -- finished inserters
  c:run(21, 8, 17, '>')                      -- science out
  c:set(0, 2, 'd') c:set(1, 2, 'd') c:set(4, 2, 'd') c:set(8, 2, 'd')
  c:set(12, 2, 'd') c:set(13, 2, 'd') c:set(14, 2, 'd') c:set(16, 2, 'd') c:set(17, 2, 'U')
  c:set(9, 6, 'd')
  for _, x in pairs({2, 6, 10, 15}) do c:set(x, 2, 'p') end
  c:set(2, 6, 'p') c:set(10, 6, 'p') c:set(15, 6, 'p')
  for k = 0, 5 do
    local x = 19 + 3 * k
    c:box(x, band, 3, 3, 'A')
    c:set(x + 1, 2, 'D') c:set(x + 2, 2, 'p')
    c:set(x, 6, 'u') c:set(x + 1, 6, 'p') c:set(x + 2, 6, 'D')
  end
  local am = function(r) return {name='assembling-machine-1', recipe=r} end
  build_layout(X, Y, c:rows(), {C=am('copper-cable'), K=am('electronic-circuit'), I=am('inserter'), G=am('iron-gear-wheel'), T=am('transport-belt'), A=am('logistic-science-pack')})
  two_lane_feed(X - 1, Y + 1, 'iron-plate', 'copper-plate')
  sink(X + 38, Y + 8, DIR.E)
  place('small-electric-pole', X + 2, Y + 9) power(X + 3, Y + 9)
  job{items={'logistic-science-pack', 'transport-belt', 'inserter', 'electronic-circuit', 'iron-gear-wheel'}, x1=X, y1=Y, x2=X + 38, y2=Y + 9, free=true, file='green-science',
    label='Зелёная наука 0.5/с',
    desc='Всё в одном: провода, схемы, шестерни, ленты, манипуляторы и 6 сборщиков зелёных банок. Вход слева сверху: одна лента, железо на верхней полосе (2.75/с), медь на нижней (0.75/с). Выход справа снизу: 0.5 банки/с.'}
end
-- 2) steam power: 4 boilers, 8 engines
do
  local X, Y = 1200, 180
  site(X, Y, 18, 16)
  local c = canvas(16, 14)
  for k = 0, 3 do
    local x = 1 + 4 * k
    c:box(x, 0, 3, 5, 'E') c:box(x, 5, 3, 5, 'E') c:box(x, 10, 3, 2, 'K')
    c:set(x - 1, 2, 'p') c:set(x - 1, 7, 'p') c:set(x - 1, 11, 'o') c:set(x - 1, 12, 'p')
    c:set(x + 1, 12, 'u')
  end
  c:run(0, 13, 16, '>')
  build_layout(X, Y, c:rows(), {E={name='steam-engine', dir=DIR.N}, K={name='boiler', dir=DIR.N}})
  local w = place('infinity-pipe', X - 1, Y + 11)
  w.set_infinity_pipe_filter({name='water', percentage=1, mode='at-least'})
  source(X - 1, Y + 13, DIR.E, 'coal')
  local load = place('electric-energy-interface', X - 3, Y + 1)
  load.power_production = 0 load.electric_buffer_size = 2e8 load.power_usage = 7.2e6 / 60 load.energy = 0
  place('small-electric-pole', X - 1, Y + 3)
  job{items={'steam'}, x1=X, y1=Y, x2=X + 16, y2=Y + 14, free=true, file='steam-power',
    label='Паровая электростанция 7.2 МВт',
    desc='4 бойлера и 8 паровых двигателей. Вода подаётся трубой слева (к нижней трубе), уголь - лентой снизу слева. Один насос тянет до 20 таких бойлеров; продлевается копиями вправо.'}
end
-- 3) labs x8 on one belt
do
  local X, Y = 1200, 220
  site(X, Y, 14, 10)
  local c = canvas(12, 9)
  for k = 0, 3 do
    local x = 3 * k
    c:box(x, 0, 3, 3, 'L') c:box(x, 6, 3, 3, 'L')
    c:set(x + 1, 3, 'u') c:set(x + 1, 5, 'd')
  end
  c:set(2, 3, 'p') c:set(8, 3, 'p') c:set(2, 5, 'p') c:set(8, 5, 'p')
  c:run(0, 4, 12, '>')
  build_layout(X, Y, c:rows(), {L={name='lab'}})
  two_lane_feed(X - 1, Y + 4, 'automation-science-pack', 'logistic-science-pack')
  place('small-electric-pole', X + 2, Y + 9) power(X + 3, Y + 9)
  local tech = f.technologies['engine']
  tech.researched = false
  f.add_research(tech)
  job{items={'-automation-science-pack', '-logistic-science-pack'}, x1=X, y1=Y, x2=X + 12, y2=Y + 9, free=true, file='labs',
    label='Лаборатории x8',
    desc='8 лабораторий по обе стороны одной ленты. Вход слева: красные банки на верхней полосе, зелёные на нижней. Продлевается копиями вправо.'}
end
test_start()
rcon.print('built')
