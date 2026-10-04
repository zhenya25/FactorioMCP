---
name: factorio-blueprints
description: Design, verify and store Factorio blueprints in the repository's blueprint books. Use for any request to create, change, test or organise Factorio blueprints, city blocks, rail pieces, stations or a book's structure.
---

# Factorio blueprints

The user plays Factorio 2.1 (Space Age) by hand to keep achievements and imports blueprints designed here.

## Rules

1. **Sandbox only.** Any RCON/Lua command disables achievements in that save for good. Work only in a save the user calls the sandbox; ask if unsure.
2. **The repository is the source of truth.** The copy in the player's inventory is disposable; they may edit or break it. Never keep the only copy of anything in the game.
3. **One folder per base architecture** under `blueprint-books/`. Each folder is one root book. Its `RULES.md` holds that architecture's design rules - read it before designing. A new planning pattern gets a new folder with its own `book.json` and `RULES.md`.
4. **Hierarchy is nested books**, one per stage or category. The root description states the design type and its rules.
5. **Descriptions everywhere.** Every book and blueprint has a label and a short, plain description in Russian saying what it does. Limit 500 bytes (about 250 Cyrillic characters); the game silently truncates longer text.
6. **Game is the source of truth for data.** Read recipes, ratios and prototypes from the running game, not from memory; 2.1 is experimental.
7. **Verified or not done.** Stamp the blueprint off-grid in a clean spot, build it, and test it: rails with the pathfinder, production by running it and checking for idle machines and missing inputs. Say plainly what was not tested.

## Files

```
blueprint-books/<architecture>/
  RULES.md                 design rules of this architecture
  book.json                root label, description, hierarchy (edit by hand)
  blueprints/<NN-stage>/<name>.json   one blueprint as decoded JSON (full text)
  import-string.txt        generated; what the player imports
```

`book.json` node: a book `{"label", "description", "children": [...]}` or a blueprint `{"file": "blueprints/..."}` (optional `label`/`description` override the ones inside the file).

## Workflow

1. Build the design in the sandbox with Lua (libraries below).
2. Verify it (rule 7).
3. Capture: `capture_blueprint(x1, y1, x2, y2, label, description, 'mcp/<name>.json')`.
4. `factorio.ps1 fetch mcp/<name>.json <architecture>/blueprints/<NN-stage>/<name>.json`
5. Add the file to `book.json` under the right book; a new category needs a new book with a description.
6. `factorio.ps1 give <architecture>` - rebuilds the book, validates it by importing it in game, replaces the player's copy. Fix every reported problem.
7. Tell the user what was added, where it sits in the book, and what was and was not verified.

## Tools

Run from the repository root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/factorio-blueprints/scripts/factorio.ps1 <command>
  lua <file.lua>...     run Lua files joined into one chunk; bare names load from scripts/lua
  call <tool> [json]    call any FactorioMCP tool
  fetch <src> <dst>     copy from Factorio script-output into blueprint-books/
  list                  books: folder -> label
  assemble [book]       rebuild and validate a book, refresh import-string.txt
  give [book]           assemble + put the book into the player's inventory
  clipboard [book]      copy import-string.txt to the clipboard; does not touch the game
```

`[book]` is the folder name or the label, in full or in part.

Put task-specific Lua in a scratch file and list libraries before it, e.g. `lua common.lua rails.lua blueprint.lua C:\...\task.lua`. Print results with `rcon.print`. Library names are `local`, so they exist only within the same run.

| Library | Provides |
|---|---|
| `common.lua` | `p`, `s`, `f`, `clear(pos, r)`, `clear_area`, `wipe(x1, y1, x2, y2)`, `player_inventory()` |
| `rails.lua` | `T.start/step/run/straight_to` rail turtle, `signal`, `P` grid geometry, `build_cell`, `add_cell_poles`, `can_route`, `path_test` |
| `blueprint.lua` | `capture_blueprint` (snaps to the absolute 96 grid), `stamp_blueprint(str, x, y)` |

Requires the game hosted through Multiplayer with RCON enabled and the server built (`dotnet build FactorioMCP -c Release`).

Read `references/api-notes.md` before writing new Lua: it lists the Factorio 2.1 API facts and pitfalls already found.
