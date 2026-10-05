-- Block fillings for the 96x96 city block. Requires common, rails, layout, stations.
-- Spines: 33 = input A, 61 = output (loading gear on its east side), 77 = optional input B.
-- A leaves its station southward at (37, 72) and B northward at (81, 40); both reach row 78 and enter the
-- production from the south, A from the west and B from the east. Products flow north, cross to the east on
-- row 37 and drop into the loading balancer at (66, 38).
local function stack_of(item) return prototypes.item[item].stack_size end
local function unload_name(item) return '[item=' .. item .. '] Разгрузка' end

-- Stations plus the belts between them and the production. a_col / b_col are the columns where A and B
-- arrive on row 78; out_col is the column that carries the product up to row 37.
local function block_io(c, bx, by, o, a_col, b_col, out_col)
  build_unload(bx, by, 33, unload_name(o.a), 320 * stack_of(o.a), 'E', 'S')
  c:col(37, 72, 6, 'v') c:run(37, 78, a_col - 37, '>')
  if o.b then
    build_unload(bx, by, 77, unload_name(o.b), 320 * stack_of(o.b), 'E', 'N')
    c:run(81, 40, 3, '>') c:col(84, 40, 38, 'v')
    c:run(79, 78, 6, '<') c:set(78, 78, 'x') c:set(75, 78, 'y')      -- under spine 77
    c:run(63, 78, 12, '<') c:set(62, 78, 'x') c:set(59, 78, 'y')     -- under spine 61
    c:run(b_col + 1, 78, 58 - b_col, '<')
  end
  build_load(bx, by, 61, 'Погрузка', 160 * stack_of(o.out), 'E')
  c:run(out_col, 37, 59 - out_col, '>') c:set(59, 37, 'X') c:set(62, 37, 'Y') c:run(63, 37, 3, '>')
  c:col(66, 37, 2, 'v')
  c:box(40, 79, 2, 2, 'B')
end
local IO_LEGEND = {
  x = {name='underground-belt', dir=DIR.W, type='input'}, y = {name='underground-belt', dir=DIR.W, type='output'},
  X = {name='underground-belt', dir=DIR.E, type='input'}, Y = {name='underground-belt', dir=DIR.E, type='output'},
  S = {name='substation'}, B = {name='big-electric-pole'},
}
local function legend_with(extra)
  local t = {}
  for k, v in pairs(IO_LEGEND) do t[k] = v end
  for k, v in pairs(extra) do t[k] = v end
  return t
end

-- One recipe, machines in two columns around a shared input belt (A on its west lane, B on its east lane).
--   o = {machine, recipe (nil for furnaces), n (machines per column, up to 12), a, b (optional), out}
local function build_simple_block(bx, by, o)
  local c = canvas(96, 96)
  block_io(c, bx, by, o, 47, 47, 41)
  c:col(47, 41, 38, '^')
  for k = 0, o.n - 1 do
    local r = 41 + 3 * k
    c:box(43, r, 3, 3, 'M') c:box(49, r, 3, 3, 'M')
    c:set(46, r + 1, 'l') c:set(48, r + 1, 'r') c:set(42, r + 1, 'l') c:set(52, r + 1, 'r')
  end
  c:col(41, 38, 40, '^') c:col(53, 38, 40, '^')
  -- row 37 carries the west column's product east; the east column's belt side-loads into it at column 53
  for _, r in pairs({42, 58, 70}) do c:box(38, r, 2, 2, 'S') c:box(54, r, 2, 2, 'S') end
  build_layout(bx, by, c:rows(), legend_with{M={name=o.machine, recipe=o.recipe}}, {inserter='fast-inserter'})
end

-- Two recipes side by side: an intermediate made from B and handed straight to the final machine, which also
-- takes A from its own belt. Example: copper cable -> electronic circuit (A iron plate, B copper plate).
--   o = {machine, final, mid, n (pairs, up to 12), a, b, out}
local function build_pair_block(bx, by, o)
  local c = canvas(96, 96)
  block_io(c, bx, by, o, 41, 51, 40)
  c:col(41, 41, 38, '^') c:col(51, 41, 38, '^')
  for k = 0, o.n - 1 do
    local r = 41 + 3 * k
    c:box(43, r, 3, 3, 'F') c:box(47, r, 3, 3, 'I')
    c:set(42, r, 'r') c:set(42, r + 1, 'L') c:set(46, r + 1, 'l') c:set(50, r + 1, 'l')
  end
  c:col(40, 38, 40, '^')
  for _, r in pairs({42, 58, 70}) do c:box(38, r, 2, 2, 'S') c:box(53, r, 2, 2, 'S') end
  build_layout(bx, by, c:rows(), legend_with{F={name=o.machine, recipe=o.final}, I={name=o.machine, recipe=o.mid}}, {inserter='fast-inserter', long='long-handed-inserter'})
end

-- Test helper: put `stacks` stacks of an item into every unloading chest of the spine at column x,
-- so a test draws its inputs through the real station inserters.
local function stock_station(bx, by, x, item, stacks)
  local n = 0
  for _, ch in pairs(s.find_entities_filtered{name='steel-chest', area={{bx + x - 4, by + 42}, {bx + x + 4, by + 70}}}) do
    ch.insert{name=item, count=stacks * stack_of(item)}
    n = n + 1
  end
  return n
end
