# NEXT — Agent C (paste this)

Read `prompts/STATUS.md` then `prompts/CONTRACT.md`, then this file. `AGENTS.md` is game law.

**cwd** `C:\Users\zepto\worktrees\TheDummy` **branch** `the-dummy`  
Only `git add src/Shared/Config.luau src/Shared/Types.luau`. Do not checkout `master`. Do not invent instance names. Do not retune dummy/gym costs.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## Already done

`copy.buy/upgrade/gymBuy/cantAfford/locked/maxed/needsRep` and `world.promptDistance` / `maxPenDummies`. Keep them.

## This pass (STATUS `needs: B needs copy.level`)

1. `Config.copy.level` = `"Lv"`
2. Optional `world.cardPixelsPerStud` (e.g. 40)
3. Types: `CopyConfig.level`; optional `WorldConfig.cardPixelsPerStud`

If B needs another copy key, add it only if STATUS `needs:` names it.

## Stop when

`copy.level` exists and Types compile. Then STATUS `needs` for that key is cleared (A updates STATUS after your commit).
