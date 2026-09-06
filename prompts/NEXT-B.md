# NEXT — Agent B (paste this)

Read `prompts/STATUS.md` then `prompts/CONTRACT.md`, then this file. `AGENTS.md` is game law.

**cwd** `C:\Users\zepto\worktrees\TheDummy` **branch** `the-dummy`  
Only `git add src/Client/**`. Do not checkout `master`. Do not invent Config keys or instance names — if missing, set STATUS `needs:` and stop that part.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## Already done

`Boards.luau` / `World.luau` (ProximityPrompt + labels). `ShopUI` gone. HUD stays.

## This pass — Noob Incremental **cards** (not plywood tiles)

Do not copy NI names (Oof, Noobs, Runes).

- SurfaceGui **card**: title, owned/`copy.level`, effect, **green TextButton Buy**, **gold TextButton Upgrade**, yellow cost.
- `SurfaceGui.Active = true`. Buttons fire CONTRACT remotes. ProximityPrompt optional extra.
- Can’t-afford / locked / max from `copy.cantAfford` `needsRep` `maxed`.
- `World.luau`: blocky R6 dummy (head + torso + limbs), `dummies[id].tint`, cap `world.maxPenDummies`. Parent to `stall.Stand` when present.
- Paths and faces: CONTRACT.md only.

## Stop when

STATUS `verify` line: green Buy on cards; yellow Buy → count + Bonk/sec + dummy in pen; crowd locked; gym raises rate; no ScreenGui shop.
