-- helpers for build scripts: a clean work site and the job queue
local function site(X, Y, w, h)
  wipe(X - 14, Y - 14, X + w + 14, Y + h + 14)
  clear_area(X - 14, Y - 14, X + w + 14, Y + h + 14)
end
local function job(t) storage.mcp_jobs = storage.mcp_jobs or {} table.insert(storage.mcp_jobs, t) end
local function two_lane_feed(tx, ty, top_item, bottom_item)
  -- belt tile (tx, ty) heading east receives top_item on its north lane and bottom_item on its south lane
  place('transport-belt', tx, ty, {dir=DIR.E})
  place('transport-belt', tx, ty - 1, {dir=DIR.S}) source(tx, ty - 2, DIR.S, top_item)
  place('transport-belt', tx, ty + 1, {dir=DIR.N}) source(tx, ty + 2, DIR.N, bottom_item)
end
storage.mcp_jobs = storage.mcp_jobs or {}
-- fixtures inside a capture area: remember them so finish.lua removes them before capturing
local FIX = {}
local function fx(list) if list.valid then FIX[#FIX+1] = list else for _, e in pairs(list) do FIX[#FIX+1] = e end end end
-- keep a test site visible on the player's map: a radar with its own power, placed at tile (tx, ty)
local function watch(tx, ty)
  if s.find_entities_filtered{name='radar', position={tx + 1.5, ty + 1.5}, radius=2}[1] then return end
  clear({tx + 2, ty + 2}, 5)
  s.create_entity{name='radar', position={tx + 1.5, ty + 1.5}, force=f}
  s.create_entity{name='medium-electric-pole', position={tx + 3.5, ty + 0.5}, force=f}
  s.create_entity{name='electric-energy-interface', position={tx + 5, ty + 1}, force=f}
end
-- stamp a captured block blueprint into a block of the live grid and check it fits and works there:
-- nothing left as a ghost, every electric machine on the trunk network, every train stop reachable
local function fit_check(key, bx, by)
  local str = storage.mcp_strs[key]
  local g, left = stamp_blueprint(str, bx + 40, by + 55)
  local trunk = s.find_entities_filtered{name='big-electric-pole', position={bx, by + 14}, radius=1.5}[1]
  local off, total = 0, 0
  for _, e in pairs(s.find_entities_filtered{force=f, area={{bx + 5, by + 5}, {bx + 91, by + 91}}}) do
    if e.prototype.electric_energy_source_prototype and e.type ~= 'electric-energy-interface' then
      total = total + 1
      if e.electric_network_id ~= trunk.electric_network_id then off = off + 1 end
    end
  end
  local from = T.start(bx + 11, by + 3, 4)
  local stops, bad = 0, 0
  for _, st in pairs(s.find_entities_filtered{name='train-stop', area={{bx, by}, {bx + 96, by + 96}}}) do
    stops = stops + 1
    local r = game.train_manager.request_train_path{type='any-goal-accessible', starts={{rail=from.rail, direction=from.direction, is_front=true}}, goals={st}}
    if not r.found_path then bad = bad + 1 end
  end
  return key .. ' in grid: ghosts=' .. g .. ' blocked=' .. left .. ' electric=' .. total .. ' off_trunk=' .. off .. ' stops=' .. stops .. ' unreachable=' .. bad
end
