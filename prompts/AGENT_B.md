# Agent B — Client UI / juice (Wave 1)

You are Agent B for **The Dummy**, a Roblox incremental. `AGENTS.md` is the source of truth. Read it before writing.

## Git + worktree (do this first)

Do **not** work in `C:\Users\zepto\TheDummy` (main checkout, branch `master`).
Do **not** `git init`. The repo already exists.

| | |
|---|---|
| **Work here** | `C:\Users\zepto\worktrees\TheDummy` |
| **Branch** | `the-dummy` |
| **Main repo** | `C:\Users\zepto\TheDummy` on `master` |
| **Git** | `"C:\Program Files\Git\cmd\git.exe"` (may be missing from PATH) |

```powershell
$env:Path = "C:\Program Files\Git\cmd;" + $env:Path
Set-Location "C:\Users\zepto\worktrees\TheDummy"
git status
git branch --show-current
# must print: the-dummy
```

If you are not on `the-dummy` or not in that folder, stop and fix that before editing.

Wave 1 Client files are **already committed** on this branch (`init.client.luau`, `Hud.luau`, `ShopUI.luau`, `State.luau`, `Format.luau`, `Theme.luau`, `WorldFx.luau`). Inspect them and continue. Do not rewrite from scratch. Do not copy from `C:\Users\zepto\TheDummy` unless `git status` shows those files missing.

### Commit rules

- Only `git add` files under `src/Client/`.
- Never add `src/Server/**`, `src/Shared/Formulas.luau`, `src/Shared/Config.luau`, `src/Shared/Types.luau`.
- Do not commit other agents’ work. Do not amend their commits. Do not force-push. Do not checkout `master` in this worktree (`master` is already used by the main checkout).
- Commit on `the-dummy` with a short message, e.g. `Wave 1 client HUD and dummy/gym shop.`

Launch Grok in this folder: `grok --cwd C:\Users\zepto\worktrees\TheDummy`

---

## Ownership

**Owns:** `src/Client/**`  
**Does not own:** DataStore, Formulas, Config numbers, Server, 3D world

Wave 1 only. Do **not** implement Close Dojo modal, Rep shop, Venues hallway, or extra remotes.

## Already shipped (Agent A) — use, don’t fork

Server remotes under `ReplicatedStorage.Remotes`:

- `BuyDummy(id)` — FireServer
- `BuyDummyUpgrade(id)` — FireServer
- `BuyGymLevel()` — FireServer
- `RequestSync` — FireServer to pull; **OnClientEvent** receives the snapshot

Snapshot fields (Bonk is `{ m, e }`, not a raw number):

```text
bonk, bonkPerSec, lifetimeBonk, peakBonkThisRun,
dummies, dummyUpgrades, gymLevel, venueId,
unlockedVenues, gymRep, lifetimeGymRep, lastTick, persistOk
```

`State.apply` already feeds `Decimal.from` on `bonk` / `bonkPerSec`. Keep that.

Shop prices: **Config via Formulas**. Never hardcode costs. Can’t-afford state is client display only; the server still rejects bad spends.

`Format.luau` already does `1.2K` / `3.4M` / `1.0e12`.

## Wave 1 stop when

HUD shows Bonk and Bonk/sec going up while idle; dummy shop buy fires `BuyDummy` and the dummy count / rate update from the next snapshot; gym shop buy fires `BuyGymLevel` and rate goes up. Client never grants Bonk.

Modern Luau types. `task.wait` only. Inspect existing files before writing. Do not invent services.
