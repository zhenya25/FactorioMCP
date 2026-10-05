# FactorioMCP

Fork of `sbarisic/FactorioMCP`: a C# (.NET 9) MCP server that drives a running Factorio game through RCON by sending Lua. In this repo it is used mainly as a sandbox tool for designing blueprint books the user imports into a hand-played game.

## User

- Writes in Russian; reply in Russian. Skills and this file stay in English (their request, to save tokens).
- Plays Factorio 2.1 experimental with Space Age by hand and wants achievements.

## Hard constraints

- **Any RCON/Lua command permanently disables achievements in that save**, and the server runs Lua as soon as it connects. Only connect to a save the user calls the sandbox. For the real playthrough deliver blueprints through the clipboard (`give-blueprint-book` skill).
- `dotnet test` without a filter runs live integration tests against the open game. Use `dotnet test FactorioMCP.Tests -c Release --filter "FullyQualifiedName!~Integration"`.
- `buildings.json` and `goals.json` are server runtime state; do not commit changes to them. `.mcp.json` is local (machine paths, RCON password); do not commit it.

## Environment

- Windows 11, Windows PowerShell 5.1, Git Bash. No Python or Node. The repo path contains Cyrillic: keep `.ps1` files ASCII-only and read data files as UTF-8 explicitly.
- `GITHUB_TOKEN` in the environment is invalid; run `unset GITHUB_TOKEN` before `gh` (keyring account `zhenya25` works).
- Remotes: `origin` = upstream, `fork` = `zhenya25/FactorioMCP`; local `master` tracks `fork/master`.

## Game connection

- RCON opens only when the game is hosted via Multiplayer. Settings come from `%APPDATA%\Factorio\config\config.ini` (`local-rcon-socket=127.0.0.1:27015`, `local-rcon-password=mypassword`), not from launch flags.
- The `factorio` MCP tools load only if Claude Code starts while the game is hosted. Otherwise use `.claude/skills/factorio-blueprints/scripts/factorio.ps1` (`call <tool>`, `lua <files>`), which talks to the built server directly.

## Server code

- Build: `dotnet build FactorioMCP -c Release`. `.mcp.json` runs the built DLL, so rebuild after code changes.
- `FactorioMCP/Tools/*.cs` declare the 116 MCP tools; `FactorioMCP/Services/*.cs` hold the Lua as C# raw strings. Unit tests assert on substrings of that Lua, so update them with the Lua.
- All tools were fixed and verified against Factorio 2.1.20 (commit `862e118`). API renames found are listed in `.claude/skills/factorio-blueprints/references/api-notes.md`.

## Blueprint work

- START HERE: `blueprint-books/city-block-96x96/memory.md` has the exact work status, the half-finished wall redesign and the user's open requests.
- Skills: `factorio-blueprints` (design, verify, store), `give-blueprint-book` (deliver a book), and user-level `skill-authoring` (rules for writing skills).
- Books live in `blueprint-books/<architecture>/`; the repository copy is the original. First architecture: `city-block-96x96` (root label `SpaceAge City Block 96x96`); its design rules are in `RULES.md` there.
- The user asked (2026-10-05) to implement the book through stage 9. Done and verified in the sandbox (30 blueprints): book 0 base; book 1 (furnace line, electric mining, steam power); book 2 (red and green science 0.5/s, labs); book 4 (intersection, T, corner, straight, load/unload stations, depot, depot with a configured shared train); book 5 (smelting: iron, copper, brick, steel); book 6 (gears, green circuits); book 7 (red science); book 9 (straight wall, train entrance, corner with a 45-degree flamethrower, supply post).
- Not done yet: book 3 (oil, plastic, sulfur, blue science was moved to blocks); mining outpost with a balanced loading station; fluid stations and tanker trains; more book 6 blocks (red and blue circuits, engines, batteries, LDS, modules); book 7 sciences 2-6 and a lab block; book 8 (solar, nuclear, robot mall); book 9 artillery add-on; upgrade planners for the base book; a mini-mall for book 2.
- Sandbox test sites are tagged on the map; the Lua that built each design is kept in `blueprint-books/city-block-96x96/designs/` (run with the skill harness).
- Commit and push only when asked; pushes go to `fork` `master`.
