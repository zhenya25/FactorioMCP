-- Defence wall cells for the 96x96 grid. Requires common, layout (rails for the train entrance; rails and
-- stations for the supply post).
-- ALIGNMENT: a wall cell is centred on a grid node, like an intersection cell, and the wall stands on the
-- grid line itself (the outermost line, which carries no rails) - in the centre of the cell, not on its edge.
-- So wall cells and T/X intersection cells never overlap, and a rail line leaving the city crosses a wall
-- cell through its centre: that is the train entrance variant.
-- Wall coordinates: a = tiles along the wall, d = depth from the outside. d < 36 is left empty.
--   36,38,40,42,44  maze: loose wall lines with staggered 2-tile gaps, so biters zigzag under fire
--   46-47           main wall
--   49-50 gun turrets, 51 inserters, 52 ammo belt
--   54-55 lasers and substations
--   57-59 flamethrowers, fuel pipe on 59
-- Belt and pipe run edge to edge and flow clockwise around the base (east on a north wall).
-- a = 58..61 is a gated passage for the player. In the entrance variant the tracks run at a = 45 and 51
-- (rail tiles 44,45 and 50,51) with gates in every wall line; belt and pipe go under them.
-- a = 2 (ammo) and a = 4 (fuel) stay free behind the line: the supply post feeds through them.
-- Gates across a north-south passage face east ('H'); across an east-west passage they face north ('G').
local GUNS = {8, 14, 20, 26, 32, 38, 54, 62, 68, 74, 80, 86}
local LASERS = {11, 15, 19, 27, 31, 35, 41, 53, 63, 67, 75, 79, 83, 91}
local SUBS = {7, 23, 39, 55, 71, 87}
local FLAMERS = {8, 16, 24, 32, 40, 54, 64, 72, 80, 88}
local MAZE = {36, 38, 40, 42, 44}
local function maze_gap(a, line)
  local m = a % 10
  if line % 2 == 1 then return m == 3 or m == 4 end
  return m == 8 or m == 9
end

-- One wall leg on canvas c. east=false: the leg faces north (a = column, d = row); east=true: it faces east
-- (a = row, d counted from the east edge). o = {from, to, entrance, gate (default true), pump (a of the pump),
-- skip_flamer}.
local function wall_leg(c, east, o)
  local function tile(a, d) if east then return 95 - d, a end return a, d end
  local function set(a, d, ch) local x, y = tile(a, d) c:set(x, y, ch) end
  local function box(a, d, la, ld, ch)
    if east then c:box(95 - d - ld + 1, a, ld, la, ch) else c:box(a, d, la, ld, ch) end
  end
  local function inside(a, la) return a >= o.from and a + (la or 1) - 1 <= o.to end
  local gate_ch = east and 'G' or 'H'
  local function is_gate(a)
    if o.gate ~= false and a >= 58 and a <= 61 then return true end
    return o.entrance and (a == 44 or a == 45 or a == 50 or a == 51)
  end
  for a = o.from, o.to do
    for i, d in ipairs(MAZE) do
      if is_gate(a) then set(a, d, gate_ch) elseif not maze_gap(a, i) then set(a, d, 'w') end
    end
    set(a, 46, is_gate(a) and gate_ch or 'w') set(a, 47, is_gate(a) and gate_ch or 'w')
  end
  for _, a in pairs(GUNS) do if inside(a, 2) then box(a, 49, 2, 2, 'g') set(a, 51, east and 'r' or 'u') end end
  for _, a in pairs(LASERS) do if inside(a, 2) then box(a, 54, 2, 2, 'z') end end
  for _, a in pairs(SUBS) do if inside(a, 2) then box(a, 54, 2, 2, 'S') end end
  local used = {}
  for _, a in pairs(FLAMERS) do
    if inside(a, 2) and a ~= o.skip_flamer then box(a, 57, 2, 3, east and 'e' or 'f') used[a] = true used[a + 1] = true end
  end
  local pa = o.pump or 36
  if inside(pa, 2) then box(pa, 59, 2, 1, east and 'Q' or 'q') used[pa] = true used[pa + 1] = true end
  -- underground hops: under the player's gate, and under both tracks of a train entrance
  local hops = {}
  if o.gate ~= false then hops[#hops+1] = {57, 62} end
  if o.entrance then hops[#hops+1] = {43, 46} hops[#hops+1] = {49, 52} end
  local under, pin, pout = {}, {}, {}
  for _, h in pairs(hops) do
    pin[h[1]] = true pout[h[2]] = true
    for a = h[1] + 1, h[2] - 1 do under[a] = true end
  end
  for a = o.from, o.to do
    if pin[a] then set(a, 52, east and 'N' or 'n') set(a, 59, east and 'A' or 'a')
    elseif pout[a] then set(a, 52, east and 'M' or 'm') set(a, 59, east and 'C' or 'c')
    elseif not under[a] then
      set(a, 52, east and 'v' or '>')
      if not used[a] then set(a, 59, 'o') end
    end
  end
end

local WALL_LEGEND = {
  w = {name='stone-wall'}, G = {name='gate', dir=DIR.N}, H = {name='gate', dir=DIR.E},
  g = {name='gun-turret'}, z = {name='laser-turret'}, S = {name='substation'}, B = {name='big-electric-pole'}, R = {name='roboport'},
  f = {name='flamethrower-turret', dir=DIR.N}, e = {name='flamethrower-turret', dir=DIR.E},
  q = {name='pump', dir=DIR.E}, Q = {name='pump', dir=DIR.S},
  n = {name='underground-belt', dir=DIR.E, type='input'}, m = {name='underground-belt', dir=DIR.E, type='output'},
  N = {name='underground-belt', dir=DIR.S, type='input'}, M = {name='underground-belt', dir=DIR.S, type='output'},
  a = {name='pipe-to-ground', dir=DIR.W}, c = {name='pipe-to-ground', dir=DIR.E},
  A = {name='pipe-to-ground', dir=DIR.N}, C = {name='pipe-to-ground', dir=DIR.S},
}
local CANVAS_H = 122   -- the power line runs 26 tiles past the cell toward the rail trunk

-- Straight cell, front to the north; (x0, y0) is the cell's top-left corner (node - 48 on both axes).
-- entrance=true adds a double track through the centre with gates in every wall line.
-- Drones and poles use the block-frame slots (roboports at 22 and 70, poles at 26 and 68), so the frame
-- blueprint can be stamped over the half-blocks behind the wall without a clash.
local function build_wall_straight(x0, y0, entrance)
  local c = canvas(96, CANVAS_H)
  wall_leg(c, false, {from=0, to=95, entrance=entrance})
  c:box(22, 70, 4, 4, 'R') c:box(70, 70, 4, 4, 'R') c:box(26, 68, 2, 2, 'B') c:box(68, 68, 2, 2, 'B')
  c:box(47, 66, 2, 2, 'B') c:box(47, 92, 2, 2, 'B') c:box(47, 118, 2, 2, 'B')
  local n = build_layout(x0, y0, c:rows(), WALL_LEGEND)
  if entrance then
    -- northbound track at a = 51, southbound at a = 45; gates may sit on rails
    T.straight_to(T.start(x0 + 51, y0 + 95, 0), x0 + 51, y0)
    T.straight_to(T.start(x0 + 45, y0 + 1, 8), x0 + 45, y0 + 96)
  end
  return n
end

-- Corner cell: outside is north and east; the two wall lines meet in the centre of the cell. Both legs stop
-- short of the corner and are joined by hand: wall lines wrap round, belt and pipe turn and keep flowing
-- clockwise (south), and one flamethrower stands at 45 degrees on the pipe elbow (fuel ports west and south).
local function build_wall_corner(x0, y0)
  local c = canvas(96, CANVAS_H)
  wall_leg(c, false, {from=0, to=35, gate=false})
  wall_leg(c, true, {from=60, to=95, gate=false, pump=68})
  for i, d in ipairs(MAZE) do
    for a = 36, 95 - d do if not maze_gap(a, i) then c:set(a, d, 'w') end end
    for a = d + 1, 59 do if not maze_gap(a, i) then c:set(95 - d, a, 'w') end end
  end
  for _, d in pairs({46, 47}) do
    for a = 36, 95 - d do c:set(a, d, 'w') end
    for a = d + 1, 59 do c:set(95 - d, a, 'w') end
  end
  c:run(36, 52, 7, '>') c:col(43, 52, 8, 'v')            -- belt round the corner
  c:set(36, 59, 'o') c:set(37, 61, 'o')                   -- pipe elbow and the stub to the turret's south port
  c:box(38, 54, 2, 2, 'S')                                -- joins the two legs' substations
  c:box(22, 70, 4, 4, 'R') c:box(26, 68, 2, 2, 'B') c:box(26, 92, 2, 2, 'B') c:box(26, 118, 2, 2, 'B')
  local n = build_layout(x0, y0, c:rows(), WALL_LEGEND)
  if not s.create_entity{name='flamethrower-turret', position={x0 + 37, y0 + 59}, direction=2, force=f} then
    error('the diagonal flamethrower does not fit in the corner')
  end
  return n + 1
end

-- Supply post: an ordinary block in the first full ring behind the wall. (bx, by) is that block; the wall line
-- is the grid line 96 tiles north of its top edge (by - 96), so there is a half-block of free land between.
-- Ammo: unloading station on spine 33, belt up column 50 - under both tracks, across the half-block, under
-- the wall's fuel pipe - into the wall belt from below. Fuel: tanker station on spine 77, tanks, pipe up
-- column 52 the same way. Columns 50 and 52 are a = 2 and a = 4 of the wall cell centred on the node bx + 96.
local function build_supply_post(bx, by, ammo)
  ammo = ammo or 'firearm-magazine'
  build_unload(bx, by, 33, '[item=' .. ammo .. '] Разгрузка', 2000, 'E', 'N')
  local _, px, py = build_fluid_unload(bx, by, 77, '[fluid=crude-oil] Разгрузка', 50000)
  local L3 = {
    n = {name='underground-belt', dir=DIR.N, type='input'}, m = {name='underground-belt', dir=DIR.N, type='output'},
    a = {name='pipe-to-ground', dir=DIR.S}, c = {name='pipe-to-ground', dir=DIR.N},
    h = {name='pipe-to-ground', dir=DIR.E}, k = {name='pipe-to-ground', dir=DIR.W},
    S = {name='substation'}, B = {name='big-electric-pole'},
  }
  local c = canvas(96, 96)
  c:col(37, 21, 20, '^') c:run(37, 20, 13, '>') c:col(50, 6, 15, '^') c:set(50, 5, 'n') c:set(50, 1, 'm') c:set(50, 0, '^')
  c:col(px, 21, py - 20, 'o') c:run(79, 20, px - 78, 'o') c:set(78, 20, 'h') c:set(75, 20, 'k') c:run(52, 20, 23, 'o')
  c:col(52, 6, 14, 'o') c:set(52, 5, 'a')
  c:box(42, 22, 2, 2, 'B') c:box(64, 22, 2, 2, 'B') c:box(84, 30, 2, 2, 'B')
  c:box(41, 36, 2, 2, 'S') c:box(41, 52, 2, 2, 'S')
  build_layout(bx, by, c:rows(), L3)
  -- north of the block: row r of this canvas is depth r + 48 of the wall cell (belt at r = 4, pipe at r = 11)
  local up = canvas(96, 96)
  up:set(50, 95, '^') up:set(50, 94, 'n') up:set(50, 91, 'm') up:col(50, 13, 78, '^')
  up:set(50, 12, 'n') up:set(50, 10, 'm') up:col(50, 5, 5, '^')
  up:set(52, 91, 'c') up:col(52, 12, 79, 'o')
  build_layout(bx, by - 96, up:rows(), L3)
end
