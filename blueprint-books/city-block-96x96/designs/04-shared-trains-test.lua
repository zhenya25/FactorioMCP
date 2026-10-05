early_game_force()
local out = {}
local KEEP = {['straight-rail']=true, ['curved-rail-a']=true, ['curved-rail-b']=true, ['half-diagonal-rail']=true, ['rail-signal']=true, ['rail-chain-signal']=true, ['roboport']=true, ['big-electric-pole']=true}
local function reset_block(bx, by)
  for _, t in pairs({'locomotive', 'cargo-wagon'}) do for _, e in pairs(s.find_entities_filtered{type=t, area={{bx - 50, by - 50}, {bx + 146, by + 146}}}) do e.destroy() end end
  for _, e in pairs(s.find_entities_filtered{area={{bx + 6, by + 6}, {bx + 90, by + 90}}}) do
    if e.valid and e.force == f and not KEEP[e.name] and e.type ~= 'character' then e.destroy() end
  end
  for _, e in pairs(s.find_entities_filtered{type={'infinity-container', 'loader-1x1', 'electric-energy-interface'}, area={{bx, by}, {bx + 96, by + 96}}}) do e.destroy() end
end
local function depot(bx, by)
  local st = build_spine(bx, by, 47, 'Депо')
  st.trains_limit = 1
end
local function fixtures(bx, by, item, lc, uc)
  source(bx + lc, by + 42, DIR.S, item)
  sink(bx + uc, by + 70, DIR.S)
  place('electric-energy-interface', bx + 44, by + 38)
  for _, x in pairs({30, 37, 43, 51, 58, 62}) do place('medium-electric-pole', bx + x, by + 41) end
end
local B1, B2 = {192, -96}, {288, -96}
reset_block(B1[1], B1[2]) reset_block(B2[1], B2[2])
local _, lc = build_station(B1[1], B1[2], 33, 'load', 'W', 'Погрузка', 2000, DIR.S)
local _, uc = build_station(B1[1], B1[2], 61, 'unload', 'E', '[item=copper-plate] Разгрузка', 32000, DIR.S)
depot(B1[1], B1[2]) fixtures(B1[1], B1[2], 'iron-plate', lc, uc)
build_station(B2[1], B2[2], 33, 'load', 'W', 'Погрузка', 2000, DIR.S)
build_station(B2[1], B2[2], 61, 'unload', 'E', '[item=iron-plate] Разгрузка', 32000, DIR.S)
depot(B2[1], B2[2]) fixtures(B2[1], B2[2], 'copper-plate', lc, uc)

storage.mcp_trains = {}
storage.mcp_visits = {}
for i, b in pairs({B1, B2}) do
  local tr = test_train(b[1], b[2], 'Депо', 2)
  local sch = tr.get_schedule()
  sch.clear_records()
  sch.add_record{station='Депо', wait_conditions={{type='inactivity', ticks=120, compare_type='and'}}}
  local P = '[virtual-signal=signal-item-parameter]'
  local ok1, e1 = pcall(function() sch.add_interrupt{name='Разгрузка', inside_interrupt=false,
    conditions={
      {type='item_count', compare_type='and', condition={first_signal={type='virtual', name='signal-item-parameter'}, comparator='>', constant=0}},
      {type='specific_destination_not_full', compare_type='and', station=P .. ' Разгрузка'},
    },
    targets={{station=P .. ' Разгрузка', wait_conditions={{type='empty', compare_type='and'}}}}} end)
  local ok2, e2 = pcall(function() sch.add_interrupt{name='Погрузка', inside_interrupt=false,
    conditions={
      {type='empty', compare_type='and'},
      {type='specific_destination_not_full', compare_type='and', station='Погрузка'},
    },
    targets={{station='Погрузка', wait_conditions={{type='full', compare_type='and'}, {type='inactivity', ticks=300, compare_type='or'}}}}} end)
  pcall(function() tr.group = 'Грузовые' end)
  tr.manual_mode = false
  storage.mcp_trains[i] = tr
  out[#out+1] = 'train' .. i .. ' interrupts: ' .. tostring(ok1) .. ' ' .. tostring(e1) .. ' / ' .. tostring(ok2) .. ' ' .. tostring(e2) .. ' count=' .. #sch.get_interrupts() .. ' group=' .. tostring(tr.group)
end
script.on_event(defines.events.on_train_changed_state, function(ev)
  local tr = ev.train
  if tr.state == defines.train_state.wait_station and tr.station then
    for i, t in pairs(storage.mcp_trains or {}) do
      if t.valid and t == tr then
        local k = 'поезд' .. i .. ' -> ' .. tr.station.backer_name
        storage.mcp_visits[k] = (storage.mcp_visits[k] or 0) + 1
      end
    end
  end
end)
storage.mcp_t0 = game.tick
game.speed = 16
rcon.print(table.concat(out, '\n') .. '\nsig_fail=' .. #sig_fail)
