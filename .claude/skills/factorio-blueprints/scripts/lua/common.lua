-- Shared helpers. Load first: every other library uses p, s, f and clear().
local p = game.connected_players[1]
local s = p.surface
local f = p.force

-- Remove nature and fill water so that something can be built at pos (sandbox only).
local function clear(pos, r)
  for _, e in pairs(s.find_entities_filtered{position=pos, radius=r, type={'tree', 'simple-entity', 'cliff', 'fish'}}) do e.destroy() end
  local tiles = {}
  local ok, water = pcall(function() return s.find_tiles_filtered{position=pos, radius=r, collision_mask='water_tile'} end)
  if ok then
    for _, t in pairs(water) do tiles[#tiles+1] = {name='landfill', position=t.position} end
    if #tiles > 0 then s.set_tiles(tiles) end
  end
end

-- Clear a whole rectangle the same way.
local function clear_area(x1, y1, x2, y2)
  for x = x1, x2, 12 do for y = y1, y2, 12 do clear({x, y}, 9) end end
end

-- Destroy everything the player's force built in the area (trains first, so rails can go).
local function wipe(x1, y1, x2, y2)
  local area = {{x1, y1}, {x2, y2}}
  local n = 0
  for _, t in pairs({'locomotive', 'cargo-wagon', 'fluid-wagon', 'artillery-wagon'}) do
    for _, e in pairs(s.find_entities_filtered{type=t, area=area}) do e.destroy() n = n + 1 end
  end
  for _, e in pairs(s.find_entities_filtered{force=f, area=area}) do
    if e.valid and e.type ~= 'character' then e.destroy() n = n + 1 end
  end
  for _, e in pairs(s.find_entities_filtered{type='entity-ghost', area=area}) do
    if e.valid then e.destroy() n = n + 1 end
  end
  return n
end

-- The player's item inventory. In map (remote) view the player has none of their own; the character does.
local function player_inventory()
  return p.get_main_inventory() or (p.character and p.character.get_main_inventory())
end
