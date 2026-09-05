# The Dummy — Grok Build Plan

Roblox incremental. Same pacing as *Noob Incremental* (buy units → currency/sec → shop → reset for a kept currency → next layer). Different fantasy: you are the punching bag.

Players do **not** fight. Fighters exist in the background. Hits generate **Bonk**. Spend Bonk on dummies and on the current gym. When the run stalls, **Close the Dojo**, keep **Gym Rep**, start over faster. Lifetime Gym Rep unlocks the next **venue** (Backyard → Raid Pit). Same hit rule in every venue.

This file is the source of truth for Grok Build agents. Do not invent systems that are not listed here.

---

## One-line pitch

Get hit. Get paid. Buy more of you. Reset the gym when the punches feel small.

---

## Core loop (do not change)

```text
Hits (always the same formula) → Bonk
  → dummy upgrades
  → gym levels 1–10 inside THIS venue
  → Close Dojo → keep Gym Rep, wipe run
  → when lifetime Rep is enough, next venue door opens
  → new run in the new room, same hits, bigger venueMult
```

### The only combat rule

Every venue uses this. Never replace it. Never add a second hit minigame.

```text
Bonk per hit = dummyPower × gymLevel × venueMult × combo
Combo = consecutive hits on the same dummy before it "breaks"
```

- Background fighters hit on a timer (idle works).
- A click can add one extra hit. Optional, not required to progress.
- Hits only ever grant **Bonk**. No second currency on the popup.

### Two shops, do not mix them

| Shop | Costs | Lasts | Does |
|---|---|---|---|
| Dummy upgrades | Bonk, this run | Wiped on Close Dojo | More output from *your* side: count, power, stay-time, types |
| Gym levels 1–10 | Bonk, this run | Wiped on Close Dojo | Stronger fighters in *this* venue |
| Venue door | Lifetime Gym Rep | Permanent | New room + `venueMult` + skins. Not a new combat system |

Dummy shop = how good is the bag.  
Gym shop = how hard do people hit here.  
Venue = which building you own the key to.

---

## Currencies

| Name | Type | Wiped on Close Dojo? |
|---|---|---|
| **Bonk** | Run currency | Yes |
| **Gym Rep** | Prestige / meta | No. Lifetime total also stored |
| Tickets / Stickers | Later. Do not implement in Wave 1–2 | — |

Use a BigNum / Decimal module for Bonk and derived rates. Do not use raw Luau `number` past mid-game.

---

## Close the Dojo (prestige)

Show the button when the next meaningful buy costs roughly 2–3 minutes of full income.

**Lose:** Bonk, dummy upgrades, dummy count (back to starting dummies for that venue), gym level.

**Keep:** Gym Rep (this-reset grant + lifetime), unlocked venues, cosmetics (later), gamepass flags.

**Grant on close:** Gym Rep from a single tunable formula in `Shared/Formulas.luau` (example shape: `floor(sqrt(peakBonkThisRun / k))`, exact constants live in Config).

Gym Rep buys *permanent* nodes between runs, for example:

- Start with +1 dummy
- All Bonk +25%
- Gym levels cheaper
- Unlock a dummy type earlier
- Offline cap +30m

Entering a new venue is a **promotion**, not another reset button. Do not spend Rep on every Close. Gate venues by **lifetime Rep required**. Optional later: one-time “sign the lease” sink. Default: requirement only, no tax.

After a venue is unlocked, a new run may **start in that venue**. Do not force the full Backyard climb every time.

---

## Venues 1–10 (launch board)

Same hit formula. Different room, multiplier, dummy skins, fighter crowd look.

| # | Venue | Lifetime Rep to unlock | venueMult | Allowed extra |
|---|---|---|---|---|
| 1 | Backyard | 0 | 1 | Teach the loop |
| 2 | Garage | 10 | 2 | — |
| 3 | School gym | 25 | 3 | More dummy slots in the room |
| 4 | Local dojo | 50 | 5 | First “serious” dummy skin |
| 5 | Strip-mall MMA | 100 | 8 | — |
| 6 | Tournament lobby | 200 | 12 | Busier crowd visual only |
| 7 | Pro practice | 400 | 18 | — |
| 8 | Hill training | 800 | 25 | Better offline cap (economy, not combat) |
| 9 | Esports stage | 1600 | 40 | — |
| 10 | Raid pit | 3200 | 60 | More dummies on screen, same tick |

Rep numbers and mults are placeholders in Config. Tune after Wave 1 is playable. Keep a roughly doubling Rep curve.

**Ship Wave 1–2 in Backyard only.** Show locked doors 2–10 in UI so the mountain is visible. Do not implement Garage+ logic until Backyard Close Dojo feels good.

**Forbidden per venue:** new hit patterns, dodgeball, splash damage, raid rotations, lag gimmicks, dummy hitting back. If a venue needs a tutorial for how punching works, it is too complicated.

**Later (not this file’s waves):** venues 11–19 as more doors, same formula.

---

## v1 content slice (definition of “the game exists”)

1. 4 dummy types
2. Dummy upgrades + gym levels 1–10 in Backyard
3. Offline progress (capped)
4. Close Dojo → Gym Rep → 3 permanent Rep shop nodes
5. Venues tab with doors 1–10 visible, only Backyard enterable
6. A pen of dummy meshes whose count scales with owned dummies
7. One HUD: Bonk + Bonk/sec. Hits popup only `+Bonk`

Stickers / rune gacha: **out of scope** until this slice is fun.

---

## Repo layout (agents own folders)

```text
src/
  Shared/
    Config.luau          -- ALL numbers. Nobody hardcodes costs elsewhere.
    Types.luau
    Formulas.luau        -- cost(n), bonkPerHit, prestige grant, offline
  Server/
    PlayerData.luau      -- DataStore profile
    Economy.luau         -- grant/spend, validate
    Dummies.luau
    Gym.luau
    Prestige.luau
    Remotes.luau         -- one binder
  Client/
    Hud.luau
    ShopUI.luau          -- Dummies | This Gym | Rep shop
    VenueUI.luau
    PrestigeUI.luau
    WorldFx.luau
```

Hard rules:

- Agents own folders, not features across folders.
- All numbers live in `Config.luau`.
- Client never writes DataStore and never grants Bonk.
- Every Remote is validated on the server.

---

## Remote contract (Wave 0 — exist before implementation)

```text
BuyDummy(id)
BuyDummyUpgrade(id)
BuyGymLevel()
CloseDojo()
BuyRepNode(id)
RequestSync()
```

Do not add RollRune / tickets until a later wave.

---

## Profile schema (minimum)

```text
bonk
lifetimeBonk
peakBonkThisRun
dummies          -- map id → count
dummyUpgrades    -- map id → level
gymLevel
venueId          -- current run venue
unlockedVenues   -- list or bitflags
gymRep
lifetimeGymRep
lastTick         -- for offline
repNodes         -- purchased permanent ids
```

---

## Dummy types (Wave 1 Config)

Start with four. Costs and ops belong in Config, not in this paragraph.

| id | name | role |
|---|---|---|
| `yellow` | Yellow Dummy | Starter. Cheap, low power |
| `fat` | Fat Dummy | Tankier stay-time, mid power |
| `gold` | Gold Dummy | High Bonk per hit |
| `crowd` | Crowd Dummy | Unlocks later / Rep node. More bodies in the pen |

---

## Agent ownership

### Agent A — Economy / server

**Owns:** `src/Server/**`, `src/Shared/Formulas.luau`  
**Does not own:** Client, world art, Config number tuning after first draft

Implement: profile, DataStore, tick, offline cap, BuyDummy / upgrades / gym level, CloseDojo grant+wipe, BuyRepNode, remote validation, BigNum usage.

### Agent B — Client UI / juice

**Owns:** `src/Client/**`  
**Does not own:** DataStore, formulas, Config

Implement: HUD (Bonk, /sec), shop tabs from Config (never duplicate prices), can’t-afford state, Close Dojo modal with Rep grant preview, Venues hallway of doors, number format (`1.2K`, `3.4M`, `1.0e12`), `+Bonk` popups, dummy-count label.

### Agent C — Content / balance + review

**Owns:** `src/Shared/Config.luau`, `src/Shared/Types.luau`  
**Also:** review pass on Agent A remotes after each wave

Implement: dummy table, upgrade table, gym level costs, venue table (1–10, doors 2–10 locked), prestige formula constants, 3 Rep shop nodes, offline cap. After A/B ship a wave: check spend is server-validated and prestige wipes the right fields.

### Studio MCP (not Grok Build)

World only: backyard pad, dummy pen, `/generate_mesh` dummy variants, shrine/door for Close Dojo and venues. No PlayerData edits.

---

## Waves

### Wave 0 — contracts (human or one short agent pass)

`Types.luau` + empty remote names + this file. No economy until these exist.

### Wave 1 — playable incrementer (parallel A + B + C)

- A: dummies + Bonk tick + gym levels + DataStore + offline
- B: HUD + dummy shop + gym shop
- C: 4 dummy types, gym 1–10 costs, Backyard only
- Stop when a friend can idle 2 minutes and feel numbers go up

### Wave 2 — first reset layer

- A: CloseDojo wipe + Gym Rep + Rep shop nodes
- B: confirm modal + time-to-rebuy hint + Rep shop
- C: prestige formula + 3 permanent nodes
- Venues UI shows 10 doors, only Backyard open

### Wave 3 — first extra venue (only if Wave 2 is fun)

Unlock Garage with lifetime Rep. Same hit formula. New room + `venueMult = 2`. Still no stickers.

### Wave 4+

Stickers / tickets only if dummy + gym + one reset + one extra door is already fun. Then venues 3–10 one at a time.

---

## Luau / Roblox rules

- Modern Luau types on public functions
- `task.wait`, not deprecated `wait()`
- Server-authoritative. Validate every spend against Config
- Remotes in one binder under ReplicatedStorage
- No invented services
- Inspect existing files before writing
- One system per change set
- Do not implement Stickers, Prism-likes, minions, factories, or venues 11–19 unless the prompt for that session says so

---

## Explicit non-goals

- Cloning Noob Incremental names (Oof, Noobs, Runes, Prestige 19 as a label)
- A new hit system per gym
- Client-trusted currency
- Raw `number` for Bonk
- Shipping 10 venues on day one
---
