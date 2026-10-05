# Work status - SpaceAge City Block 96x96

Written 2026-10-05 at the end of a long session, for the next one. Read `RULES.md` (design rules) and the
`factorio-blueprints` skill first. The user asked to implement the book through stage 9; this is where it stands.

## State of the book

`book.json` lists 30 blueprints; `import-string.txt` was last built with those. All were built and measured in
the sandbox. Committed and pushed to `fork` `master` at the end of the session.

| Book | Done | Still to do |
|---|---|---|
| 0 base | landfill, block frame, 3 paving variants | upgrade / deconstruction planners (the user has examples in their library) |
| 1 start | furnace line x12 (3.74/s), electric mining 2x5 (5/s), steam power 7.2 MW | - |
| 2 red/green | red science 0.5/s, green science 0.5/s, labs x8 | mini-mall |
| 3 oil | nothing | basic + advanced oil, plastic, sulfur. Blue science was moved to blocks (book 7) |
| 4 rails | intersection, T, corner, straight, station-load, station-unload, depot, depot-with-train | fluid load station, tanker train blueprint, mining outpost loading station |
| 5 raw | smelting: iron, copper, brick, steel (15 plates/s) | mining outpost |
| 6 intermediate | gears (7.5/s), green circuits (7.5/s) | red and blue circuits, engines, batteries, plastic/sulfur block, LDS, modules |
| 7 science | red science block (1.8/s) | sciences 2-6, lab block |
| 8 power, robots | nothing | solar, nuclear, robot mall |
| 9 defence | straight wall, train entrance, corner, supply post (see "Walls") | artillery add-on, attack test of the final version |

## Walls - version 3 is in the book

The user rejected two earlier versions (edge-aligned; no maze; no train gates). Version 3 follows their
reference `City Block/Defense`: the wall cell is centred on a grid node like an intersection cell and the wall
stands on the grid line in the centre of the cell (depth 46-47), maze at depth 36-44, turrets behind.
In the book: `wall-straight`, `wall-entrance` (double track through the centre, gates on the rails),
`wall-corner` (one flamethrower at 45 degrees), `wall-supply-post` (block in the first full ring behind the
wall; ammo up column 50, fuel up column 52).

Checked in the live grid with `designs/09-wall-set-live-test.lua` + `09-wall-check.lua`: all turrets of the
straight, entrance and corner cells armed and powered, entrance and corner supplied only through the post,
train routes out and back in through the entrance found. Captured on clean land by `09-wall-capture.lua`.
Not done: attack test of version 3 (version 2, same turret rows, killed 60 of 60 with no losses); stamping the
captured wall blueprints off-grid (they are taller than one cell: the power line runs 26 tiles past it);
the artillery add-on; a tanker train to feed the post (only a script-filled tanker was used).

## Requests from the user not yet carried out

- Record mistakes: in the descriptions of sub-books and blueprints, add a short note of what went wrong
  before, so later edits do not repeat it; and make that a rule in the skill. Plan: a `lesson` field per node
  in `book.json`, appended to the description by `assemble_book.lua` (keep the 500-byte limit). Lessons so far:
  unloading filled only one belt lane (inserters drop on the far lane) - unload both wagon sides and merge;
  loading without a splitter filled the first wagon only; boilers need burner inserters; a small pole covers
  only 5x5; blocks must be tested through their stations, not by feeding belts; walls: need a maze, gates for
  trains, and must be centred on the grid line.
- Supply post: ammo stop opens below 2000 magazines so a train comes rarely and refills for several waves;
  every wall cell has a pump on the fuel pipe (already in the code).

## Verified facts worth keeping (details in the skill's `references/api-notes.md`)

- Shared trains with wildcard interrupts work: `Погрузка` / `[item=X] Разгрузка` / `Депо`, group `Грузовые`.
- Tanker pumps connect only on the east side of a spine, rows 44/46/49 per wagon (centre row and -2/+3).
- Flamethrowers accept diagonal directions (2, 6, 10, 14); fuel ports of a NE one face west and south.
- Tanker trains need their own group and interrupts with `signal-fluid-parameter` - not built or tested yet.

## Sandbox

Game hosted through Multiplayer, RCON 127.0.0.1:27015. Test sites carry map tags. The grid lives around
x 144..432, y -144..144; trunk power is an energy interface in the rail median at (208, -96) - block resets
must not delete it. Enemy expansion is off and nests were removed around the sites. `game.speed` may be left
above 1 after tests; set it back to 1 when handing the game to the user.

## Idea sources the user named

Their reference books (second quick bar row; export with `designs/ref-export-user-quickbar.lua`) and Nilaus'
wiki. Ideas only - older game version, 100-grid, rails through cell centres.
