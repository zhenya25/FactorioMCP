early_game_force()
s.request_to_generate_chunks({1250, 50}, 8)
s.force_generate_chunk_requests()
local X, Y = 1200, 0
wipe(X - 10, Y - 10, X + 60, Y + 30)
clear_area(X - 10, Y - 10, X + 60, Y + 30)
local A = {name='assembling-machine-1', recipe='automation-science-pack'}
local G = {name='assembling-machine-1', recipe='iron-gear-wheel'}
local rows = {
  '   >>>>>>>>>>>>>>>>',
  ' >>>>>>>>>>>>>>>>> ',
  ' u pdU dUpdU dUpdU ',
  'G..A..A..A..A..A.. ',
  '.................. ',
  '.................. ',
  ' uup u pu pu pu pu ',
  '>>>>>>>>>>>>>>>>>> ',
}
local n = build_layout(X, Y, rows, {A=A, G=G})
-- test fixtures: two-lane plate feed on the left, drain on the right, power
place('transport-belt', X - 1, Y + 7, {dir=DIR.E})
place('transport-belt', X - 1, Y + 6, {dir=DIR.S}) source(X - 1, Y + 5, DIR.S, 'iron-plate')
place('transport-belt', X - 1, Y + 8, {dir=DIR.N}) source(X - 1, Y + 9, DIR.N, 'copper-plate')
sink(X + 19, Y, DIR.E)
place('small-electric-pole', X + 3, Y + 9) power(X + 4, Y + 9)
place('small-electric-pole', X + 3, Y + 8)
game.speed = 8
test_start()
rcon.print('built ' .. n)
storage.mcp_job = {items={'automation-science-pack'}, x1=X, y1=Y, x2=X + 19, y2=Y + 8, free=true, file='red-science',
  label='Красная наука 0.5/с',
  desc='5 сборщиков красных банок и 1 сборщик шестерён. Вход слева: одна лента, железо на верхней полосе, медь на нижней (1 железо/с, 0.5 меди/с). Выход справа сверху: 0.5 банки/с.'}
