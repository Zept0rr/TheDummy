# NEXT — Agent B (paste this)

Read `prompts/STATUS.md` then `prompts/CONTRACT.md`. cwd worktree `the-dummy`. Only `src/Client/**`.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## Phase 1 polish

Play Solo (Edit will look blank).

- Cards readable from the path: title, `copy.level`, green **Buy**, gold **Upgrade**, cost. `SurfaceGui.Active = true`. Fix Face if the camera on the path sees the back of the board.
- `DummyBoard.Title` / `GymBoard.Title`: SurfaceGui with `copy.tabDummies` / `copy.tabGym`.
- `World.luau`: blocky R6 in `PenDummies` and on each `Stand`. Cap `world.maxPenDummies`.
- No ScreenGui shop. HUD stays.

If a copy key or path is missing, STATUS `needs:` — do not invent.

## Stop when

STATUS verify: read Buy from the path, dummy appears in the pen, titles on the boards.
