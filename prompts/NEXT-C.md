# NEXT — Agent C (paste this)

You are Agent C. Read `prompts/README.md` then this file. `AGENTS.md` is source of truth.

**Work in** `C:\Users\zepto\worktrees\TheDummy` **branch** `the-dummy`.  
Only `git add src/Shared/Config.luau src/Shared/Types.luau`. Do not checkout `master`. Do not paste `AGENT_C.md` or `AGENT_C_BOARDS.md` — those waves are done.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## Already done

`copy.buy/upgrade/gymBuy/cantAfford/locked/maxed/needsRep` and `world.promptDistance` / `world.maxPenDummies` exist. Keep them.

## This pass

Do **not** retune dummy/gym costs.

1. `Config.copy.level` = `"Lv"` (B’s NI cards).
2. Optional `world.cardPixelsPerStud` (e.g. 40) if you want B to read it.
3. Types: add `level` on `CopyConfig`; add optional `cardPixelsPerStud` on `WorldConfig`.

## Stop when

`Config.copy.level` and Types compile. B can require them without guessing strings.
