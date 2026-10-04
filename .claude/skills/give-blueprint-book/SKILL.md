---
name: give-blueprint-book
description: Give the player a full blueprint book by name, rebuilt from the repository. Use when the user asks to get, restore, reset or re-issue a blueprint book in Factorio, or broke their copy.
---

# Give a blueprint book

Books live in `blueprint-books/<folder>/`; the repository copy is the original, the in-game copy is disposable. Giving always rebuilds the whole book from the files, so a broken or edited copy is replaced by a clean one.

Script (run from the repository root):

```
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/factorio-blueprints/scripts/factorio.ps1 <command> [book]
```

`[book]` is the folder name or the book label, in full or in part. `list` shows what exists.

Pick the command by the save the user is in:

- **Sandbox** (game hosted with RCON): `give <book>`. Rebuilds the book, validates it in the game and puts it in the player's inventory, replacing a copy with the same label.
- **Real playthrough:** `clipboard <book>`. Copies the import string to the Windows clipboard without connecting to the game; the user pastes it into "Import string". Never use `give` here - any RCON command disables achievements in that save.

If it is unclear which save is open, ask. If `clipboard` warns that files changed after the string was built, run `assemble <book>` with the sandbox hosted first.

Report the script's result line to the user; on `ERROR` or a non-zero exit say what failed.
