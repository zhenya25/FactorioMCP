-- Rail building helpers. Requires common.lua.
-- Rails are laid through the game's own rail planner API (LuaRailEnd.get_rail_extensions),
-- so curve pieces always land on valid positions. Headings are 16-way: 0 north, 4 east, 8 south, 12 west.
local T = {}

local function same_loc(a, b)
  return a.position.x == b.position.x and a.position.y == b.position.y and a.direction == b.direction
end
local function end_at(rail, loc)
  for _, rd in pairs({defines.rail_direction.front, defines.rail_direction.back}) do
    local e = rail.get_rail_end(rd)
    if same_loc(e.location, loc) then return e end
  end
  return nil
end

-- Place (or reuse) a straight rail centred on odd coordinates (x, y) and return its end facing `dir`.
function T.start(x, y, dir)
  clear({x, y}, 3)
  local rdir = (dir == 0 or dir == 8) and defines.direction.north or defines.direction.east
  local rail = nil
  for _, c in pairs(s.find_entities_filtered{name='straight-rail', position={x, y}, radius=0.5}) do
    if c.direction == rdir then rail = c end
  end
  rail = rail or s.create_entity{name='straight-rail', position={x, y}, direction=rdir, force=f}
  for _, rd in pairs({defines.rail_direction.front, defines.rail_direction.back}) do
    local e = rail.get_rail_end(rd)
    if e.location.direction == dir then return e end
  end
  error('no rail end with heading ' .. dir .. ' at ' .. x .. ',' .. y)
end

-- Extend by one piece: turn = 0 straight, -1 left, 1 right (1/16 of a circle per step).
function T.step(e, turn)
  local cur = e.location.direction
  local want = (cur + turn) % 16
  for _, x in pairs(e.get_rail_extensions('rail')) do
    if x.name ~= 'rail-ramp' and x.goal.direction == want and x.goal.rail_layer == 0 then
      clear(x.position, 4)
      local rail = nil
      for _, c in pairs(s.find_entities_filtered{name=x.name, position=x.position, radius=0.5}) do
        if c.direction == x.direction then rail = c end
      end
      rail = rail or s.create_entity{name=x.name, position=x.position, direction=x.direction, force=f}
      if not rail then error('cannot create ' .. x.name .. ' at ' .. x.position.x .. ',' .. x.position.y) end
      local ne = end_at(rail, x.goal)
      if not ne then error('no matching end after ' .. x.name) end
      return ne
    end
  end
  error('no extension for turn ' .. turn .. ' from heading ' .. cur)
end

-- Run a string of moves: S straight, L left, R right. 'RRRR' is a 90-degree right turn (13 tiles each way).
function T.run(e, moves)
  for i = 1, #moves do
    local c = moves:sub(i, i)
    e = T.step(e, c == 'L' and -1 or (c == 'R' and 1 or 0))
  end
  return e
end

-- Go straight until the end location is exactly (x, y).
function T.straight_to(e, x, y)
  for _ = 1, 400 do
    local l = e.location
    if l.position.x == x and l.position.y == y then return e end
    e = T.step(e, 0)
  end
  error('straight_to did not reach ' .. x .. ',' .. y)
end

local function L(e) local l = e.location return l.position.x .. ',' .. l.position.y .. ' h' .. l.direction end

-- Signal for trains leaving through rail end `e` (right-hand side). Collects failures in sig_fail.
local sig_fail = {}
local function signal(e, name)
  local loc = e.out_signal_location
  if s.find_entities_filtered{type={'rail-signal', 'rail-chain-signal'}, position=loc.position, radius=0.3}[1] then return end
  local sg = s.create_entity{name=name, position=loc.position, direction=loc.direction, force=f}
  if not sg then sig_fail[#sig_fail+1] = name .. '@' .. loc.position.x .. ',' .. loc.position.y end
end

-- Grid geometry. An intersection sits at (cx, cy), both multiples of 96.
-- P maps "a tiles along heading h, r tiles to the right of the centre line" to world coordinates.
-- Right-hand traffic: the track for heading h runs at r = 3.
local FWD = {[0]={0, -1}, [4]={1, 0}, [8]={0, 1}, [12]={-1, 0}}
local RGT = {[0]={1, 0}, [4]={0, 1}, [8]={-1, 0}, [12]={0, -1}}
local function P(cx, cy, h, a, r)
  h = h % 16
  return cx + a * FWD[h][1] + r * RGT[h][1], cy + a * FWD[h][2] + r * RGT[h][2]
end

-- A cell's arms are the compass sides that have rails: a set like {N=true, E=true, S=true, W=true}.
-- Defaults to all four (a full intersection). Three arms give a T, two adjacent a corner, two opposite a straight.
local ARM = {[0]='N', [4]='E', [8]='S', [12]='W'}
local ALL_ARMS = {N=true, E=true, S=true, W=true}
local function has_arm(arms, h) return (arms or ALL_ARMS)[ARM[h % 16]] end

-- Build the 96x96 grid cell centred on (cx, cy): tracks, the turns its arms allow, signals.
-- A train heading h enters by the arm behind it and may leave straight, right (h+4) or left (h+12).
local function build_cell(cx, cy, arms)
  for _, h in pairs({0, 4, 8, 12}) do
    if has_arm(arms, h + 8) then
      local x, y = P(cx, cy, h, -47, 3)
      if has_arm(arms, h) then
        local ex, ey = P(cx, cy, h, 48, 3)
        T.straight_to(T.start(x, y, h), ex, ey)
      end
      if has_arm(arms, h + 4) then
        local bx, by = P(cx, cy, h, -16, 3)
        local e = T.run(T.straight_to(T.start(x, y, h), bx, by), 'RRRR')
        local ex, ey = P(cx, cy, h + 4, 48, 3)
        T.straight_to(e, ex, ey)
      end
      if has_arm(arms, h + 12) then
        local bx, by = P(cx, cy, h, -10, 3)
        local e = T.run(T.straight_to(T.start(x, y, h), bx, by), 'LLLL')
        local ex, ey = P(cx, cy, (h + 12) % 16, 48, 3)
        T.straight_to(e, ex, ey)
      end
    end
  end
  -- Chain signal on every entry, plain signal on every exit; the cell is one signal block.
  for _, h in pairs({0, 4, 8, 12}) do
    if has_arm(arms, h + 8) then
      local x, y = P(cx, cy, h, -19, 3)
      signal(T.start(x, y, h), 'rail-chain-signal')
    end
    if has_arm(arms, h) then
      local x, y = P(cx, cy, h, 17, 3)
      signal(T.start(x, y, h), 'rail-signal')
    end
  end
end

-- Big electric poles in the median of each arm. Returns the number that could not be placed.
local function add_cell_poles(cx, cy, arms)
  local fail = 0
  for _, h in pairs({0, 4, 8, 12}) do
    if has_arm(arms, h) then
      for _, a in pairs({14, 40}) do
        local x, y = P(cx, cy, h, a, 0)
        clear({x, y}, 2)
        if not s.find_entities_filtered{name='big-electric-pole', position={x, y}, radius=0.5}[1] then
          if not s.create_entity{name='big-electric-pole', position={x, y}, force=f} then fail = fail + 1 end
        end
      end
    end
  end
  return fail
end

-- Ask the game's train pathfinder whether a train on rail end `from` can reach rail end `to`.
local function can_route(from, to)
  local r = game.train_manager.request_train_path{
    type = 'any-goal-accessible',
    starts = {{rail = from.rail, direction = from.direction, is_front = true}},
    goals = {{rail = to.rail, direction = to.direction}}
  }
  return r.found_path
end

-- Check a cell: every entry arm must reach every other arm. Returns the number of missing routes
-- and a readable list. U-turns are not counted: on a lone cell they are impossible, on a
-- connected grid they exist by going around a block.
local function path_test(cx, cy, arms)
  local res, bad = {}, 0
  for _, h in pairs({0, 4, 8, 12}) do
    if has_arm(arms, h + 8) then
      local x, y = P(cx, cy, h, -41, 3)
      local from = T.start(x, y, h)
      for _, h2 in pairs({0, 4, 8, 12}) do
        if h2 ~= (h + 8) % 16 and has_arm(arms, h2) then
          local gx, gy = P(cx, cy, h2, 41, 3)
          local ok = can_route(from, T.start(gx, gy, h2))
          if not ok then bad = bad + 1 end
          res[#res+1] = ARM[(h + 8) % 16] .. '>' .. ARM[h2] .. ':' .. (ok and 'ok' or 'NO ROUTE')
        end
      end
    end
  end
  return bad, table.concat(res, ' ')
end

-- Station spine: a siding that crosses a block from its top track to its bottom track.
-- (bx, by) is the block's top-left rail intersection, x the spine's column inside the block (odd, 31..65).
-- A train leaves the eastbound top track by a right turn, runs south along the spine, stops at the
-- train stop near the bottom and rejoins the westbound bottom track by another right turn.
-- The platform is straight from by+16 to by+80. Returns the train stop.
local SPINE_STOP_Y = 76
local function build_spine(bx, by, x, stop_name)
  local e = T.start(bx + x - 14, by + 3, 4)
  e = T.run(e, 'RRRR')
  e = T.straight_to(e, bx + x, by + 80)
  T.run(e, 'RRRR')
  signal(T.start(bx + x, by + 17, 8), 'rail-signal')
  signal(T.start(bx + x, by + 79, 8), 'rail-chain-signal')
  local pos = {bx + x - 2, by + SPINE_STOP_Y}
  clear(pos, 2)
  local stop = s.find_entities_filtered{name='train-stop', position=pos, radius=0.5}[1]
    or s.create_entity{name='train-stop', position=pos, direction=defines.direction.south, force=f}
  if not stop or not stop.connected_rail then error('train stop did not attach to the spine at ' .. pos[1] .. ',' .. pos[2]) end
  if stop_name then stop.backer_name = stop_name end
  return stop
end

-- Put a 1+4 train on the eastbound top track of a block, fuelled, and send it to `stop_name` forever
-- (wait `seconds` there each time). For testing sidings with a real train.
local function test_train(bx, by, stop_name, seconds)
  local train = nil
  for i = 0, 4 do
    local name = i == 0 and 'locomotive' or 'cargo-wagon'
    local car = s.create_entity{name=name, position={bx + 58 - i * 7, by + 3}, direction=defines.direction.east, force=f}
    if not car then error('could not place ' .. name) end
    if i == 0 then car.insert{name='rocket-fuel', count=10} end
    train = car.train
  end
  train.schedule = {current=1, records={{station=stop_name, wait_conditions={{type='time', ticks=(seconds or 5) * 60, compare_type='and'}}}}}
  train.manual_mode = false
  return train
end
