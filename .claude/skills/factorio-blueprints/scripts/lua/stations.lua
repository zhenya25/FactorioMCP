-- Train stations on a block spine. Requires common.lua, rails.lua, layout.lua.
-- A 1+4 train stopped on a spine has its wagons on these tile rows (relative to the block's top edge), 6 rows each.
local WAGON_ROWS = {43, 50, 57, 64}
local POLE_ROWS = {42, 49, 56, 63, 70}

local function red_wire(a, b)
  local ca = a.get_wire_connector(defines.wire_connector_id.circuit_red, true)
  local cb = b.get_wire_connector(defines.wire_connector_id.circuit_red, true)
  ca.connect_to(cb, false, defines.wire_origin.player)
end

-- One side of a platform: wagon inserter, chest, belt inserter in columns c1, c2, c3 (c1 next to the rail).
-- toward_rail=true loads wagons. Returns the chests, north to south.
local function gear_side(bx, by, x, side, toward_rail, bar)
  local out = side == 'W' and -1 or 1
  local c1 = side == 'W' and (x - 2) or (x + 1)
  local c2, c3 = c1 + out, c1 + 2 * out
  local moves_east = (side == 'W') == toward_rail
  local idir = moves_east and DIR.W or DIR.E
  local chests = {}
  for _, r0 in pairs(WAGON_ROWS) do
    for r = r0, r0 + 5 do
      place('bulk-inserter', bx + c1, by + r, {dir=idir})
      local chest = place('steel-chest', bx + c2, by + r)
      if bar then chest.get_inventory(defines.inventory.chest).set_bar(bar) end
      chests[#chests+1] = chest
      place('fast-inserter', bx + c3, by + r, {dir=idir})
    end
  end
  for _, r in pairs(POLE_ROWS) do place('medium-electric-pole', bx + c2, by + r) end
  for i = 2, #chests do red_wire(chests[i - 1], chests[i]) end
  return chests, c3 + out
end

local function stop_rule(stop, comparator, signal, threshold)
  stop.trains_limit = 1
  local cb = stop.get_or_create_control_behavior()
  cb.circuit_enable_disable = true
  cb.circuit_condition = {first_signal={type='virtual', name=signal}, comparator=comparator, constant=threshold}
end

-- Unloading station on spine x: inserters and chests on BOTH sides of the wagons. Each side fills one lane of
-- its belt (an inserter always drops on the far lane); one belt dives under the rail and side-loads into the
-- other, which gives a full two-lane belt. `to` ('W'/'E') is the side the full belt continues on, `exit`
-- ('S'/'N') the end it leaves by. The stop is open while the chests hold less than `threshold`.
-- Returns the stop and the first free tile after the belt (column, row), where the block picks it up.
local function build_unload(bx, by, x, name, threshold, to, exit)
  local stop = build_spine(bx, by, x, name)
  local cw, bw = gear_side(bx, by, x, 'W', false)
  local ce, be = gear_side(bx, by, x, 'E', false)
  red_wire(cw[1], ce[1])
  red_wire(cw[#cw], stop)
  stop_rule(stop, '<', 'signal-everything', threshold)
  local south = (exit ~= 'N')
  local flow = south and DIR.S or DIR.N
  local row = south and 71 or 41                 -- the row where the two belts meet
  local keep, cross = (to == 'E') and be or bw, (to == 'E') and bw or be
  local step = (to == 'E') and 1 or -1           -- direction the crossing belt travels
  local across = (to == 'E') and DIR.E or DIR.W
  for r = 43, 69 do
    place('transport-belt', bx + bw, by + r, {dir=flow})
    place('transport-belt', bx + be, by + r, {dir=flow})
  end
  local mid = south and 70 or 42
  place('transport-belt', bx + bw, by + mid, {dir=flow}) place('transport-belt', bx + be, by + mid, {dir=flow})
  place('transport-belt', bx + keep, by + row, {dir=flow})
  -- crossing belt: turn, run to the rail, go under it (the rail covers columns x-1 and x), come up, join
  local c = cross
  place('transport-belt', bx + c, by + row, {dir=across})
  local rail_in = (to == 'E') and (x - 2) or (x + 1)
  local rail_out = (to == 'E') and (x + 1) or (x - 2)
  c = c + step
  while c ~= rail_in do place('transport-belt', bx + c, by + row, {dir=across}) c = c + step end
  place('underground-belt', bx + rail_in, by + row, {dir=across, type='input'})
  place('underground-belt', bx + rail_out, by + row, {dir=across, type='output'})
  c = rail_out + step
  while c ~= keep do place('transport-belt', bx + c, by + row, {dir=across}) c = c + step end
  -- a big pole beside the exit links the station to the rail trunk (south exit only; clear of block belts)
  if south then place('big-electric-pole', bx + ((to == 'E') and (x + 5) or (x - 6)), by + 74) end
  return stop, keep, south and 72 or 40
end

-- Loading station on spine x, gear on one side. The incoming belt is split 1 -> 4 by three splitters and each
-- wagon gets its own belt, so all four wagons fill at the same rate. Chests are capped at 8 stacks (24 of them
-- hold just over one trainload). The stop is open once the chests hold at least `threshold`.
-- Returns the stop and the tile (column, row 38) where the block must deliver its product, flowing south.
local function build_load(bx, by, x, name, threshold, side)
  local stop = build_spine(bx, by, x, name)
  local chests, c4 = gear_side(bx, by, x, side, true, 9)
  red_wire(chests[#chests], stop)
  stop_rule(stop, '>=', 'signal-anything', threshold)
  local out = side == 'W' and -1 or 1
  local back = side == 'W' and DIR.E or DIR.W     -- from an outer lane back toward the rail
  for k = 0, 3 do
    local col, r0 = c4 + k * out, WAGON_ROWS[k + 1]
    for r = 41, (k == 0 and 42 or r0 - 1) do place('transport-belt', bx + col, by + r, {dir=DIR.S}) end
    if k > 0 then
      local cc = col
      while cc ~= c4 do place('transport-belt', bx + cc, by + r0, {dir=back}) cc = cc - out end
    end
    for r = r0, r0 + 5 do
      if not (k > 0 and r == r0 and false) then
        if not s.find_entities_filtered{type='transport-belt', position={bx + c4 + 0.5, by + r + 0.5}, radius=0.2}[1] then
          place('transport-belt', bx + c4, by + r, {dir=DIR.S})
        end
      end
    end
  end
  local west = math.min(c4, c4 + 3 * out)        -- westmost lane column
  place('splitter', bx + west + 1, by + 39, {dir=DIR.S})
  place('splitter', bx + west, by + 40, {dir=DIR.S})
  place('splitter', bx + west + 2, by + 40, {dir=DIR.S})
  -- a big pole below the platform links the station to the rail trunk (clear of the frame roboport)
  place('big-electric-pole', bx + ((side == 'E') and (x + 6) or (x - 7)), by + 72)
  return stop, west + 1, 38
end

-- Shared cargo trains (2.0 interrupts). Every loading stop is called 'Погрузка'; an unloading stop is
-- '[item=<name>] Разгрузка'. A train rests at 'Депо', takes any open load, then delivers to the stop
-- named after its cargo. Sets the schedule, interrupts and group on `train`.
local PARAM = '[virtual-signal=signal-item-parameter]'
local function shared_schedule(train)
  local sch = train.get_schedule()
  sch.clear_records()
  sch.add_record{station='Депо', wait_conditions={{type='inactivity', ticks=300, compare_type='and'}}}
  sch.add_interrupt{name='Разгрузка', inside_interrupt=false,
    conditions={
      {type='item_count', compare_type='and', condition={first_signal={type='virtual', name='signal-item-parameter'}, comparator='>', constant=0}},
      {type='specific_destination_not_full', compare_type='and', station=PARAM .. ' Разгрузка'},
    },
    targets={{station=PARAM .. ' Разгрузка', wait_conditions={{type='empty', compare_type='and'}}}}}
  sch.add_interrupt{name='Погрузка', inside_interrupt=false,
    conditions={
      {type='empty', compare_type='and'},
      {type='specific_destination_not_full', compare_type='and', station='Погрузка'},
    },
    targets={{station='Погрузка', wait_conditions={{type='full', compare_type='and'}, {type='inactivity', ticks=300, compare_type='or'}}}}}
  train.group = 'Грузовые'
end

-- Depot: a spine with the stop 'Депо' (limit 1) and a fuel chest feeding the locomotive.
-- with_train=true also parks a configured 1+4 shared train at the stop.
local function build_depot(bx, by, x, with_train)
  local stop = build_spine(bx, by, x, 'Депо')
  stop.trains_limit = 1
  place('inserter', bx + x + 1, by + 73, {dir=DIR.E})
  place('steel-chest', bx + x + 2, by + 73)
  place('medium-electric-pole', bx + x + 2, by + 74)
  if with_train then
    local train = nil
    for i = 0, 4 do
      local car = s.create_entity{name=(i == 0 and 'locomotive' or 'cargo-wagon'), position={bx + x, by + 74 - i * 7}, direction=defines.direction.south, force=f}
      if not car then error('could not park the train on the depot spine') end
      if i == 0 then car.insert{name='coal', count=50} end
      train = car.train
    end
    shared_schedule(train)
    train.manual_mode = false
    return stop, train
  end
  return stop
end

-- Fluid unloading on spine x (east side only: pumps on the west side do not connect). One pump per wagon on
-- the wagon's centre row (46, 53, 60, 67; rows -2 and +3 from the centre also connect), a collector pipe and
-- four storage tanks (100k). The stop is open while the tanks hold less than `threshold`.
-- Returns the stop and the tile above the first tank's north port, where the outgoing pipe starts.
local function build_fluid_unload(bx, by, x, name, threshold)
  local stop = build_spine(bx, by, x, name)
  for _, r in pairs({46, 53, 60, 67}) do place('pump', bx + x + 1, by + r, {dir=DIR.E}) end
  for r = 44, 67 do place('pipe', bx + x + 3, by + r) end
  local tanks = {}
  for _, r in pairs({44, 50, 56, 62}) do tanks[#tanks+1] = place('storage-tank', bx + x + 4, by + r) end
  place('substation', bx + x + 7, by + 46) place('substation', bx + x + 7, by + 60)
  local pole = place('medium-electric-pole', bx + x + 4, by + 70)
  for i = 2, #tanks do red_wire(tanks[i - 1], tanks[i]) end
  red_wire(tanks[#tanks], pole) red_wire(pole, stop)
  stop_rule(stop, '<', 'signal-everything', threshold)
  return stop, x + 4, 43
end
