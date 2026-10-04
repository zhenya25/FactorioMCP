-- Blueprint capture and stamping. Requires common.lua.
storage.mcp_inv = storage.mcp_inv or game.create_inventory(10)
local GRID = 96

-- Capture the rectangle (x1, y1)-(x2, y2) as a blueprint snapped to the absolute 96x96 grid.
-- (x1, y1) becomes the blueprint origin, so wherever the player clicks, the blueprint lands at the
-- same offset inside a grid cell as it had here. Label and description are mandatory by the book rules.
-- If `file` is given, the blueprint is also written to script-output/<file> as readable JSON.
local function capture_blueprint(x1, y1, x2, y2, label, description, file)
  if not label or label == '' then error('blueprint needs a label') end
  if not description or description == '' then error('blueprint needs a description') end
  local st = storage.mcp_inv[1]
  st.set_stack{name='blueprint'}
  -- Inset by half a tile: the game also grabs entities that merely touch the border (the neighbour cell rails).
  local area = {{x1 + 0.5, y1 + 0.5}, {x2 - 0.5, y2 - 0.5}}
  st.create_blueprint{surface=s, force=f, area=area, always_include_tiles=false}
  local ents = st.get_blueprint_entities() or {}
  if #ents == 0 then error('nothing captured in the area') end

  -- Blueprint coordinates come back centred; shift them so that (x1, y1) is the origin.
  local bx1, by1, bx2, by2 = math.huge, math.huge, -math.huge, -math.huge
  for _, e in pairs(ents) do
    bx1 = math.min(bx1, e.position.x) by1 = math.min(by1, e.position.y)
    bx2 = math.max(bx2, e.position.x) by2 = math.max(by2, e.position.y)
  end
  local wx1, wy1, wx2, wy2 = math.huge, math.huge, -math.huge, -math.huge
  for _, e in pairs(s.find_entities_filtered{force=f, area=area}) do
    local q = e.position
    if e.type ~= 'character' and q.x >= x1 and q.x <= x2 and q.y >= y1 and q.y <= y2 then
      wx1 = math.min(wx1, q.x) wy1 = math.min(wy1, q.y)
      wx2 = math.max(wx2, q.x) wy2 = math.max(wy2, q.y)
    end
  end
  if math.abs((bx2 - bx1) - (wx2 - wx1)) > 0.01 or math.abs((by2 - by1) - (wy2 - wy1)) > 0.01 then
    error('captured entities do not match the world entities in the area; check what sits on the border')
  end
  local ox, oy = wx1 - bx1 - x1, wy1 - by1 - y1
  for _, e in pairs(ents) do e.position = {x = e.position.x + ox, y = e.position.y + oy} end
  st.set_blueprint_entities(ents)

  st.blueprint_snap_to_grid = {x = GRID, y = GRID}
  st.blueprint_absolute_snapping = true
  st.blueprint_position_relative_to_grid = {x = x1 % GRID, y = y1 % GRID}
  st.label = label
  st.blueprint_description = description
  local str = st.export_stack()
  if file then helpers.write_file(file, helpers.decode_string(string.sub(str, 2)), false) end
  return str, #ents
end

-- Stamp a blueprint string near (x, y) the way a player would, then turn the ghosts into real entities.
-- Returns ghost count, entities left as ghosts, and the bounding box of what was placed.
local function stamp_blueprint(str, x, y)
  local st = storage.mcp_inv[2]
  st.clear()
  if st.import_stack(str) > 0 then error('blueprint string failed to import') end
  local ghosts = st.build_blueprint{surface=s, force=f, position={x, y}, build_mode=defines.build_mode.forced}
  local bx1, by1, bx2, by2 = math.huge, math.huge, -math.huge, -math.huge
  for _, g in pairs(ghosts) do
    bx1 = math.min(bx1, g.position.x) by1 = math.min(by1, g.position.y)
    bx2 = math.max(bx2, g.position.x) by2 = math.max(by2, g.position.y)
  end
  local n = #ghosts
  for _ = 1, 3 do
    for _, g in pairs(ghosts) do if g.valid then g.revive() end end
  end
  local left = 0
  for _, g in pairs(ghosts) do if g.valid then left = left + 1 end end
  return n, left, {bx1, by1, bx2, by2}
end
