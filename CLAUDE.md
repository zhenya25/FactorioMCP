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

- Skills: `factorio-blueprints` (design, verify, store), `give-blueprint-book` (deliver a book), and user-level `skill-authoring` (rules for writing skills).
- Books live in `blueprint-books/<architecture>/`; the repository copy is the original. First architecture: `city-block-96x96` (root label `SpaceAge City Block 96x96`); its design rules are in `RULES.md` there.
- Done: book structure with 14 stage books, `04-grid/intersection` and `04-grid/block-frame`, both verified in the sandbox.
- Next: train stations inside a block (loading/unloading) and a live-train test of the grid, then fillings stage by stage (books 1-3 first so a new map can start).
- `.claude/` and `blueprint-books/` are untracked; commit only when asked.
