# NEXT — Agent B (paste this)

You are Agent B. Read `prompts/README.md` then this file. `AGENTS.md` is source of truth.

**Work in** `C:\Users\zepto\worktrees\TheDummy` **branch** `the-dummy`.  
Only `git add src/Client/**`. Do not checkout `master`. Do not paste `AGENT_B.md` or `AGENT_B_BOARDS.md` — those waves are done.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## Already done

`Boards.luau` / `World.luau` exist (ProximityPrompt + labels). `ShopUI` is gone. HUD stays.

## This pass — look like Noob Incremental boards (not plywood tiles)

Do **not** copy NI names (Oof, Noobs, Runes). Copy the **card language**:

- Each stall SurfaceGui is a **card**: title, owned/`Lv`, effect line, **green TextButton Buy**, **gold TextButton Upgrade**, yellow cost.
- `SurfaceGui.Active = true`. Clicking the button fires remotes. ProximityPrompt is optional extra, not the main control.
- Can’t-afford = grey button + `Config.copy.cantAfford`. Locked crowd = `needsRep`. Max = `maxed`.
- Remotes only: `BuyDummy(id)`, `BuyDummyUpgrade(id)`, `BuyGymLevel()`.
- Copy from `Config.copy` (`buy`, `upgrade`, `gymBuy`, `level` if present).
- `World.luau`: **blocky R6 dummy** (head + torso + 4 limbs), Config `tint`, cap `Config.world.maxPenDummies`. Parent display dummy to `stall.Stand` when that part exists.

Instance names: see `prompts/README.md`. Face Right on dummy stalls, Left on gym.

## Stop when

Play Solo: grass yard; green Buy on the 3D cards; click yellow Buy → dummy count + Bonk/sec up and a dummy in the pen; crowd locked; gym card raises rate; no ScreenGui shop.
