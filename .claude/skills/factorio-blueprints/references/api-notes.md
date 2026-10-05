# Factorio 2.1 notes (verified on 2.1.20)

## Connection
- RCON opens only while the game is hosted via Multiplayer. Launch flags are ignored there; settings come from `%APPDATA%\Factorio\config\config.ini` (`local-rcon-socket`, `local-rcon-password`). Edit it only while the game is closed.
- Files written with `helpers.write_file` and screenshots land in `%APPDATA%\Factorio\script-output\`.
- `dotnet test` without a filter runs live integration tests against the open game. Use `--filter "FullyQualifiedName!~Integration"`.

## API renames in 2.1
- `defines.inventory.furnace_source/furnace_result/assembling_machine_input/output` -> `crafter_input` / `crafter_output`.
- `LuaRecipe.category` -> `categories` (array).
- `LuaEntityPrototype.max_health` -> `get_max_health()`.
- Pole neighbours: `pole.get_wire_connector(defines.wire_connector_id.pole_copper, false).connections[i].target.owner`.
- `find_entities_filtered{name=...}` throws on an unknown name; check `prototypes.entity[name]` first.

## Rails
- Straight rails are centred on odd coordinates. A rail end location is even along the travel axis.
- `rail.get_rail_end(dir).get_rail_extensions('rail')` lists valid next pieces (`name`, `position`, `direction`, `goal`). Pick by `goal.direction`; skip `rail-ramp`.
- A 90-degree turn is four pieces (curved-rail-a, b, b, a) and moves 13 tiles on each axis.
- `rail_end.out_signal_location` is where the signal goes for a train leaving through that end (right-hand side); create the signal with its `position` and `direction`.
- `game.train_manager.request_train_path{type='any-goal-accessible', starts={{rail, direction, is_front=true}}, goals={{rail, direction}}}.found_path` checks routing. `total_length` may be nil.

## Grid cell
- Intersection at (cx, cy), multiples of 96. Tracks at 3 tiles right of the centre line per heading.
- Right turn branches at a = -16, left turn at a = -10 (a = tiles along the heading from the centre). Chain signal at a = -18, exit signal at a = +18. The whole intersection is one signal block.
- Big poles in the median at +-14 and +-40 on both axes.
- Turns cut about 13 tiles off each block corner; usable interior is about 86x86.

## Blueprints
- `create_blueprint` also grabs entities that only touch the area border; inset the area by 0.5.
- Captured entity positions are centred on the blueprint. For absolute snapping, shift them so the area's top-left is the origin, then set `blueprint_snap_to_grid`, `blueprint_absolute_snapping`, `blueprint_position_relative_to_grid = {x1 % 96, y1 % 96}`.
- `stack.build_blueprint{position=...}` honours absolute snapping, so it tests the player's "click anywhere" case. `ghost.revive()` builds the ghosts.
- Book JSON: `{"blueprint_book": {"item", "label", "description", "blueprints": [{"index", "blueprint" | "blueprint_book"}], "active_index", "version"}}`. Omit `blueprints` for an empty book. String = `"0" .. helpers.encode_string(json)`.
- Descriptions are cut at 500 bytes.

## Sandbox helpers
- Generate terrain before building far away: `surface.request_to_generate_chunks(pos, radius)` then `force_generate_chunk_requests()`.
- Look at results: `game.take_screenshot{surface, position, resolution, zoom, path, daytime=0, force_render=true}`, then read the PNG.
- Point the user to a place with a chat message containing `[gps=x,y]` and a chart tag.

## Block frame
- Roboport: logistics 50x50, construction 110x110. Big pole: wire 32, supply 4x4. Substation: wire 18, supply 18x18.
- Roboports on a 48 lattice (24/72 from rail centre lines) cover every tile with a 2-tile overlap and form one network; fewer than four per block cannot link blocks (spacing must be <= 50).
- A frame pole at 21/75 is about 22 tiles from the nearest trunk pole and connects by itself when built, provided the neighbouring intersections exist.
- Checks: `surface.find_logistic_network_by_position(pos, force)` per tile for coverage; equal `electric_network_id` for wiring; `is_connected_to_electric_network()` is false until the network has a power source.

## Reading the user's own blueprints
- Quick bar: `p.get_quick_bar_slot(page, slot)` returns `{type='record', record=LuaRecord}` for library blueprints.
- Library: `p.blueprints` is an array of `LuaRecord` (`type`, `label`, `contents` for books). `is_preview=true` records are not loaded and cannot be read; records the player put on the quick bar are loaded.
- `record.export_record()` gives the import string; decode with `helpers.decode_string(string.sub(str, 2))`.
- In map (remote) view `p.get_main_inventory()` is nil; use `p.character.get_main_inventory()` (`player_inventory()` in common.lua).

## Tiles
- `stack.set_blueprint_tiles({{name, position={x, y}}})` builds a tile-only blueprint; position 0,0 is the blueprint origin. `stamp_blueprint` revives tile ghosts too.
- Landfill ghosts appear only on water. Count with `surface.count_tiles_filtered{area, name}`.

## Turrets (read from 2.1.20)
- Range: gun 18, laser 24, flamethrower 30 (min 6, 120-degree arc), artillery 224.
- Flamethrower turrets accept 8 directions; odd 16-way values round down to the nearest of 0, 2, 4, ... 14.
- `create_blueprint` drops train stop names unless `include_station_names=true`; trains need `include_trains=true` (and `include_fuel`). `capture_blueprint` sets all three.

## Machines and fluids (2.1.20)
- `LuaEntity.fluidbox` is gone; read connections from `prototypes.entity[n].fluidbox_prototypes[i].pipe_connections[k].positions[1]` (north-facing offsets).
- Facing north: refinery inputs on the south side at x -1/+1, outputs north at -2/0/+2; chemical plant inputs north at -1/+1, outputs south at -1/+1; assembler fluid input north centre, output south centre.
- An inserter's direction is its pickup side. Basic inserter moves about 0.74 items/s from a belt with no stack bonus; fast about 2.3/s.
- Boilers need burner inserters: electric ones cannot start a dead plant.
- `loader-1x1` + `infinity-chest` make endless sources/sinks; `infinity-pipe` for fluids.
- A belt tile fed from both sides and not from behind takes each feeder onto its own lane.

## Trains
- Station spine: right turn off the eastbound top track at x-13, platform straight from y+16 to y+80, right turn onto the westbound bottom track. Spine columns that clear the frame: 33, 47, 61, 77. Stop at y+76 (west side); wagons of a 1+4 train sit on rows 43-48, 50-55, 57-62, 64-69.
- Train stop control: `cb.circuit_enable_disable`, `cb.circuit_condition`; `stop.trains_limit`. Wires: `a.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(b_connector, false, defines.wire_origin.player)`.
- Interrupts: `train.get_schedule().add_interrupt{name, conditions, targets, inside_interrupt}`; wildcard is `[virtual-signal=signal-item-parameter]` in the station name with `{type='item_count', condition={first_signal={type='virtual', name='signal-item-parameter'}, ...}}`; `specific_destination_not_full` takes `station`. `train.group` sets the group (an existing group's schedule wins).
- Verified: two shared trains served iron and copper between four stops for 36 game minutes without mixing cargo; a train stamped from `depot-with-train` joins the group and works (fuel arrives only by robots).
- A one-record schedule never leaves its stop; add a second record to test departures.
- The user keeps reference blueprints (others' designs, old game version, 100-grid) in their second quick bar row; `p.get_quick_bar_slot(p.get_active_quick_bar_page(2), i).record.export_record()` reads them. Use them for ideas only and adapt to this architecture. Last export: `script-output/mcp/ref_slot1..5.json`, index in `ref_index.txt`.
- Second idea source the user named: Nilaus' wiki, https://nilaus.atlassian.net/wiki/spaces/PM/pages/2506129413/Factorio+S51+-+Base-In-A-Book (that page is 2021 / 1.1, strings are linked on factoriobin.com; the same space has Space Age 2.0 pages). Ideas only, adapt to this architecture.
- Test blocks through their stations (`stock_station`): feeding belts directly hid a half-belt unloader for a whole round of blueprints.
