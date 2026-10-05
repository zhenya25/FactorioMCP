early_game_force()
storage.mcp_jobs = {}
game.speed = 8
-- 2) steam power: 4 boilers, 8 engines
do
  local X, Y = 1200, 180
  site(X, Y, 18, 16)
  local c = canvas(16, 14)
  for k = 0, 3 do
    local x = 1 + 4 * k
    c:box(x, 0, 3, 5, 'E') c:box(x, 5, 3, 5, 'E') c:box(x, 10, 3, 2, 'K')
    c:set(x - 1, 2, 'p') c:set(x - 1, 7, 'p') c:set(x - 1, 11, 'o')
    c:set(x + 1, 12, 'u')
  end
  c:run(0, 13, 16, '>')
  build_layout(X, Y, c:rows(), {E={name='steam-engine', dir=DIR.N}, K={name='boiler', dir=DIR.N}, u={name='burner-inserter', dir=DIR.S}})
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
test_start()
rcon.print('built')
