# Agent B — 3D upgrade boards (this pass)

You are Agent B for **The Dummy**. `AGENTS.md` is source of truth. Read it, then `src/Client/**` and `default.project.json`.

## Git

Work only in `C:\Users\zepto\worktrees\TheDummy` on branch `the-dummy`.
`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`
Do not `git init`. Do not checkout `master`. Only `git add src/Client/**`.

The place now has named anchors (Rojo). Wait for / use:

```
Workspace.Backyard.DummyBoard.Stalls.yellow
Workspace.Backyard.DummyBoard.Stalls.fat
Workspace.Backyard.DummyBoard.Stalls.gold
Workspace.Backyard.DummyBoard.Stalls.crowd
Workspace.Backyard.GymBoard.Stall
Workspace.Backyard.PenDummies
```

If a stall is missing, create a fallback part under Backyard — don’t crash.

## Do

1. `src/Client/Boards.luau`
   - SurfaceGui on each stall (name, owned/max, cost). Not ScreenGui.
   - ProximityPrompt Buy / Upgrade on dummy stalls; one Buy on gym stall.
   - Fire existing remotes only: `BuyDummy(id)`, `BuyDummyUpgrade(id)`, `BuyGymLevel()`.
   - Subscribe to `State`. Prices from Formulas + Config. Can’t-afford / max / locked (crowd `unlockRep`).
   - Copy strings from `Config.copy` when present (`buy`, `upgrade`, `gymBuy`, `cantAfford`, `locked`, `maxed`, `needsRep`).

2. `src/Client/World.luau`
   - Blocky SmoothPlastic dummy stand-ins in `PenDummies`, tint from Config dummy `tint`.
   - Visible count from `State.dummies`, cap with `Config.world.maxPenDummies` (default 12).

3. `src/Client/init.client.luau`
   - Do **not** mount `ShopUI`.
   - Mount World + Boards. Keep Hud + WorldFx.

4. Stop using `ShopUI.luau` (delete if nothing else requires it).

## Don’t

Server, Formulas, Config, Types, `default.project.json`, new remotes, Close Dojo UI, client-granted Bonk.

## Stop when

Play Solo: no right-side shop panel; walk to dummy board, buy yellow → HUD dummy count and Bonk/sec go up and a dummy appears in the pen; crowd locked; gym board buy raises rate.
