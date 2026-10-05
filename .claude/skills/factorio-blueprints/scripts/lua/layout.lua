-- ASCII layouts and production tests. Requires common.lua.
-- One character = one tile. A multi-tile entity is written once, at its top-left tile; pad the rest with '.'.
local DIR = {N=defines.direction.north, E=defines.direction.east, S=defines.direction.south, W=defines.direction.west}

local function size_of(name, dir)
  local pr = prototypes.entity[name]
  local w, h = pr.tile_width, pr.tile_height
  if dir == DIR.E or dir == DIR.W then w, h = h, w end
  return w, h
end

-- Place an entity with its top-left tile at (tx, ty). opts: dir, recipe, type (underground/loader), bar.
local function place(name, tx, ty, opts)
  opts = opts or {}
  local dir = opts.dir or DIR.N
  local w, h = size_of(name, dir)
  local e = s.create_entity{name=name, position={tx + w / 2, ty + h / 2}, direction=dir, force=f, recipe=opts.recipe, type=opts.type}
  if not e then error('cannot place ' .. name .. ' at tile ' .. tx .. ',' .. ty) end
  return e
end

-- Default legend. Belts ^ > v <. Inserters by the way items move: u d l r (long-handed: U D L R).
-- An inserter's direction is its pickup side, so "moves down" faces north.
-- Poles: p small, P medium, B big, S substation. o = pipe.
local DEFAULT = {
  ['^'] = {kind='belt', dir=DIR.N}, ['>'] = {kind='belt', dir=DIR.E}, ['v'] = {kind='belt', dir=DIR.S}, ['<'] = {kind='belt', dir=DIR.W},
  u = {kind='inserter', dir=DIR.S}, d = {kind='inserter', dir=DIR.N}, l = {kind='inserter', dir=DIR.E}, r = {kind='inserter', dir=DIR.W},
  U = {kind='long', dir=DIR.S}, D = {kind='long', dir=DIR.N}, L = {kind='long', dir=DIR.E}, R = {kind='long', dir=DIR.W},
  p = {name='small-electric-pole'}, P = {name='medium-electric-pole'}, B = {name='big-electric-pole'}, S = {name='substation'},
  o = {name='pipe'},
}

-- Build rows of text with its top-left tile at (x0, y0). legend overrides DEFAULT per character.
-- kinds: {belt=..., inserter=..., long=...} choose the tier (defaults: yellow belt, inserter, long-handed).
local function build_layout(x0, y0, rows, legend, kinds)
  kinds = kinds or {}
  local names = {belt = kinds.belt or 'transport-belt', inserter = kinds.inserter or 'inserter', long = kinds.long or 'long-handed-inserter'}
  local n = 0
  for j, row in ipairs(rows) do
    for i = 1, #row do
      local c = row:sub(i, i)
      if c ~= ' ' and c ~= '.' then
        local d = (legend and legend[c]) or DEFAULT[c]
        if not d then error('no legend entry for "' .. c .. '" in row ' .. j) end
        place(d.name or names[d.kind], x0 + i - 1, y0 + j - 1, d)
        n = n + 1
      end
    end
  end
  return n
end

-- Test fixtures (keep them outside the capture rectangle).
-- Endless supply: a loader at tile (tx, ty) pushing `item` in direction `dir`, fed by an infinity chest behind it.
local VEC = {[DIR.N]={0, -1}, [DIR.E]={1, 0}, [DIR.S]={0, 1}, [DIR.W]={-1, 0}}
local function source(tx, ty, dir, item)
  local v = VEC[dir]
  local chest = place('infinity-chest', tx - v[1], ty - v[2])
  chest.set_infinity_container_filter(1, {name=item, count=200, mode='at-least'})
  return {chest, place('loader-1x1', tx, ty, {dir=dir, type='output'})}
end
-- Endless drain: a loader at (tx, ty) taking a belt that flows in `dir` into a chest that deletes everything.
local function sink(tx, ty, dir)
  local v = VEC[dir]
  local loader = place('loader-1x1', tx, ty, {dir=dir, type='input'})
  local chest = place('infinity-chest', tx + v[1], ty + v[2])
  chest.remove_unfiltered_items = true
  return {loader, chest}
end
-- Free power at tile (tx, ty) (2x2); it must touch a pole's supply area.
local function power(tx, ty) return place('electric-energy-interface', tx, ty) end

-- Research everything so recipes work, then switch off the bonuses a new game would not have.
local function early_game_force()
  f.research_all_technologies()
  f.inserter_stack_size_bonus = 0
  f.bulk_inserter_capacity_bonus = 0
  f.belt_stack_size_bonus = 0
  f.laboratory_speed_modifier = 0
  f.laboratory_productivity_bonus = 0
  f.mining_drill_productivity_bonus = 0
end

-- Measuring: test_start() remembers the counters, test_report(items, x1, y1, x2, y2) prints rates per second
-- since then and lists machines in the rectangle that are not working.
local function test_start()
  local stats = f.get_item_production_statistics(s)
  local fl = f.get_fluid_production_statistics(s)
  storage.mcp_test0 = {tick = game.tick, items = stats.input_counts, used = stats.output_counts, fluids = fl.input_counts}
end
local function test_report(items, x1, y1, x2, y2)
  local t0 = storage.mcp_test0
  local secs = (game.tick - t0.tick) / 60
  local stats = f.get_item_production_statistics(s)
  local fl = f.get_fluid_production_statistics(s)
  local out = {string.format('%.0fs', secs)}
  for _, name in pairs(items) do
    if name:sub(1, 1) == '-' then
      -- a leading minus measures consumption instead of production
      local n2 = name:sub(2)
      local used = (stats.output_counts[n2] or 0) - (t0.used[n2] or 0)
      out[#out+1] = n2 .. ' used=' .. string.format('%.3f/s', used / secs)
    else
      local made = (stats.input_counts[name] or fl.input_counts[name] or 0) - (t0.items[name] or t0.fluids[name] or 0)
      out[#out+1] = name .. '=' .. string.format('%.3f/s', made / secs)
    end
  end
  local st = {}
  for k, v in pairs(defines.entity_status) do st[v] = k end
  local idle = {}
  for _, e in pairs(s.find_entities_filtered{force=f, area={{x1, y1}, {x2, y2}}}) do
    local t = e.type
    if t == 'assembling-machine' or t == 'furnace' or t == 'lab' or t == 'mining-drill' or t == 'boiler' or t == 'generator' or t == 'inserter' and false then
      local name = st[e.status] or '?'
      if name ~= 'working' then idle[e.name .. ':' .. name] = (idle[e.name .. ':' .. name] or 0) + 1 end
    end
  end
  local il = {}
  for k, v in pairs(idle) do il[#il+1] = k .. ' x' .. v end
  out[#out+1] = 'not_working: ' .. (#il == 0 and 'none' or table.concat(il, ', '))
  local dark = {}
  for _, e in pairs(s.find_entities_filtered{force=f, area={{x1, y1}, {x2, y2}}}) do
    if e.prototype.electric_energy_source_prototype and e.type ~= 'electric-energy-interface' and not e.is_connected_to_electric_network() then
      dark[#dark+1] = e.name .. '@' .. string.format('%.0f,%.0f', e.position.x - x1, e.position.y - y1)
    end
  end
  out[#out+1] = 'unpowered: ' .. (#dark == 0 and 'none' or table.concat(dark, ' '))
  return table.concat(out, ' | ')
end

-- A canvas for layouts computed in code: c:set(col, row, ch), c:run(col, row, n, ch) (n tiles to the right),
-- c:col(col, row, n, ch) (n tiles down); columns and rows are 0-based. c:rows() feeds build_layout.
local function canvas(w, h)
  local g = {}
  for r = 0, h - 1 do g[r] = {} for c = 0, w - 1 do g[r][c] = ' ' end end
  local o = {}
  function o:set(c, r, ch)
    if c < 0 or c >= w or r < 0 or r >= h then error('canvas: ' .. c .. ',' .. r .. ' is outside ' .. w .. 'x' .. h) end
    if g[r][c] ~= ' ' then error('canvas: tile ' .. c .. ',' .. r .. ' already holds "' .. g[r][c] .. '", cannot put "' .. ch .. '"') end
    g[r][c] = ch
  end
  function o:run(c, r, n, ch) for i = 0, n - 1 do self:set(c + i, r, ch) end end
  function o:col(c, r, n, ch) for i = 0, n - 1 do self:set(c, r + i, ch) end end
  -- a w2 x h2 machine: its character at the top-left tile, dots elsewhere
  function o:box(c, r, w2, h2, ch)
    for i = 0, w2 - 1 do for k = 0, h2 - 1 do self:set(c + i, r + k, (i == 0 and k == 0) and ch or '.') end end
  end
  function o:rows()
    local out = {}
    for r = 0, h - 1 do out[#out+1] = table.concat(g[r], '', 0, w - 1) end
    return out
  end
  return o
end
