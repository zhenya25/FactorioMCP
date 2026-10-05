early_game_force()
storage.mcp_jobs = {}
game.speed = 8
-- 1) stone furnace line x12
do
  local X, Y = 1200, 60
  site(X, Y, 26, 6)
  local F = {name='stone-furnace'}
  local n = build_layout(X, Y, {
    '>>>>>>>>>>>>>>>>>>>>>>>>>',
    'upu upu upu upu upu upu ',
    'F.F.F.F.F.F.F.F.F.F.F.F.',
    '........................',
    'upu upu upu upu upu upu ',
    '>>>>>>>>>>>>>>>>>>>>>>>>',
  }, {F=F})
  two_lane_feed(X - 1, Y + 5, 'iron-ore', 'coal')
  sink(X + 25, Y, DIR.E)
  place('small-electric-pole', X + 1, Y + 7) power(X + 2, Y + 7)
  job{items={'iron-plate'}, x1=X, y1=Y, x2=X + 25, y2=Y + 6, free=true, file='furnace-line',
    label='Плавильная линия: 12 каменных печей',
    desc='Вход слева снизу: одна лента, руда на верхней полосе, уголь на нижней. Выход справа сверху: 3.75 плиты/с. Подходит для железа, меди и кирпича.'}
end
-- 2) electric mining drills, two rows of five around a belt
do
  local X, Y = 1200, 100
  site(X, Y, 20, 8)
  for x = X - 2, X + 20 do for y = Y - 2, Y + 8 do s.create_entity{name='copper-ore', position={x + 0.5, y + 0.5}, amount=20000} end end
  local T = {name='electric-mining-drill', dir=DIR.S}
  local M = {name='electric-mining-drill', dir=DIR.N}
  local n = build_layout(X, Y, {
    'T.. T..T.. T..T.. ',
    '...p......p......p',
    '.................. ',
    '>>>>>>>>>>>>>>>>>>>',
    'M.. M..M.. M..M.. ',
    '...p......p......p',
    '.................. ',
  }, {T=T, M=M})
  sink(X + 19, Y + 3, DIR.E)
  place('small-electric-pole', X + 3, Y + 8) power(X + 4, Y + 8)
  job{items={'copper-ore'}, x1=X, y1=Y, x2=X + 19, y2=Y + 7, free=true, file='electric-mining',
    label='Электробуры: 2 ряда по 5',
    desc='10 электрических буров по обе стороны ленты. Выход справа: до 5 руды/с. Ставится прямо на месторождение, продлевается копиями вправо.'}
end
test_start()
rcon.print('built')
