# Agent C — Content / balance + Types (Wave 1)

You are Agent C for **The Dummy**, a Roblox incremental. `AGENTS.md` is the source of truth. Read it before writing.

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

Agent B may be committing `src/Client/**` on the same branch. Pull/status before you commit. Touch only your files so you do not clobber them.

### Commit rules

- Only `git add` `src/Shared/Config.luau` and `src/Shared/Types.luau`.
- Never add `src/Server/**`, `src/Shared/Formulas.luau`, or `src/Client/**`.
- Do not amend other agents’ commits. Do not force-push. Do not checkout `master` in this worktree (`master` is already used by the main checkout).
- Commit on `the-dummy` with a short message, e.g. `Wave 1 Config and Types for Backyard incrementer.`

Launch Grok in this folder: `grok --cwd C:\Users\zepto\worktrees\TheDummy`

---

## Ownership

**Owns:** `src/Shared/Config.luau`, `src/Shared/Types.luau`  
**Also:** after A/B ship, review that spends are server-validated (read-only review this wave — do not edit Server)

**Does not own:** Server, Formulas math, Client UI, 3D world

Wave 1 only. Do **not** wire CloseDojo, implement Rep shop purchases, or make venues 2–10 enterable. You **may** put prestige `k`, 3 Rep node **definitions**, and venue doors 2–10 in Config as data (locked). Agent A/B will use those in Wave 2.

## Already shipped (Agent A) — match this Config shape

`src/Shared/Formulas.luau` already reads Config. **Do not edit Formulas.** Use these keys (camelCase). Aliases exist, but write the names below so A and B keep working.

```text
tickInterval              -- 1
offlineCapSeconds         -- you pick; must be > 0 so rejoin grants capped offline

start.bonk
start.gymLevel            -- 1
start.venueId             -- "backyard"
start.dummies             -- { yellow = 1 } so idle produces Bonk immediately

dummies.yellow / fat / gold / crowd:
  name, baseCost, costGrowth, basePower, hitInterval, stayTime,
  maxCount, startingCount, unlockRep,
  upgradeBaseCost, upgradeCostGrowth, powerPerUpgrade,
  stayTimePerUpgrade, maxUpgradeLevel

gym.maxLevel              -- 10
gym.baseCost, gym.costGrowth
  -- or gym.costs = { [2]=..., [3]=... } for the cost to BUY that level

venues.backyard.venueMult -- 1
venues.<id> for doors 2–10 with unlockRep and venueMult (locked this wave)

prestige.k                -- Wave 2 formula: floor(sqrt(peakBonk / k))
```

Dummy ids (fixed): `yellow`, `fat`, `gold`, `crowd`.  
`crowd.unlockRep` must be **> 0** so Wave 1 cannot buy it (Rep shop is Wave 2).

`Types.luau`: profile + dummy/gym/venue types. Align with the profile schema in `AGENTS.md` and with `PlayerData.Profile` / `Formulas.DummyDef`. Bonk is **not** a raw `number`; Agent A uses `{ m, e }` Decimal.

All numbers live in Config. Nobody else should hardcode costs. You own the first-draft values.

## Wave 1 stop when

A friend can idle ~2 minutes and feel numbers go up: starting yellow dummy produces Bonk, dummy costs are buyable from that income, gym levels 1–10 have costs, Backyard `venueMult = 1`, offline cap is set. Doors 2–10 exist in the venue table and stay locked.

Modern Luau types. Inspect `Formulas.luau` and `src/Server/PlayerData.luau` before writing. Do not invent services.
