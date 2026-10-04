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
