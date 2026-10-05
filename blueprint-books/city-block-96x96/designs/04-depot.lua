early_game_force()
local out = {}
local defs = {
  {bx=480, by=96, train=false, file='depot', label='Депо',
   desc='Путь через блок со станцией Депо (лимит 1 поезд): здесь общий поезд ждёт работы. У локомотива сундук с манипулятором для топлива - кладите уголь вручную или замените сундук на запросный.'},
  {bx=672, by=96, train=true, file='depot-with-train', label='Депо с поездом',
   desc='Депо и готовый общий поезд 1+4 в группе Грузовые: расписание и прерывания уже настроены. Поезд берёт груз на любой открытой станции Погрузка и везёт на станцию [предмет] Разгрузка. Ставьте по одному на каждый нужный поезд.'},
}
for _, d in pairs(defs) do
  wipe(d.bx, d.by, d.bx + 96, d.by + 96)
  clear_area(d.bx, d.by, d.bx + 96, d.by + 96)
  build_depot(d.bx, d.by, 47, d.train)
  local str, n = capture_blueprint(d.bx, d.by, d.bx + 96, d.by + 96, d.label, d.desc, 'mcp/' .. d.file .. '.json')
  storage.mcp_strs[d.file] = str
  out[#out+1] = d.file .. ' entities=' .. n
end
rcon.print(table.concat(out, '\n'))
