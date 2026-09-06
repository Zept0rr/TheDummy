# NEXT — Agent A / orchestrator (paste this)

You own place/Rojo/Studio (`default.project.json`, `TheDummy.rbxl`, `Workspace.Backyard` shells) and you rewrite `prompts/STATUS.md` + `NEXT-*` when a wave starts.

Read `prompts/STATUS.md` then `prompts/CONTRACT.md`. Work in `C:\Users\zepto\worktrees\TheDummy` on `the-dummy`.

`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`

## This pass

Place restyle for boards-ni is **done**. Do not rebuild the yard again unless STATUS `needs:` says a named path is missing.

1. After B and C commit: `git status`, fast-forward `master` if needed, rebuild `TheDummy.rbxl` only if Rojo sources changed.
2. Play Solo verify from STATUS `verify:`.
3. Update STATUS (`blocked` / `needs` / done).

Do not edit `src/Client/**`, Config numbers, or Server economy unless a named stall from CONTRACT is missing — then add only that instance.

## Stop when

STATUS `verify` is true in Studio, or STATUS lists a concrete `needs:` for B or C.
